ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
# Disables real network access: avatars (URI.open) and OSRM (Faraday) must be
# stubbed, otherwise the suite silently depends on third parties.
require 'webmock/rspec'

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# Dir.glob (and therefore Pathname#glob) is sorted.
Rails.root.glob('spec/support/**/*.rb').each { |file| require file }

RSpec.configure do |config|
  # Rolls every example back, so examples cannot leak state into each other.
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper
  config.include ActionMailer::TestHelper
end
