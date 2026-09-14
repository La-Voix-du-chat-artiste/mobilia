require 'capybara/rails'
require 'capybara/rspec'

# Acceptance tests drive the real forms through a real request cycle, but they
# deliberately run without JavaScript (`:rack_test`): the forms are plain HTML
# forms, so this keeps them fast and CI-safe, and it means a broken no-JS path is
# caught rather than hidden behind a browser.
Capybara.configure do |config|
  config.default_driver = :rack_test
  config.javascript_driver = :rack_test
  config.default_max_wait_time = 5
  config.ignore_hidden_elements = true
end

module FeatureHelpers
  DEFAULT_PASSWORD = 'password123'.freeze

  # Signs in the way a person does: visit the form and fill it in.
  def sign_in_as(user, password: DEFAULT_PASSWORD)
    visit new_sessions_path
    fill_in 'session_email', with: user.email
    fill_in 'session_password', with: password
    click_button 'Se connecter'
  end

  def sign_out
    click_button 'Déconnexion'
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
