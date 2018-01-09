class BatchController < ApplicationController
  class CreateParams
    include ActiveModel::Validations

    attr_accessor :uris, :checked_within, :priority, :webhook_uri, :webhook_secret_token

    validates :uris, presence: true, length: { maximum: 5000 }
    validates :checked_within, numericality: { greater_than: 0 }
    validates :priority, inclusion: { in: %w(low high) }

    def initialize(params)
      @params = params
      @uris = permitted_params[:uris]
      @checked_within = (permitted_params[:checked_within] || 4.hours).to_i
      @priority = permitted_params.fetch(:priority, "high")
      @webhook_uri = permitted_params[:webhook_uri]
      @webhook_secret_token = permitted_params[:webhook_secret_token]
    end

    def permitted_params
      @permitted_params ||= @params.permit(:checked_within, :webhook_uri, :webhook_secret_token, :priority, uris: [])
    end
  end

  def create
    create_params = CreateParams.new(params)
    create_params.validate!

    batch = create_batch(create_params)

    return head :unprocessable_entity unless batch

    if batch.completed?
      batch.trigger_webhook
      render(json: batch_report(batch), status: 201)
    else
      batch.checks.each do |check|
        CheckWorker.run(check.id, priority: create_params.priority)
      end

      render(json: batch_report(batch.reload), status: 202)
    end
  end

  def show
    batch = Batch.includes(checks: :link).find(params[:id])
    render(json: batch_report(batch))
  end

private

  def create_batch(create_params)
    ActiveRecord::Base.transaction do
      batch = Batch.create!(
        webhook_uri: create_params.webhook_uri,
        webhook_secret_token: create_params.webhook_secret_token
      )

      links = Link.fetch_all(create_params.uris)
      checks = Check.fetch_all(links, within: create_params.checked_within)

      batch_checks = checks.each_with_index.map do |check, i|
        BatchCheck.new(batch_id: batch.id, check_id: check.id, order: i)
      end

      BatchCheck.import(batch_checks)

      batch
    end
  end

  def batch_report(batch)
    BatchPresenter.new(batch).report
  end
end
