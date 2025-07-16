class ApplicationController < ActionController::Base
  include Pundit
  allow_browser versions: :modern
end
