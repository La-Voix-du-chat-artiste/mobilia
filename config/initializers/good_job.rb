GoodJob::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(ENV.fetch('GOODJOB_USERNAME'), username) &&
    ActiveSupport::SecurityUtils.secure_compare(ENV.fetch('GOODJOB_PASSWORD'), password)
end
