class CreateEstoque < ActiveRecord::Migration[6.1]
  def change
    create_table :estoques do |t|
      t.string :sku
      t.integer :quantidade

      t.timestamps
    end
  end
end
