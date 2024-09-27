class RestartJobException < RuntimeError
end

class WebhookJob
  include Sidekiq::Job

  sidekiq_options queue: :webhooks, retry: 4, lock: :until_and_while_executing, lock_args_method: :unique_args

  def self.unique_args(args)
    [args[3]] # batch_id
  end

  sidekiq_retry_in do |count|
    # retry between 15-20 minutes first, then 30-40 minutes next, then 45-60 minutes next, etc
    # we have randomness here to make sure that waiting webhooks don't all come in at the same time
    (rand(15..19) * 60) * (count + 1)
  end

  SIGNATURE_HEADER = "X-LinkCheckerApi-Signature".freeze

  def perform(report, uri, secret_token, batch_id)
    batch = Batch.find(batch_id)
    return if batch.webhook_triggered

    connection.post do |req|
      req.url uri
      req.headers["Content-Type"] = "application/json"
      req.headers["User-Agent"] = "#{ENV.fetch('GOVUK_APP_NAME', 'link-checker-api')} (webhook-job)"
      req.headers[SIGNATURE_HEADER] = generate_signature(report, secret_token) if secret_token
      req.body = report
    end

    batch.update!(webhook_triggered: true)
  rescue Faraday::ClientError => e
    logger.error e.message
    raise RestartJobException
  rescue Faraday::ServerError => e
    logger.error e.message
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

WebhookWorker = WebhookJob
