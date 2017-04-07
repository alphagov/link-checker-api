class BatchController < ApplicationController
  class CreateParams
    include ActiveModel::Validations

    attr_accessor :uris, :checked_within, :callback_uri

    validates :uris, presence: true
    validates :checked_within, numericality: { greater_than: 0 }

    def initialize(params)
      @params = params
      @uris = permitted_params[:uris]
      @checked_within = (permitted_params[:checked_within] || 24.hours).to_i
      @callback_uri = permitted_params[:callback_uri]
    end

    def permitted_params
      @permitted_params ||= @params.permit(:checked_within, :callback_uri, uris: [])
    end
  end

  def create
    create_params = CreateParams.new(params)
    create_params.validate!

    batch = ActiveRecord::Base.transaction do
      links = Link.fetch_all(create_params.uris)
      checks = Check.fetch_all(links, within: create_params.checked_within)
      Batch.create!(checks: checks, callback_uri: create_params.callback_uri)
    end

    if batch.completed?
      WebhookJob.perform_later(BatchPresenter.new(batch).call, batch.callback_uri) if batch.callback_uri
      render(json: BatchPresenter.new(batch).call, status: 201)
    else
      batch.checks.each do |check|
        CheckJob.perform_later(check)
      end

      render(json: BatchPresenter.new(batch).call, status: 202)
    end
  end

  class ShowParams
    include ActiveModel::Validations

    attr_accessor :id

    validates :id, presence: true, numericality: { greater_than_or_equal_to: 0 }

    def initialize(params)
      @params = params
      @id = permitted_params[:id]
    end

    def permitted_params
      @permitted_params ||= @params.permit(:id)
    end
  end

  def show
    show_params = ShowParams.new(params)
    show_params.validate!
    batch = Batch.find(show_params.id)
    render(json: BatchPresenter.new(batch).call)
  end
end
