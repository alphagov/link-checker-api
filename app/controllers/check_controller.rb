class CheckController < ApplicationController
  class CheckParams
    include ActiveModel::Validations

    attr_accessor :uri, :synchronous, :checked_within

    validates :uri, presence: true, allow_blank: false
    validates :synchronous, inclusion: { in: [ true, false ] }
    validates :checked_within, numericality: { greater_than: 0 }

    def initialize(params)
      @params = params
      @uri = permitted_params[:uri]
      @synchronous = permitted_params[:synchronous] == "true"
      @checked_within = (permitted_params[:checked_within] || 24.hours).to_i
    end

    def permitted_params
      @permitted_params ||= @params.permit(:uri, :synchronous, :checked_within)
    end
  end

  def check
    check_params = CheckParams.new(params)
    check_params.validate!

    link = Link.find_or_create_by!(uri: check_params.uri)
    check = link.find_check(within: check_params.checked_within)
    return render(json: CheckPresenter.new(check).call) if check

    check = Check.create!(link: link)

    if check_params.synchronous
      CheckJob.perform_now(check)
    else
      CheckJob.perform_later(check)
    end

    render(json: CheckPresenter.new(check).call)
  end
end
