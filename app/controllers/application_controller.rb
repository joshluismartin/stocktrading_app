class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :extract_latest_price
  before_action :restrict_unapproved_trader, if: :trader_controller?

  def extract_latest_price(stock_data)
    time_series_key = stock_data.keys.find { |key| key.include?("Time Series") }
    return nil unless time_series_key

    time_series = stock_data[time_series_key]
    latest_time = time_series.keys.sort.last
    latest_data = time_series[latest_time]
    latest_data["4. close"].to_f
  rescue
    nil
  end

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
