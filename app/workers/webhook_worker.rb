class RestartWorkerException < RuntimeError
end

class WebhookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :webhooks

  SIGNATURE_HEADER = "X-LinkCheckerApi-Signature".freeze

  def perform(report, uri, secret_token)
    body = report.to_json

    connection.post do |req|
      req.url uri
      req.headers["Content-Type"] = "application/json"
      req.headers[SIGNATURE_HEADER] = generate_signature(body, secret_token) if secret_token
      req.body = body
    end
  rescue Faraday::ClientError
    raise RestartWorkerException.new
  end

  def connection
    Faraday.new do |faraday|
      faraday.adapter Faraday.default_adapter
      faraday.use Faraday::Response::RaiseError
    end
  end

  def generate_signature(body, key)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), key, body)
  end
end
