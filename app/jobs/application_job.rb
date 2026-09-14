class ApplicationJob < ActiveJob::Base
  rescue_from StandardError, with: :broadcast_flash_alert

  private

  def broadcast_flash_alert(e)
    message = "[#{e.class.name}] #{e.message}"

    Rails.logger.tagged(e.class) do
      # `ActiveSupport::LogSubscriber.new.send(:color, ...)` reached into a
      # private API just to colour the line red.
      Rails.logger.error("#{message} // #{e.backtrace&.join("\n")}")
    end

    ApplicationRecord.broadcast_flash(
      :alert,
      message,
      stream: error_stream,
      disappear: false
    )
  end

  # Every browser subscribes to the bare `:flash` stream, so this default shows
  # one tenant's background-job failures to all the others. Jobs that know their
  # company should override it with `[company, :flash]`.
  def error_stream
    :flash
  end
end
