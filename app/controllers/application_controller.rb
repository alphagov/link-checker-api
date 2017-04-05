class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  before_action :require_signin_permission!

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: { message: e.message } }, status: 400
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: { message: e.message } }, status: 404
  end

  def payload
    @payload ||= JSON.parse(request.body.read).deep_symbolize_keys
  end
end
