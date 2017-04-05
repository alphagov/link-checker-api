class BatchController < ApplicationController
  def create
    uris = payload.fetch(:uris)
    checked_within = (payload[:checked_within] || 24.hours).to_i
    callback_uri = payload[:callback_uri]

    return render json: { error: { message: "No URIs given." } }, status: 400 if uris.empty?

    links = uris.map do |uri|
      Link.find_or_create_by(uri: uri)
    end

    checks = links.map do |link|
      check = link.find_completed_check(within: checked_within)
      check ? check : Check.create(link: link)
    end

    batch = Batch.create(checks: checks)

    if batch.completed?
      WebhookJob.perform_now(batch, callback_uri) if callback_uri
      render json: batch.to_h, status: 201
    else
      checks.each do |check|
        LinkCheckJob.perform_later(check, callback_uri)
      end

      render json: batch.to_h, status: 202
    end
  end

  def show
    id = params.fetch(:id)
    batch = Batch.find(id)
    render json: batch.to_h
  end
end
