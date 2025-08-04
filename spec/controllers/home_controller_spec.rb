require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    context "when user is not signed in" do
      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "does not set dashboard variables" do
        get :index
        expect(assigns(:recent_trades)).to be_nil
        expect(assigns(:portfolio_holdings)).to be_nil
        expect(assigns(:total_trades)).to be_nil
      end
    end

    context "when user is signed in" do
      let(:user) do
        u = User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123', status: 'approved', balance: 10000)
        u.confirm
        u
      end
      let(:stock) { Stock.create!(symbol: 'AAPL', name: 'Apple Inc.') }

      before do
        sign_in user
        allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "150.0" } } })
      end

      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "sets dashboard variables" do
        user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        
        get :index
        
        expect(assigns(:recent_trades)).to be_present
        expect(assigns(:portfolio_holdings)).to be_present
        expect(assigns(:total_trades)).to eq(1)
      end

      it "calculates portfolio performance correctly" do
        user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        
        get :index
        
        expect(assigns(:total_invested)).to eq(1000.0)
        expect(assigns(:current_portfolio_value)).to eq(1500.0) # 10 shares * $150
        expect(assigns(:total_gain_loss)).to eq(500.0)
        expect(assigns(:total_gain_loss_percentage)).to eq(50.0)
      end

      it "handles empty portfolio correctly" do
        get :index
        
        expect(assigns(:total_invested)).to eq(0)
        expect(assigns(:current_portfolio_value)).to eq(0)
        expect(assigns(:total_gain_loss)).to eq(0)
        expect(assigns(:total_gain_loss_percentage)).to eq(0)
      end
    end
  end
end
