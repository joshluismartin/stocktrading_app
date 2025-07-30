require 'rails_helper'

RSpec.describe StocksController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      Stock.create!(symbol: "AAPL", name: "Apple Inc.")
      allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100.0" } } })
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      stock = Stock.create!(symbol: "AAPL", name: "Apple Inc.")
      allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100.0" } } })
      get :show, params: { id: stock.id }
      expect(response).to be_successful
    end
  end
end
