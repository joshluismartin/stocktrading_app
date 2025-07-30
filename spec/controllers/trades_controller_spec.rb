require 'rails_helper'

RSpec.describe TradesController, type: :controller do
  let(:user) do
    u = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123", status: "approved", balance: 10000)
    u.confirm
    u
  end
  let(:stock) { Stock.create!(symbol: "AAPL", name: "Apple Inc.") }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response for user's own trade" do
      trade = user.trades.create!(stock: stock, trade_type: "buy", quantity: 1, price: 100)
      get :show, params: { id: trade.id }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    it "creates a new trade with enough balance" do
      allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100.0" } } })
      expect {
        post :create, params: { trade: { stock_id: stock.id, trade_type: "buy", quantity: 1 } }
      }.to change(Trade, :count).by(1)
    end

    it "does not create a trade with insufficient balance" do
      allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100000.0" } } })
      expect {
        post :create, params: { trade: { stock_id: stock.id, trade_type: "buy", quantity: 1 } }
      }.not_to change(Trade, :count)
      expect(flash[:alert]).to match(/don't have enough balance/)
    end
  end
end
