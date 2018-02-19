source "https://rubygems.org"

gem "rails", "5.1.5"
gem "logstasher", "~> 1.2"
gem "database_cleaner"
gem "deprecated_columns"
gem "gds-sso", "~> 13.6"
gem "plek", "~> 2.1"
gem "pg"

gem "govuk_app_config", "~> 1.2"

gem "faraday", "~> 0.11"
gem "faraday-cookie_jar", "~> 0.0.6"

gem "govuk_sidekiq", "~> 3.0"
gem "sidekiq-scheduler", "~> 2.2"
gem "sidekiq-unique-jobs", "~> 5.0"

gem "activerecord-import", "~> 0.17"

group :development, :test do
  gem "pry"
  gem "simplecov-rcov", "~> 0.2", require: false
  gem "simplecov", "~> 0.11", require: false
  gem "govuk-lint"
  gem "sqlite3" # Remove this when you choose a production database
  gem "factory_bot_rails", "~> 4.7"
  gem "timecop"
  gem "webmock"
  gem "rspec-rails", "~> 3.4"
  gem "byebug" # Comes standard with Rails
end

group :test do
  gem "rspec-sidekiq", "~> 3.0"
  gem "rspec-its"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 3.5"
  gem "listen"
end
