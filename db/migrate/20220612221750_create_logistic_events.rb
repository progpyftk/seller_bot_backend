class CreateLogisticEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :logistic_events do |t|
      t.string :new_logistic
      t.string :old_logistic
      t.datetime :change_time
      t.timestamps
      t.string :item_id
    end
    add_foreign_key :logistic_events, :items, column: :item_id, primary_key: :ml_item_id
  end
end
