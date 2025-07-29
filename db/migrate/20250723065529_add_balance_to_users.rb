class AddBalanceToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :balance, :decimal, precision: 12, scale: 2, default: 10000
  end
end
