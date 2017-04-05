class CheckController < ApplicationController
  def check
    uri = params.fetch(:uri)
    synchronous = params[:synchronous] == "true"
    checked_within = (params[:checked_within] || 24.hours).to_i
    callback_uri = params[:callback_uri]

    link = Link.find_or_create_by!(uri: uri)
    check = link.find_completed_check(within: checked_within)
    return render(json: check.to_h) if check

    check = Check.create(link: link)

    if synchronous
      CheckJob.perform_now(check)
      WebhookJob.perform_now(check, callback_uri) if callback_uri
    else
      CheckJob.perform_later(check)
      WebhookJob.perform_later(check, callback_uri) if callback_uri
    end

    render(json: check.to_h)
  end
end
