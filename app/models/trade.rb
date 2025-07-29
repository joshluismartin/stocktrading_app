class Trade < ApplicationRecord
  belongs_to :user
  belongs_to :stock

  validates :trade_type, presence: true, inclusion: { in: %w[buy sell] }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }
end
