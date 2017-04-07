class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  before_action :require_signin_permission!
end
