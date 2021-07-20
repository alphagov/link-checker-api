GovukError.configure do |config|
  config.data_sync_excluded_exceptions += %w[
    Faraday::ServerError
    Faraday::ConnectionFailed
    RestartWorkerException
  ]

  config.backtrace_cleanup_callback = lambda do |backtrace|
    Rails.backtrace_cleaner.clean(backtrace)
  end
end
