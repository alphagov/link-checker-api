GovukError.configure do |config|
  config.data_sync_excluded_exceptions += %w[
    Faraday::ServerError
    Faraday::ConnectionFailed
    RestartJobException
  ]

  config.excluded_exceptions += %w[
    RestartJobException
  ]
end
