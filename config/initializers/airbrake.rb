if ENV["ERRBIT_API_KEY"].present?
  errbit_uri = Plek.find_uri("errbit")

  Airbrake.configure do |config|
    config.project_key = ENV["ERRBIT_API_KEY"]
    config.project_id = 9999 # This is required by airbrake but ignored by errbit.
    config.host = errbit_uri.to_s
    config.environment = ENV["ERRBIT_ENVIRONMENT_NAME"]
  end
end
