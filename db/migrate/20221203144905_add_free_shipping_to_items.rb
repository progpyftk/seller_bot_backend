class AddFreeShippingToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :free_shipping, :boolean
  end
end
