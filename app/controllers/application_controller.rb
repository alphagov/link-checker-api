class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  before_action :require_signin_permission!

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: { message: e.message } }, status: 400
  end
end
