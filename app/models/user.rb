class User < ApplicationRecord
  has_many :trades

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # Beginner-friendly validations
  validates :email, presence: true, uniqueness: true
  validates :status, presence: true # assuming you use status for approval
end
