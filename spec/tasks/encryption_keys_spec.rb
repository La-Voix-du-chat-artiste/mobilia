require 'rails_helper'
require 'English'

# Two halves of the same trap:
#
#   * config/application.rb is evaluated for every `bin/rails` invocation, so an
#     ENV.fetch there aborts even for tasks that never initialise the app — most
#     notably `db:encryption:init`, which generates the very keys it would abort
#     for. The task was impossible to run from a clean checkout.
#   * the check has to live somewhere that still runs when the app does boot.
#
# Both are asserted by running the real commands in a subprocess, because the
# behaviour under test is what happens *before* a process finishes booting.
RSpec.describe 'Active Record encryption key bootstrap' do
  encryption_variables = %w[
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT
  ].freeze

  # Empty rather than absent: dotenv never overwrites an existing key, so this is
  # what stops it re-supplying the values from .env / .env.test.
  let(:env_without_keys) do
    { 'RAILS_ENV' => 'test' }.merge(encryption_variables.index_with { '' })
  end

  def run(*command, env:)
    output = IO.popen(env, command, chdir: Rails.root.to_s, err: %i[child out], &:read)

    [output, $CHILD_STATUS]
  end

  it 'can generate keys even though it needs them to boot' do
    output, status = run('bin/rails', 'db:encryption:init', env: env_without_keys)

    expect(status).to be_success, "db:encryption:init failed:\n#{output}"
    expect(output).to include('primary_key', 'deterministic_key', 'key_derivation_salt')
  end

  it 'refuses to boot without them and says how to fix it' do
    output, status = run('bin/rails', 'runner', 'puts :booted', env: env_without_keys)

    expect(status).not_to be_success
    expect(output).to include('Missing Active Record encryption configuration')
    expect(output).to include('bin/rails db:encryption:init')
  end
end
