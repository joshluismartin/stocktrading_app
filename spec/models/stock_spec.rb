require 'rails_helper'

RSpec.describe Stock, type: :model do
  it "is valid with valid attributes" do
    stock = Stock.new(symbol: "AAPL", name: "Apple Inc.")
    expect(stock).to be_valid
  end

  it "is not valid without a symbol" do
    stock = Stock.new(symbol: nil, name: "Apple Inc.")
    expect(stock).not_to be_valid
  end

  it "is not valid without a name" do
    stock = Stock.new(symbol: "AAPL", name: nil)
    expect(stock).not_to be_valid
  end

  it "is not valid with duplicate symbol" do
    Stock.create!(symbol: "AAPL", name: "Apple Inc.")
    stock2 = Stock.new(symbol: "AAPL", name: "Apple Inc. 2")
    expect(stock2).not_to be_valid
  end
end
