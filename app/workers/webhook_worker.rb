class WebhookWorker
  include Sidekiq::Worker

  def perform(report, webhook_uri)
    connection.post do |req|
      req.url webhook_uri
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
