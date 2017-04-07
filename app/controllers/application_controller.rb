class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  before_action :require_signin_permission!

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: { message: e.message } }, status: :bad_request
  end

  rescue_from ActionController::UnpermittedParameters do |e|
    render json: { error: { message: e.message } }, status: :bad_request
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: { message: e.message } }, status: :not_found
  end

  rescue_from ActiveModel::ValidationError do |e|
    render json: { error: { message: e.message } }, status: :bad_request
  end
end
