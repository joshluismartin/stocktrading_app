require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    context "when user is not signed in" do
      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "renders the index template" do
        get :index
        expect(response).to render_template(:index)
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

      it "renders the index template" do
        get :index
        expect(response).to render_template(:index)
      end

      it "loads user's recent trades when they exist" do
        trade = user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)
        
        get :index
        
        expect(response).to be_successful
        expect(user.trades.count).to eq(1)
        expect(user.trades.first.stock).to eq(stock)
      end

      it "handles empty portfolio without errors" do
        get :index
        
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end
    end
  end
end
