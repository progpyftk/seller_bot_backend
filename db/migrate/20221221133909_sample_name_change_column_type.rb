class SampleNameChangeColumnType < ActiveRecord::Migration[6.1]
  def change
    change_column(:variations, :item_id, :string)
  end
end
