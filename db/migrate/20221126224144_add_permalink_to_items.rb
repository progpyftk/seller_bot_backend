class AddPermalinkToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :permalink, :string
  end
end
