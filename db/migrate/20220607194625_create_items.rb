class CreateItems < ActiveRecord::Migration[6.1]
  def change
    create_table :items, primary_key: 'ml_item_id', id: :string do |t|

      t.string :title
      t.float :price
      t.float :base_price
      t.integer :available_quantity
      t.integer :sold_quantity
      t.string :logistic_type
      t.timestamps
      t.belongs_to :seller
    end
  end
end
