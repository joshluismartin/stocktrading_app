class HomeController < ApplicationController
  def index
    if user_signed_in?
      @recent_trades = current_user.trades.includes(:stock).order(created_at: :desc).limit(5)


      @portfolio_holdings = calculate_portfolio_holdings

      calculate_portfolio_performance

      @total_trades = current_user.trades.count
    end
  end

  private

  def calculate_portfolio_holdings
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

    portfolio = shares_i_own.select { |stock_id, quantity| quantity > 0 }

    stocks = Stock.where(id: portfolio.keys).index_by(&:id)
    portfolio_with_stocks = {}
    portfolio.each do |stock_id, quantity|
      stock = stocks[stock_id]
      portfolio_with_stocks[stock] = quantity if stock
    end

    portfolio_with_stocks
  end

  def calculate_portfolio_performance
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

    portfolio = shares_i_own.select { |stock_id, quantity| quantity > 0 }
    stocks = Stock.where(id: portfolio.keys).index_by(&:id)
    current_prices = {}

    stocks.each do |stock_id, stock|
      stock_data = AlphaVantage.get_stock_price(stock.symbol)
      current_prices[stock_id] = extract_latest_price(stock_data)
    end

    @total_money_i_spent = 0
    @total_current_value = 0

    portfolio.each do |stock_id, shares_i_own|
      current_price = current_prices[stock_id]

      my_buy_trades = current_user.trades.where(stock_id: stock_id, trade_type: "buy")
      money_i_spent_on_this_stock = my_buy_trades.sum { |trade| trade.price * trade.quantity }

      current_worth_of_this_stock = current_price ? (current_price * shares_i_own) : 0

      @total_money_i_spent += money_i_spent_on_this_stock
      @total_current_value += current_worth_of_this_stock
    end

    @total_invested = @total_money_i_spent
    @current_portfolio_value = @total_current_value
    @total_gain_loss = @current_portfolio_value - @total_invested
    @total_gain_loss_percentage = @total_invested > 0 ? ((@total_gain_loss / @total_invested) * 100) : 0

    @portfolio_value = @current_portfolio_value
  end
end

