class TradesController < ApplicationController
  before_action :authenticate_user!
  def new
    @trade = Trade.new
    @stocks = Stock.all
  end

  def create
    @trade = current_user.trades.build(trade_params)
    if @trade.save
      redirect_to trades_path, notice: "Trade successful!"
    else
      render :new
    end
  end

  def index
    @trades = current_user.trades
  end


  private

  def trade_params
    params.require(:trade).permit(:stock_id, :trade_type, :quantity, :price)
  end
end
