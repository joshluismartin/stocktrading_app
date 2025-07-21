class Admin::TradersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @traders = User.where(admin: false)
  end

  def show
    @trader = User.find(params[:id])
  end

  def destroy
    @trader = User.find(parmams[:id])
    @trader.destroy
    redirect_to admin_traders_path, notice: "Trader deleted."
  end

  def pending
    @traders = User.where(admin: false, status: "pending")
    render :index
  end

  def approve
    @trader = User.find(params[:id])
    @trader.update(status: "approved")
    redirect_to admin_trader_path(@trader), notice: "Trader approved!"
  end


  private

  def require_admin
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end
end
