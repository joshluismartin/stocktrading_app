class TradesController < ApplicationController
  before_action :authenticate_user!

  def index
    @trades = current_user.trades
  end

  def new
    @trade = Trade.new
    @stocks = Stock.all
  end

  def create
    symbol = params[:trade][:stock_symbol]
    trade_type = params[:trade][:trade_type]
    quantity = params[:trade][:quantity].to_i

    stock_data = AlphaVantage.get_stock_price(symbol)
    price = extract_latest_price(stock_data)


    @trade = current_user.trades.build(
      stock_id: stock_id,
      trade_type: trade_type,
      quantity: quantity,
      price: price
    )

    if @trade.save
      redirect_to trades_path, notice: "Trade successful!"
    else
      redirect_back fallback_location: root_path, alert: "Trade failed."
    end
  end


  private

  def extract_latest_price(stock_data)
    time_series_key = nil
    stock_data.each_key do |key|
      if key.include?("Time Series")
        time_series_key = key
        break
      end
    end

    return nil if time_series_key.nil?

    time_series = stock_data[time_series_key]

    latest_time = time_series.keys.sort.last

    latest_data = time_series[latest_time]
    closing_price = latest_data["4. close"]

    closing_price.to_f
  rescue
    nil
  end
end
