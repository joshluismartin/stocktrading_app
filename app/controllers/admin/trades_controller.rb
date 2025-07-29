class Admin::TradesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @trades = Trade.includes(:user, :stock).order(created_at: :desc)

    if params[:symbol].present?
      @trades = @trades.select do |trade|
        trade.stock.symbol.downcase.include?(params[:symbol].downcase)
      end
    end

    if params[:email].present?
      @trades = @trades.select do |trade|
        trade.user.email.downcase.include?(params[:email].downcase)
      end
    end

    @trades = Kaminari.paginate_array(@trades).page(params[:page]).per(20)
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Not authorized"
    end
  end
end
