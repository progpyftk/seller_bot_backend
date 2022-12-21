class AddSkuToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :sku, :string
  end
end
