module AuthenticationHelpers
  DEFAULT_PASSWORD = 'password123'.freeze

  # Signs in through the real sessions controller rather than poking the session,
  # so the spec exercises sorcery's login path.
  def sign_in(user, password: DEFAULT_PASSWORD)
    post '/sessions', params: { session: { email: user.email, password: password } }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
