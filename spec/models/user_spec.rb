require 'rails_helper'

RSpec.describe User, type: :model do
  it "is valid with valid attributes" do
    user = User.new(email: "test@example.com", password: "password123", password_confirmation: "password123", status: "approved")
    expect(user).to be_valid
  end

  it "is not valid without an email" do
    user = User.new(email: nil, password: "password123", password_confirmation: "password123", status: "approved")
    expect(user).not_to be_valid
  end

  it "is not valid without a status" do
    user = User.new(email: "test@example.com", password: "password123", password_confirmation: "password123", status: nil)
    expect(user).not_to be_valid
  end

  it "is not valid with duplicate email" do
    User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123", status: "approved")
    user2 = User.new(email: "test@example.com", password: "password123", password_confirmation: "password123", status: "approved")
    expect(user2).not_to be_valid
  end
end
