class WebhookJob < ApplicationJob
  queue_as :default

  def perform(object, callback_uri)
    response = Faraday.post do |req|
      req.url callback_uri
      req.headers["Content-Type"] = "application/json"
      req.body = object.to_h.to_json
    end

    if response.status >= 500
      WebhookJob.set(wait: 10.minutes).perform_later(object, callback_uri)
    end
  end
end
