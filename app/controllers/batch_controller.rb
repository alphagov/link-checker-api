class BatchController < ApplicationController
  before_action :validate_create_params, only: [:create]

  def create
    batch = ActiveRecord::Base.transaction do
      links = Link.fetch_all(create_params[:uris])
      checked_within = create_params[:checked_within] || 24.hours.to_i
      checks = Check.fetch_all(links, within: checked_within)
      Batch.create!(checks: checks, webhook_uri: create_params[:webhook_uri])
    end

    if batch.completed?
      WebhookWorker.perform_async(batch_report(batch), batch.webhook_uri) if batch.webhook_uri
      render(json: batch_report(batch), status: 201)
    else
      batch.checks.each do |check|
        CheckWorker.perform_async(check)
      end

      render(json: batch_report(batch), status: 202)
    end
  end

  def show
    batch = Batch.find(params[:id])
    render(json: batch_report(batch))
  end

private

  def batch_report(batch)
    BatchPresenter.new(batch).report
  end

  def create_params
    params.permit(:checked_within, :webhook_uri, uris: [])
  end

  def validate_create_params
    CreateValidator.new(create_params).validate!
  end

  class CreateValidator < OpenStruct
    include ActiveModel::Validations

    validates :uris, presence: true, length: { maximum: 5000 }
    validates :checked_within, numericality: { greater_than: 0, allow_nil: true }
  end
end
