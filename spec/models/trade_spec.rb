require 'rails_helper'

RSpec.describe Trade, type: :model do
  let(:user) { User.create!(email: "trader@example.com", password: "password123", password_confirmation: "password123", status: "approved") }
  let(:stock) { Stock.create!(symbol: "AAPL", name: "Apple Inc.") }

  it "is valid with valid attributes" do
    trade = Trade.new(user: user, stock: stock, trade_type: "buy", quantity: 10, price: 100.0)
    expect(trade).to be_valid
  end

  it "is not valid without a trade_type" do
    trade = Trade.new(user: user, stock: stock, trade_type: nil, quantity: 10, price: 100.0)
    expect(trade).not_to be_valid
  end

  it "is not valid with an invalid trade_type" do
    trade = Trade.new(user: user, stock: stock, trade_type: "hold", quantity: 10, price: 100.0)
    expect(trade).not_to be_valid
  end

  it "is not valid without a quantity" do
    trade = Trade.new(user: user, stock: stock, trade_type: "buy", quantity: nil, price: 100.0)
    expect(trade).not_to be_valid
  end

  it "is not valid with negative quantity" do
    trade = Trade.new(user: user, stock: stock, trade_type: "buy", quantity: -5, price: 100.0)
    expect(trade).not_to be_valid
  end

  it "is not valid without a price" do
    trade = Trade.new(user: user, stock: stock, trade_type: "buy", quantity: 10, price: nil)
    expect(trade).not_to be_valid
  end

  it "is not valid with zero price" do
    trade = Trade.new(user: user, stock: stock, trade_type: "buy", quantity: 10, price: 0)
    expect(trade).not_to be_valid
  end
end
