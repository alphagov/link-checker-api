class WebhookJob < ApplicationJob
  queue_as :default

  rescue_from Faraday::Error do
    retry_job wait: 5.minutes
  end

  def perform(report, callback_uri)
    response = connection.post do |req|
      req.url callback_uri
      req.headers["Content-Type"] = "application/json"
      req.body = report.to_json
    end
  end

  def connection
    Faraday.new do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.use Faraday::Response::RaiseError
    end
  end
end
