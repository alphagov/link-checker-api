source "https://rubygems.org"

gem "rails", "5.1.6"
gem "logstasher", "~> 1.2"
gem "database_cleaner"
gem "deprecated_columns"
gem "gds-sso", "~> 13.6"
gem "plek", "~> 2.1"
gem "pg"

gem "govuk_app_config", "~> 1.4"

gem "faraday", "~> 0.11"
gem "faraday-cookie_jar", "~> 0.0.6"

gem "govuk_sidekiq", "~> 3.0"
gem "sidekiq-scheduler", "~> 2.2"
# We can't use v5 of this because it requires redis 3 and we use 2.8
# We use our own fork because the latest 4.x release has a bug with
# removing jobs from the uniquejobs hash in redis
gem "sidekiq-unique-jobs", git: "https://github.com/alphagov/sidekiq-unique-jobs", branch: 'fix-for-upstream-195-backported-to-4-x-branch'

gem "activerecord-import", "~> 0.22"

group :development, :test do
  gem "pry"
  gem "simplecov-rcov", "~> 0.2", require: false
  gem "simplecov", "~> 0.16", require: false
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
  gem "web-console", "~> 3.6"
  gem "listen"
end
