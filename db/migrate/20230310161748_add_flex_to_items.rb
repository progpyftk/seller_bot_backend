class AddFlexToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :flex, :boolean
  end
end
