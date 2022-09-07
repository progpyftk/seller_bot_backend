class CreatePriceEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :price_events do |t|
      t.float :new_price
      t.float :old_price
      t.datetime :change_time
      t.string :item_id
      
      t.timestamps
    end
    add_foreign_key :price_events, :items, column: :item_id, primary_key: :ml_item_id
  end
end
