class StocksController < ApplicationController
  before_action :authenticate_user!
  def index
    if params[:query].present?
      @searched_stock_data = AlphaVantage.get_stock_price(params[:query])
      @searched_stock_price = extract_latest_price(@searched_stock_data)
    end

    user_trades = current_user.trades.includes(:stock)
    stock_quantities = Hash.new(0)

    user_trades.each do |trade|
      if trade.trade_type == "buy"
        stock_quantities[trade.stock_id] += trade.quantity
      elsif trade.trade_type == "sell"
        stock_quantities[trade.stock_id] -= trade.quantity
      end
    end

    owned_stock_ids = stock_quantities.select { |stock_id, qty| qty > 0 }.keys
    @stocks = Stock.where(id: owned_stock_ids)
    @latest_prices = {}

    @stocks.each do |stock|
      stock_data = AlphaVantage.get_stock_price(stock.symbol)
      @latest_prices[stock.id] = extract_latest_price(stock_data)
    end
  end

  def show
    @stock = Stock.find_by(id: params[:id])
    if @stock.nil?
      redirect_to stocks_path, alert: "Stock not found."
      return
    end

    @stock_data = AlphaVantage.get_stock_price(@stock.symbol)
  end
end

