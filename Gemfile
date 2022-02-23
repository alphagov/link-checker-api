source "https://rubygems.org"

gem "rails", "7.0.2"

gem "activerecord-import"
gem "addressable"
gem "deprecated_columns"
gem "faraday"
gem "faraday-cookie_jar"
gem "gds-sso"
gem "govuk_app_config"
gem "govuk_sidekiq"
gem "pg"
gem "plek"
gem "sidekiq-scheduler"
gem "sidekiq-unique-jobs", "~> 6" # Latest version is 7.x but this currently breaks the unique options in webhook_worker, will be handled in subsequent PR

group :development, :test do
  gem "byebug" # Comes standard with Rails
  gem "climate_control"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "pact", require: false
  gem "pact_broker-client"
  gem "pry"
  gem "rspec-rails"
  gem "rubocop-govuk"
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock"
end

group :test do
  gem "rspec-its"
  gem "rspec-sidekiq"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "listen"
  gem "web-console"
end
