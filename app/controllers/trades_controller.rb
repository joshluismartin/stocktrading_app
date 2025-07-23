class TradesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_approved_user

  def index
    @trades = current_user.trades.order(created_at: :desc)
    if params[:type].present?
      @trades = @trades.where(trade_type: params[:type])
    end

    @total_buys = current_user.trades.where(trade_type: "buy").sum(:quantity)
    @total_sells = current_user.trades.where(trade_type: "sell").sum(:quantity)
    @total_spent = current_user.trades.where(trade_type: "buy").sum("quantity * price")
    @total_earned = current_user.trades.where(trade_type: "sell").sum("quantity * price")
  end

  def show
    @trade = current_user.trades.find(params[:id])
  end

  def new
    @trade = Trade.new
  end

  def create
    stock_id = params[:trade][:stock_id]
    trade_type = params[:trade][:trade_type]
    quantity = params[:trade][:quantity].to_i

    stock = Stock.find(stock_id)
    symbol = stock.symbol

    stock_data = AlphaVantage.get_stock_price(symbol)
    price = extract_latest_price(stock_data)
    total_cost = price * quantity

    if trade_type == "buy" && current_user.balance < total_cost
      redirect_back fallback_location: trades_path, alert: "You don't have enough balance to buy these shares"
      return
    end

    if trade_type == "sell"
      total_bought == current_user.trades.where(stock_id: stock_id, trade_type: "buy").sum(:quantity)
      total_sold == current_user.trades.where(stock_id: stock_id, trade_type: "sell").sum(:quantity)
      shares_owned = total_bought - total_sold

      if quantity > shares_owned
        redirect_fall back_location: trades_path, alert: "You don't have enough shares to sell"
        return
      end
    end

    @trade = current_user.trades.build(
      stock_id: stock_id,
      trade_type: trade_type,
      quantity: quantity,
      price: price
    )

    if @trade.save
      if trade_type == "buy"
        current_user.balance -= price * quantity
      elsif trade_type == "sell"
        current_user.balance += price * quantity
      end
      current_user.save!
      redirect_to trades_path, notice: "Trade successful"
    else
      redirect_back fallback_location: root_path, alert: "Trade failed."
    end
  end

  def portfolio
    holdings = Hash.new(0)
    current_user.trades.each do |trade|
      if trade.trade_type == "buy"
        holdings[trade.stock_id] += trade.quantity
      elsif trade.trade_type == "sell"
        holdings[trade.stock_id] -= trade.quantity
      end
    end

    @portfolio = holdings.select { |stock_id, shares| shares > 0 }

    @stocks = Stock.where(id: @portfolio.keys).index_by(&:id)

    @current_prices = {}
    @portfolio.each_key do |stock_id|
      stock = @stocks[stock_id]
      symbol = stock&.symbol
      if symbol
        stock_data = AlphaVantage.get_stock_price(symbol)
        @current_prices[stock_id] = extract_latest_price(stock_data)
      else
        @current_prices[stock_id] = nil
      end
    end
  end

  private

  def require_approved_user
    unless current_user.status == "approved"
      redirect_to root_path, alert: "Your account is pending approval."
    end
  end

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
end
