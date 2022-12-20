class CreateStocks < ActiveRecord::Migration[6.1]
  def change
    create_table :stocks do |t|
      t.string :sku
      t.integer :quantity

      t.timestamps
    end
  end
end
