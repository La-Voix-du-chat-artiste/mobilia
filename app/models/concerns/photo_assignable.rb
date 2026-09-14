require 'erb'

# Attaches the generated avatar used as the default photo for a new record.
#
# Previously each model inlined `photo.attach(io: URI.parse(url).open, filename: ...)`.
# That had three problems:
#
# * it ran a synchronous HTTP request inside an `after_create` callback, so a slow
#   or unreachable avatar service made the whole `create` fail and roll back;
# * the name was interpolated into the URL unescaped, so any record whose name
#   contains a space or an accent raised URI::InvalidURIError;
# * `URI.parse(url).open` is the deprecated form of `URI.open`.
#
# Failures are now logged and swallowed: a missing avatar must never cost us the
# record, and seeds/tests must not depend on a third-party service being up.
module PhotoAssignable
  extend ActiveSupport::Concern

  AVATAR_TIMEOUT = 5 # seconds, applies to both connect and read

  # Active Storage sniffs the blob's content type from the bytes, but it stores
  # whatever filename it is handed. ui-avatars answers `format=jpg` requests with
  # PNG, so every generated avatar was saved as `*.jpg` containing PNG data, and
  # db/seeds.rb named loremflickr's JPEGs `*.png` — 57 of 57 blobs with an
  # extension that disagreed with their content. Serving was always correct
  # (browsers use the blob's content type); the stored filename just lied.
  CONTENT_TYPE_EXTENSIONS = {
    'image/png' => 'png',
    'image/jpeg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif'
  }.freeze

  class_methods do
    # @return [String] ui-avatars.com URL for the given name
    def avatar_url(name, background:)
      encoded_name = ERB::Util.url_encode(name.to_s)
      "https://ui-avatars.com/api/?format=jpg&name=#{encoded_name}" \
        "&background=#{background}&color=ffffff&size=256"
    end
  end

  private

  def attach_generated_photo(url, filename)
    return if photo.attached?

    # No block form here: Active Storage may read the IO after this method
    # returns, and `URI.open(url) { |io| ... }` closes it on block exit, which
    # surfaced as "IOError: not opened for reading". The URL is built by
    # avatar_url from a literal host plus an escaped name, so no user input can
    # reach the host or the scheme.
    io = URI.open(url, open_timeout: AVATAR_TIMEOUT, read_timeout: AVATAR_TIMEOUT) # rubocop:disable Security/Open
    photo.attach(io: io, filename: filename_for(filename, io))
  rescue StandardError => e
    Rails.logger.warn(
      "[PhotoAssignable] could not attach #{filename} to #{self.class.name}##{id}: #{e.class}: #{e.message}"
    )
  end

  # Name the file after what the service actually returned. open-uri exposes the
  # response's Content-Type on the object it yields.
  def filename_for(filename, io)
    content_type = io.try(:content_type).to_s.split(';').first
    extension = CONTENT_TYPE_EXTENSIONS[content_type]
    return filename if extension.nil?

    "#{filename.sub(/\.[^.]+\z/, '')}.#{extension}"
  end
end
