GovukError.configure do |config|
  config.data_sync_excluded_exceptions += %w[
    Faraday::ServerError
    Faraday::ConnectionFailed
    RestartWorkerException
  ]
end
