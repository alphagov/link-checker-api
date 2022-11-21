class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods
  before_action :authenticate_user!
end
