Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

# SidekiqUniqueJobs recommends not testing this behaviour, our tests have previously has caused flakey builds
SidekiqUniqueJobs.config.enabled = !Rails.env.test?
SidekiqUniqueJobs.config.logger_enabled = !Rails.env.test?

# Use Sidekiq strict args to force Sidekiq 6 deprecations to error ahead of upgrade to Sidekiq 7
Sidekiq.strict_args!
