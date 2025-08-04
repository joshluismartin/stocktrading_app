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

      it "shows only owned stocks" do
        user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        
        get :index
        
        expect(assigns(:stocks)).to include(stock)
        expect(assigns(:latest_prices)).to have_key(stock.id)
      end

      it "does not show stocks with zero or negative shares" do
        user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        user.trades.create!(stock: stock, trade_type: 'sell', quantity: 10, price: 110.0)
        
        get :index
        
        expect(assigns(:stocks)).not_to include(stock)
      end
    end

    context "with search query" do
      it "searches for stock and sets search variables" do
        get :index, params: { query: 'AAPL' }
        
        expect(assigns(:searched_stock_data)).to be_present
        expect(assigns(:searched_stock_price)).to eq(100.0)
      end
    end
  end

  describe "GET #show" do
    it "returns a success response for existing stock" do
      get :show, params: { id: stock.id }
      expect(response).to be_successful
    end

    it "sets stock and stock data variables" do
      get :show, params: { id: stock.id }
      
      expect(assigns(:stock)).to eq(stock)
      expect(assigns(:stock_data)).to be_present
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