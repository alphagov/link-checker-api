source "https://rubygems.org"

gem "activerecord-import", "~> 1.0"
gem "deprecated_columns"
gem "faraday", "~> 0.16"
gem "faraday-cookie_jar", "~> 0.0.6"
gem "gds-sso", "~> 14.1"
gem "govuk_app_config", "~> 2.0"
gem "govuk_sidekiq", "~> 3.0"
gem "pg"
gem "plek", "~> 3.0"
gem "rails", "6.0.0"
gem "sidekiq-scheduler", "~> 3.0"
# We can't use v5 of this because it requires redis 3 and we use 2.8
# We use our own fork because the latest 4.x release has a bug with
# removing jobs from the uniquejobs hash in redis
gem "sidekiq-unique-jobs", git: "https://github.com/alphagov/sidekiq-unique-jobs", branch: "fix-for-upstream-195-backported-to-4-x-branch"

group :development, :test do
  gem "byebug" # Comes standard with Rails
  gem "climate_control", "~> 0.2.0"
  gem "factory_bot_rails", "~> 5.1"
  gem "govuk-lint"
  gem "pry"
  gem "rspec-rails", "~> 3.8"
  gem "simplecov", "~> 0.17", require: false
  gem "simplecov-rcov", "~> 0.2", require: false
  gem "timecop"
  gem "webmock"
end

group :test do
  gem "rspec-its"
  gem "rspec-sidekiq", "~> 3.0"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "listen"
  gem "web-console", "~> 4.0"
end
