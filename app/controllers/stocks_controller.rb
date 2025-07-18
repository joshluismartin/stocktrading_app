class StocksController < ApplicationController
  def index
    @stocks = Stock.all
  end

  def show
    symbol = params[:symbol]
    @stock = Stock.find_or_create_by(symbol: symbol)
    @stock_data = AlphaVantage.get_stock_price(symbol)
  end
end
