class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :restrict_unapproved_trader, if: :trader_controller?

  private

  def restrict_unapproved_trader
    if user_signed_in? && !current_user.admin? && current_user.status != "approved"
      redirect_to root_path, alert: "Your account is pending approval by an admin."
    end
  end

  def trader_controller?
    controller_path.start_with?("trades") || controller_path.start_with?("stocks")
  end
end
