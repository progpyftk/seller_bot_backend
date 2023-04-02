class AddVariationToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :variation, :boolean
  end
end
