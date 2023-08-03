class AddIdProdutoToEstoques < ActiveRecord::Migration[6.1]
  def change
    add_column :estoques, :id_produto, :string
  end
end
