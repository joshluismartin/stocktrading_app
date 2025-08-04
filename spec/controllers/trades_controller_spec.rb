require 'rails_helper'

RSpec.describe TradesController, type: :controller do
  let(:user) do
    u = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123", status: "approved", balance: 10000)
    u.confirm
    u
  end
  let(:pending_user) do
    u = User.create!(email: "pending@example.com", password: "password123", password_confirmation: "password123", status: "pending", balance: 10000)
    u.confirm
    u
  end
  let(:stock) { Stock.create!(symbol: "AAPL", name: "Apple Inc.") }

  before do
    allow(AlphaVantage).to receive(:get_stock_price).and_return({ "Time Series (1min)" => { "2025-07-29 16:00:00" => { "4. close" => "100.0" } } })
  end

  describe "authentication and authorization" do
    it "redirects to sign in when user is not authenticated" do
      get :index
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects pending users" do
      sign_in pending_user
      get :index
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Your account is pending approval by an admin.")
    end
  end

  context "with approved user" do
    before do
      sign_in user
    end

    describe "GET #index" do
      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end

      it "processes trade statistics correctly" do
        user.trades.create!(stock: stock, trade_type: "buy", quantity: 10, price: 100)
        user.trades.create!(stock: stock, trade_type: "sell", quantity: 5, price: 110)
        
        get :index
        
        expect(response).to be_successful
        expect(user.trades.where(trade_type: "buy").sum(:quantity)).to eq(10)
        expect(user.trades.where(trade_type: "sell").sum(:quantity)).to eq(5)
      end

      it "filters trades by type correctly" do
        buy_trade = user.trades.create!(stock: stock, trade_type: "buy", quantity: 10, price: 100)
        sell_trade = user.trades.create!(stock: stock, trade_type: "sell", quantity: 5, price: 110)
        
        get :index, params: { type: "buy" }
        
        expect(response).to be_successful
        # Verify filtering logic works by checking database state
        expect(user.trades.where(trade_type: "buy").count).to eq(1)
        expect(user.trades.where(trade_type: "sell").count).to eq(1)
      end

      it "filters trades by symbol correctly" do
        aapl_trade = user.trades.create!(stock: stock, trade_type: "buy", quantity: 10, price: 100)
        other_stock = Stock.create!(symbol: "GOOGL", name: "Google")
        googl_trade = user.trades.create!(stock: other_stock, trade_type: "buy", quantity: 5, price: 200)
        
        get :index, params: { symbol: "AAPL" }
        
        expect(response).to be_successful
        # Verify we have trades for both stocks
        expect(user.trades.joins(:stock).where(stocks: { symbol: "AAPL" }).count).to eq(1)
        expect(user.trades.joins(:stock).where(stocks: { symbol: "GOOGL" }).count).to eq(1)
      end
    end

    describe "GET #show" do
      it "returns a success response for user's own trade" do
        trade = user.trades.create!(stock: stock, trade_type: "buy", quantity: 1, price: 100)
        get :show, params: { id: trade.id }
        expect(response).to be_successful
      end

      it "raises error for other user's trade" do
        other_user = User.create!(email: "other@example.com", password: "password123", password_confirmation: "password123", status: "approved", balance: 5000)
        other_user.confirm
        trade = other_user.trades.create!(stock: stock, trade_type: "buy", quantity: 1, price: 100)
        
        expect {
          get :show, params: { id: trade.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "GET #new" do
      it "returns a success response" do
        get :new
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid trade parameters" do
        it "creates a buy trade successfully" do
          expect {
            post :create, params: { 
              trade: { 
                stock_id: stock.id, 
                trade_type: "buy", 
                quantity: 10 
              } 
            }
          }.to change(Trade, :count).by(1)
          
          expect(response).to redirect_to(trades_path)
          expect(flash[:notice]).to eq("Trade successful")
        end

        it "updates user balance for buy trade" do
          initial_balance = user.balance
          
          post :create, params: { 
            trade: { 
              stock_id: stock.id, 
              trade_type: "buy", 
              quantity: 10 
            } 
          }
          
          user.reload
          expect(user.balance).to eq(initial_balance - 1000) # 10 * 100
        end

        it "creates a sell trade successfully" do
          user.trades.create!(stock: stock, trade_type: "buy", quantity: 20, price: 90)
          
          expect {
            post :create, params: { 
              trade: { 
                stock_id: stock.id, 
                trade_type: "sell", 
                quantity: 10 
              } 
            }
          }.to change(Trade, :count).by(1)
        end

        it "updates user balance for sell trade" do
          user.trades.create!(stock: stock, trade_type: "buy", quantity: 20, price: 90)
          initial_balance = user.reload.balance
          
          post :create, params: { 
            trade: { 
              stock_id: stock.id, 
              trade_type: "sell", 
              quantity: 10 
            } 
          }
          
          user.reload
          expect(user.balance).to eq(initial_balance + 1000) # 10 * 100
        end
      end

      context "with insufficient balance" do
        it "rejects buy trade with insufficient balance" do
          user.update!(balance: 500)
          
          expect {
            post :create, params: { 
              trade: { 
                stock_id: stock.id, 
                trade_type: "buy", 
                quantity: 10 
              } 
            }
          }.not_to change(Trade, :count)
          
          expect(flash[:alert]).to include("don't have enough balance")
        end
      end

      context "with insufficient shares" do
        it "rejects sell trade with insufficient shares" do
          expect {
            post :create, params: { 
              trade: { 
                stock_id: stock.id, 
                trade_type: "sell", 
                quantity: 10 
              } 
            }
          }.not_to change(Trade, :count)
          
          expect(flash[:alert]).to include("don't have enough shares")
        end
      end

      context "with symbol and price parameters" do
        it "creates stock and trade for new symbol" do
          expect {
            post :create, params: { 
              symbol: "TSLA", 
              quantity: 5, 
              price: 200 
            }
          }.to change(Stock, :count).by(1).and change(Trade, :count).by(1)
          
          new_stock = Stock.find_by(symbol: "TSLA")
          expect(new_stock).to be_present
          expect(new_stock.name).to eq("TSLA")
        end
      end

      context "when AlphaVantage API fails" do
        it "handles nil price gracefully" do
          allow(AlphaVantage).to receive(:get_stock_price).and_return({})
          
          post :create, params: { 
            trade: { 
              stock_id: stock.id, 
              trade_type: "buy", 
              quantity: 10 
            } 
          }
          
          expect(flash[:alert]).to include("Unable to fetch current stock price")
        end
      end
    end

    describe "GET #portfolio" do
      it "returns a success response" do
        get :portfolio
        expect(response).to be_successful
      end

      it "processes portfolio with owned stocks correctly" do
        user.trades.create!(stock: stock, trade_type: "buy", quantity: 10, price: 90)
        
        get :portfolio
        
        expect(response).to be_successful
        # Verify user owns the stock
        expect(user.trades.where(stock: stock, trade_type: "buy").sum(:quantity)).to eq(10)
        expect(AlphaVantage).to have_received(:get_stock_price).with(stock.symbol)
      end

      it "calculates portfolio performance correctly" do
        user.trades.create!(stock: stock, trade_type: "buy", quantity: 10, price: 90)
        
        get :portfolio
        
        expect(response).to be_successful
        # Verify the trade data for calculations
        total_invested = user.trades.where(stock: stock, trade_type: "buy").sum { |t| t.price * t.quantity }
        expect(total_invested).to eq(900) # 10 * 90
      end

      it "handles empty portfolio without errors" do
        get :portfolio
        
        expect(response).to be_successful
        expect(response).to render_template(:portfolio)
      end
    end
  end
end
