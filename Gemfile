# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'
gem 'bcrypt', '~> 3.1.7'
gem 'dotenv-rails', require: 'dotenv/rails-now'
gem 'jbuilder'
gem 'jwt'
gem 'pg', '~> 1.1'
gem 'pry'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.5'
gem 'redis', '~> 5.0', '>= 5.0.8'
# Pagination

gem 'api-pagination', '~> 5.0.0'
gem 'kaminari', '~> 1.2.2'

gem 'bootsnap', require: false
gem 'factory_bot_rails'
gem 'faker', '~> 3.2.2'
gem 'simplecov-small-badge', require: false
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem "rack-cors"

group :development, :test do
  gem 'brakeman', '~> 6.0.1'
  gem 'bullet'
  gem 'byebug'
  # gem 'letter_opener_web', '~> 1.4.0'
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  # gem 'dotenv-rails', require: 'dotenv/rails-now'
  gem 'rspec-rails', '~> 6.0.3'
  gem 'rswag-specs', '~> 2.11.0'
  gem 'rubocop', '~> 1.57.2', require: false
  gem 'rubocop-performance', '~> 1.19.1', require: false
  gem 'rubocop-rails', '~> 2.22.1', require: false
  gem 'rubocop-rspec', '~> 2.25.0', require: false
end

group :development do
  gem 'listen', '~> 3.8.0'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.1.0'
  gem 'web-console', '>= 4.2.1'
end

group :test do
  gem 'mock_redis', '~> 0.16.1'
  gem 'rspec'
  # RSpec 2 & 3 results that your CI can read
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end

# API documentation
gem 'rswag-api'
gem 'rswag-ui'
