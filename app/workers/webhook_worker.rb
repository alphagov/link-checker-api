class RestartWorkerException < RuntimeError
end

class WebhookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :webhooks, retry: 5

  sidekiq_retry_in do |count|
    # retry between 15-20 minutes first, then 30-40 minutes next, then 45-60 minutes next, etc
    # we have randomness here to make sure that waiting webhooks don't all come in at the same time
    ((15 + rand(5)) * 60) * (count + 1)
  end

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
