errbit_uri = Plek.find_uri("errbit")
environment = ENV.fetch("ERRBIT_ENVIRONMENT_NAME", Rails.env)

Airbrake.configure do |config|
  # we need a key even if errbit isn't used, so fall back to random data
  config.project_key = ENV.fetch("ERRBIT_API_KEY", SecureRandom.hex(5))
  config.project_id = 1 # dummy, not used in Errbit
  config.host = errbit_uri.to_s
  config.environment = environment
  config.ignore_environments = ENV["ERRBIT_API_KEY"] ? [environment] : []
end
