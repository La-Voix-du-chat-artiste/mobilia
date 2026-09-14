# Fails fast, with instructions, when the Active Record encryption keys are
# missing.
#
# The values themselves are assigned in config/application.rb, because Active
# Record copies that configuration into ActiveRecord::Encryption from its own
# railtie initializer — assigning them here would be too late.
#
# The *check* is here, and not there, because config/application.rb is evaluated
# for every `bin/rails` invocation, including `bin/rails db:encryption:init`.
# Raising there made that task impossible to run from a clean checkout: it
# aborted asking for the keys it exists to generate. Initializers only run once
# the application is initialised, and that task does not initialise it.
#
# Values come from .env (see .env.template) or from
# `bin/rails credentials:edit` (active_record_encryption.*).
missing_settings = %i[primary_key deterministic_key key_derivation_salt].reject do |setting|
  Rails.application.config.active_record.encryption[setting].present?
end

if missing_settings.any?
  raise KeyError, <<~MESSAGE
    Missing Active Record encryption configuration: #{missing_settings.join(', ')}

    Generate them with:

        bin/rails db:encryption:init

    then add the three values to your .env file (see .env.template), or run
    `bin/setup`, which does both. They protect users' names, phones and emails,
    so the application refuses to boot without them.
  MESSAGE
end
