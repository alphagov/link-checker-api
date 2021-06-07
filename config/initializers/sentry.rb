GovukError.configure do |config|
  config.excluded_exceptions += %w[
    RestartWorkerException
  ]
end
