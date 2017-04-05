class CheckController < ApplicationController
  def check
    uri = params.fetch(:uri)

    link = Link.find_or_create_by!(uri: uri)
    check = link.existing_check
    return render(json: check.to_h) if check

    check = Check.create(link: link)
    LinkCheckJob.perform_later(check)

    render(json: check.to_h)
  end
end
