GovukError.configure do |config|
  config.data_sync_excluded_exceptions += [
    "Faraday::ServerError",
    "Faraday::ConnectionFailed",
  ]
end
