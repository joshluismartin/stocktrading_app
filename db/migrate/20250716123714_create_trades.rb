class CreateTrades < ActiveRecord::Migration[8.0]
  def change
    create_table :trades do |t|
      t.references :user, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.string :trade_type
      t.integer :quantity
      t.decimal :price

      t.timestamps
    end
  end
end
