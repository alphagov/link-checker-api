class CheckController < ApplicationController
  def check
    uri = params.fetch(:uri)
    synchronous = params[:synchronous] == "true"
    checked_within = params.fetch(:"checked-within", 24.hours.to_i).to_i

    link = Link.find_or_create_by!(uri: uri)
    check = link.find_check(within: checked_within)
    return render(json: check.to_h) if check

    check = Check.create(link: link)

    if synchronous
      LinkCheckJob.perform_now(check)
    else
      LinkCheckJob.perform_later(check)
    end

    render(json: check.to_h)
  end
end
