source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '4.0.4'

gem 'rails', '~> 8.1.0'

gem 'action_policy'
gem 'acts_as_list'
gem 'bootsnap', require: false
gem 'business'
# Ruby 4.0 dropped cgi from the default gems and nothing in the Rails dependency
# tree pulls it back in. Add it explicitly or `require 'cgi'` breaks on a clean install.
gem 'cgi'
gem 'dotenv-rails'
gem 'faker'
gem 'geocoder'
gem 'good_job', '~> 4.19'
gem 'human_attributes'
gem 'image_processing', '~> 1.2'
gem 'importmap-rails'
gem 'jbuilder'
# json 3.x made JSON.parse keyword-only, but ActiveSupport::JSON.decode in
# activesupport 8.1.3.1 still calls it positionally, so every JSON column read
# raises ArgumentError. Keep the 2.x line until Rails supports json 3.
gem 'json', '~> 2.21'
gem 'lograge'
gem 'meta-tags'
# TODO: pagy 43 redesigned its whole API (Pagy::Method, #series_nav, new markup/CSS).
# Staying on 9.x until the views and app/assets/stylesheets/plugins/pagy.css are ported.
gem 'pagy', '~> 9.4'
gem 'pg'
gem 'puma'
gem 'rails-i18n'
# Action Cable's redis adapter declares `gem "redis", ">= 4", "< 6"` (see
# action_cable/subscription_adapter/redis.rb), so letting this float to redis 6
# makes every Turbo stream connection answer 500 with a Gem::LoadError.
gem 'redis', '~> 5.4'
gem 'simple_form'
gem 'slim-rails'
gem 'sorcery'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'store_model'
# TODO: tailwindcss-rails 4 ships Tailwind CSS v4, whose standalone CLI cannot resolve
# `@plugin` directives without node_modules. Staying on the v3 line.
gem 'tailwindcss-rails', '~> 3.3'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

group :development do
  # `annotate` caps activerecord at < 8.0, so it cannot run on Rails 8.1.
  # annotaterb is the maintained fork, with the same annotations format.
  gem 'annotaterb'
  gem 'chusaku', require: false
  gem 'letter_opener'
  gem 'web-console'
end

group :development, :test do
  gem 'bullet'
  gem 'debug', platforms: %i[mri windows]
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  # Keeps the suite off the network: covers URI.open (avatars), Faraday (OSRM)
  # and any other real HTTP.
  gem 'webmock'
end
