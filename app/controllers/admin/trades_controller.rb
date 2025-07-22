class Admin::TradesController < ApplicationController
  def index
    @trades = Trade.includes(:user, :stock).order(created_at: :desc)
  end
end
