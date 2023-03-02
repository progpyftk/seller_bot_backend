class CreateVariations < ActiveRecord::Migration[6.1]
  def change
    create_table :variations, primary_key: 'variation_id', id: :string do |t|
      t.string :sku
      t.belongs_to :item
      t.timestamps
    end
  end
end


