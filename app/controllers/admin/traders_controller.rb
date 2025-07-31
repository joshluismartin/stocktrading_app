class Admin::TradersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @traders = User.all
  end

  def show
    @trader = User.find(params[:id])
  end

  def new
    @trader = User.new
  end

  def create
    @trader = User.new(trader_params)
    @trader.admin = false
    @trader.status = "pending"
    if @trader.save
      redirect_to admin_trader_path(@trader), notice: "Trader created successfully!"
    else
      render :new
    end
  end

  def edit
    @trader = User.find(params[:id])
  end

  def update
    @trader = User.find(params[:id])
    if @trader.update(trader_params)
      redirect_to admin_trader_path(@trader), notice: "Trader updated successfully!"
    else
      render :edit
    end
  end

  def destroy
    @trader = User.find(params[:id])
    if @trader.trades.exists?
      redirect_to admin_traders_path, alert: "Cannot delete trader with existing trades."
    else
      @trader.destroy
      redirect_to admin_traders_path, notice: "Trader deleted."
    end
  end

  def pending
    @traders = User.where(admin: false, status: "pending")
    render :index
  end

  def approve
    @trader = User.find(params[:id])


    was_pending = @trader.status == "pending"

    if @trader.update(status: "approved")

      if was_pending
        TraderMailer.account_approved(@trader).deliver_now
        redirect_to admin_trader_path(@trader), notice: "Trader approved and notification email sent!"
      else
        redirect_to admin_trader_path(@trader), notice: "Trader status updated!"
      end
    else
      redirect_to admin_trader_path(@trader), alert: "Failed to approve trader."
    end
  end

  private

  def require_admin
    redirect_to root_path, alert: "Not authorized" unless current_user.admin?
  end

  def trader_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :status, :admin)
  end
end
