class CreateSellers < ActiveRecord::Migration[6.1]
  def change
    create_table :sellers, primary_key: 'ml_seller_id', id: :string do |t|
      t.string :nickname
      t.string :code
      t.string :access_token
      t.string :refresh_token
      t.datetime :last_auth_at
      t.string :auth_status
      t.timestamps
      t.belongs_to :user
    end
  end
end
