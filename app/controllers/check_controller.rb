class CheckController < ApplicationController
  class CheckParams
    include ActiveModel::Validations

    attr_accessor :uri, :synchronous, :checked_within, :priority

    validates :uri, presence: true, allow_blank: false
    validates :synchronous, inclusion: { in: [true, false] }
    validates :checked_within, numericality: { greater_than_or_equal_to: 0 }
    validates :priority, inclusion: { in: %w(low high) }

    def initialize(params)
      @params = params
      @uri = permitted_params[:uri]
      @synchronous = permitted_params[:synchronous] == "true"
      @checked_within = (permitted_params[:checked_within] || 4.hours).to_i
      @priority = permitted_params.fetch(:priority, "high")
    end

    def permitted_params
      @permitted_params ||= @params.permit(:uri, :synchronous, :checked_within, :priority)
    end
  end

  def check
    check_params = CheckParams.new(params)
    check_params.validate!

    link = Link.find_or_create_by!(uri: check_params.uri)
    check = link.find_check(
      within: check_params.checked_within,
      completed: check_params.synchronous,
    )

    return render(json: link_report(check)) if check

    check = Check.create!(link: link)

    CheckWorker.run(
      check.id,
      priority: check_params.priority,
      synchronous: check_params.synchronous,
    )

    render(json: link_report(check.reload))
  end

private

  def link_report(check)
    CheckPresenter.new(check).link_report
  end
end
