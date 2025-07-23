class StocksController < ApplicationController
  def index
    @stocks = Stock.all
    @latest_prices = {}

    @stocks.each do |stock|
      stock_data = AlphaVantage.get_stock_price(stock.symbol)
      @latest_prices[stock.id] = extract_latest_price(stock_data)
    end
  end

  def show
    symbol = params[:symbol]
    @stock = Stock.find_or_create_by(symbol: symbol)
    @stock_data = AlphaVantage.get_stock_price(symbol)
  end
end
