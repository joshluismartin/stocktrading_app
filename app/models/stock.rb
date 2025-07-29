class Stock < ApplicationRecord
  has_many :trades

  validates :symbol, presence: true, uniqueness: true
  validates :name, presence: true
end
