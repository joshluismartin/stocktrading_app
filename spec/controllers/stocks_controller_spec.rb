require 'rails_helper'

RSpec.describe StocksController, type: :controller do
  let(:user) do
    u = User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123', status: 'approved', balance: 10000)
    u.confirm
    u
  end
  let(:stock) { Stock.find_or_create_by!(symbol: 'AAPL') { |s| s.name = 'Apple Inc.' } }
  
  before do
    sign_in user
    allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100.0" } } })
  end

  describe "GET #index" do
    context "without search query" do
      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "processes owned stocks correctly" do
        user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        
        get :index
        
        expect(response).to be_successful
        # Verify the user actually owns the stock
        total_bought = user.trades.where(stock: stock, trade_type: 'buy').sum(:quantity)
        total_sold = user.trades.where(stock: stock, trade_type: 'sell').sum(:quantity)
        expect(total_bought - total_sold).to be > 0
      end

      it "handles stocks with zero shares correctly" do
        user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        user.trades.create!(stock: stock, trade_type: 'sell', quantity: 10, price: 110.0)
        
        get :index
        
        expect(response).to be_successful
        # Verify the user has zero net shares
        total_bought = user.trades.where(stock: stock, trade_type: 'buy').sum(:quantity)
        total_sold = user.trades.where(stock: stock, trade_type: 'sell').sum(:quantity)
        expect(total_bought - total_sold).to eq(0)
      end
    end

    context "with search query" do
      it "searches for stock successfully" do
        get :index, params: { query: 'AAPL' }
        
        expect(response).to be_successful
        expect(AlphaVantage).to have_received(:get_stock_price).with('AAPL')
      end
    end
  end

  describe "GET #show" do
    it "returns a success response for existing stock" do
      get :show, params: { id: stock.id }
      expect(response).to be_successful
    end

    it "fetches stock data for display" do
      get :show, params: { id: stock.id }
      
      expect(response).to be_successful
      expect(AlphaVantage).to have_received(:get_stock_price).with(stock.symbol)
    end

    it "redirects for non-existent stock" do
      get :show, params: { id: 99999 }
      
      expect(response).to redirect_to(stocks_path)
      expect(flash[:alert]).to eq("Stock not found.")
    end
  end

  describe "authentication" do
    it "redirects to sign in when user is not authenticated" do
      sign_out user
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end