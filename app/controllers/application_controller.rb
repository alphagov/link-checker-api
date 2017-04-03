class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  before_action :require_signin_permission!

  protect_from_forgery with: :exception
end
