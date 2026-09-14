# The GoodJob dashboard exposes every job payload, so it must never be public.
#
# The route itself is conditional (see config/routes.rb): outside development it
# is only mounted when both variables are set, so a missing credential disables
# the dashboard rather than publishing it. This initializer adds the HTTP basic
# auth on top.
#
# Previously this file called ENV.fetch unconditionally, which made the whole
# application fail to boot whenever the two variables were unset — even in
# environments that never mount the dashboard.
goodjob_username = ENV.fetch('GOODJOB_USERNAME', nil)
goodjob_password = ENV.fetch('GOODJOB_PASSWORD', nil)

if goodjob_username.present? && goodjob_password.present?
  GoodJob::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(goodjob_username, username) &
      ActiveSupport::SecurityUtils.secure_compare(goodjob_password, password)
  end
elsif !Rails.env.local?
  Rails.logger.warn(
    'GOODJOB_USERNAME/GOODJOB_PASSWORD are not set: the GoodJob dashboard is not mounted.'
  )
end
