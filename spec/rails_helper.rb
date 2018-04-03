if ENV["RCOV"]
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start "rails"
end
# This file is copied to spec/ when you run "rails generate rspec:install"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "database_cleaner"
require "rspec/rails"
require "govuk_sidekiq/testing"
require "sidekiq_unique_jobs/testing"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include AuthenticationHelper::RequestMixin, type: :request
  config.include AuthenticationHelper::ControllerMixin, type: :controller

  config.include FactoryBot::Syntax::Methods

  config.after do
    GDS::SSO.test_user = nil
  end

  [:controller, :request].each do |spec_type|
    config.before :each, type: spec_type do
      login_as_stub_user
    end
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    if example.metadata[:skip_cleaning]
      example.run
    else
      DatabaseCleaner.cleaning { example.run }
    end
  end

  config.infer_spec_type_from_file_location!
end
