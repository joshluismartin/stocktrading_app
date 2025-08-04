class TradesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_approved_user

  def index
    @trades = current_user.trades.order(created_at: :desc).page(params[:page]).per(10)
    if params[:type].present?
      @trades = @trades.where(trade_type: params[:type])
    end

    if params[:symbol].present?
      @trades = @trades.joins(:stock).where("stocks.symbol ILIKE ?", "%#{params[:symbol]}%")
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
    if params[:trade].present?

      stock_id = params[:trade][:stock_id]
      trade_type = params[:trade][:trade_type]
      quantity = params[:trade][:quantity].to_i

      stock = Stock.find(stock_id)
      symbol = stock.symbol
      stock_data = AlphaVantage.get_stock_price(symbol)
      price = extract_latest_price(stock_data)


      if price.nil?
        redirect_back fallback_location: root_path, alert: "Unable to fetch current stock price. Please try again later."
        return
      end
    elsif params[:symbol].present? && params[:price].present?

      symbol = params[:symbol].upcase
      quantity = params[:quantity].to_i
      price = params[:price].to_f
      trade_type = "buy"

      stock = Stock.find_or_create_by(symbol: symbol) do |s|
        s.name = symbol
      end
      stock_id = stock.id
    else
      redirect_back fallback_location: root_path, alert: "Invalid trade parameters."
      return
    end

    total_cost = price * quantity

    if trade_type == "buy" && current_user.balance < total_cost
      redirect_back fallback_location: trades_path, alert: "You don't have enough balance to buy these shares"
      return
    end

    if trade_type == "sell"
      total_bought = current_user.trades.where(stock_id: stock_id, trade_type: "buy").sum(:quantity)
      total_sold = current_user.trades.where(stock_id: stock_id, trade_type: "sell").sum(:quantity)
      shares_owned = total_bought - total_sold

      if quantity > shares_owned
        redirect_back fallback_location: trades_path, alert: "You don't have enough shares to sell"
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
    shares_i_own = {}

    current_user.trades.includes(:stock).each do |trade|
      stock_id = trade.stock_id

      if shares_i_own[stock_id]

        if trade.trade_type == "buy"
          shares_i_own[stock_id] += trade.quantity
        else
          shares_i_own[stock_id] -= trade.quantity
        end
      else
        if trade.trade_type == "buy"
          shares_i_own[stock_id] = trade.quantity
        else
          shares_i_own[stock_id] = -trade.quantity
        end
      end
    end

    @portfolio = shares_i_own.select { |stock_id, quantity| quantity > 0 }

    @stocks = Stock.where(id: @portfolio.keys).index_by(&:id)
    @current_prices = {}

    @stocks.each do |stock_id, stock|
      stock_data = AlphaVantage.get_stock_price(stock.symbol)
      @current_prices[stock_id] = extract_latest_price(stock_data)
    end

    @total_money_i_spent = 0
    @total_current_value = 0
    @stock_performance = {}

    @portfolio.each do |stock_id, shares_i_own|
      stock = @stocks[stock_id]
      current_price = @current_prices[stock_id]

      my_buy_trades = current_user.trades.where(stock_id: stock_id, trade_type: "buy")
      money_i_spent_on_this_stock = my_buy_trades.sum { |trade| trade.price * trade.quantity }

      current_worth_of_this_stock = current_price ? (current_price * shares_i_own) : 0

      profit_or_loss = current_worth_of_this_stock - money_i_spent_on_this_stock
      profit_or_loss_percentage = money_i_spent_on_this_stock > 0 ? ((profit_or_loss / money_i_spent_on_this_stock) * 100) : 0

      @stock_performance[stock_id] = {
        total_invested: money_i_spent_on_this_stock,
        current_value: current_worth_of_this_stock,
        gain_loss: profit_or_loss,
        gain_loss_percentage: profit_or_loss_percentage,
        shares_owned: shares_i_own
      }

      @total_money_i_spent += money_i_spent_on_this_stock
      @total_current_value += current_worth_of_this_stock
    end

    @total_invested = @total_money_i_spent
    @current_portfolio_value = @total_current_value
    @total_gain_loss = @current_portfolio_value - @total_invested
    @total_gain_loss_percentage = @total_invested > 0 ? ((@total_gain_loss / @total_invested) * 100) : 0
  end

  private

  def require_approved_user
    unless current_user.status == "approved"
      redirect_to root_path, alert: "Your account is pending approval."
    end
  end
end
