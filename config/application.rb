require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LinkCheckerApi
  mattr_accessor :hosts_with_basic_authorization
  self.hosts_with_basic_authorization = {}

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.load_defaults = 6.0

    config.eager_load_paths << "#{config.root}/lib"
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]

    config.api_only = true

    config.active_job.queue_adapter = :sidekiq

    # GDS SSO requires a session to exist
    middleware.insert_before Rack::Head, ActionDispatch::Session::CacheStore
  end
end
