require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Mobilia
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    #
    # Beyond 7.1, 8.1 turns on:
    #   action_controller.escape_json_responses = false
    #   action_controller.action_on_path_relative_redirect = :raise
    #   active_record.raise_on_missing_required_finder_order_columns = true
    #   active_support.escape_js_separators_in_json = false
    #   action_view.render_tracker = :ruby
    #   action_view.remove_hidden_field_autocomplete = true
    #   config.yjit = !Rails.env.local?
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks templates])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Europe/Paris'
    # config.eager_load_paths << Rails.root.join("extras")

    config.i18n.default_locale = :fr

    # Active Record encryption keys, from .env (see .env.template).
    #
    # Assigned here, in the class body, because Active Record copies this
    # configuration into ActiveRecord::Encryption from its own railtie
    # initializer — an initializer in config/initializers/ runs too late to be
    # seen.
    #
    # Deliberately not ENV.fetch: this file is evaluated for every `bin/rails`
    # invocation (the Rakefile requires it), including `db:encryption:init`,
    # which generates the very keys an exception here would abort for. The
    # fail-fast check lives in config/initializers/active_record_encryption.rb,
    # which only runs when the application is actually initialised.
    {
      'primary_key' => 'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY',
      'deterministic_key' => 'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY',
      'key_derivation_salt' => 'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'
    }.each do |setting, variable|
      value = ENV[variable].to_s
      config.active_record.encryption.public_send("#{setting}=", value) unless value.empty?
    end
  end
end
