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

    user.trades.create!(stock: stock, trade_type: 'buy', quantity: 10, price: 100.0)

    allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100.0" } } })
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { id: stock.id }
      expect(response).to be_successful
    end
  end
end