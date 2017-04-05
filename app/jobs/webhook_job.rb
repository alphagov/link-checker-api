class WebhookJob < ApplicationJob
  queue_as :default

  def perform(check_or_batch, callback_uri)
    return try_again(check_or_batch, callback_uri) unless check_or_batch.completed?

    response = Faraday.post do |req|
      req.url callback_uri
      req.headers["Content-Type"] = "application/json"
      req.body = check_or_batch.to_h.to_json
    end

    if response.status >= 500
      try_again(check_or_batch, callback_uri)
    end
  end

  def try_again(check_or_batch, callback_uri)
    WebhookJob.set(wait: 10.minutes).perform_later(object, callback_uri)
  end
end
