class CreateVariations < ActiveRecord::Migration[6.1]
  def change
    create_table :variations do |t|
      t.string :variation_id
      t.string :sku
      t.string :ml_item_id
      t.belongs_to :item
      t.timestamps
    end
  end
end
