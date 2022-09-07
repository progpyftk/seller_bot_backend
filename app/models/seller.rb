class Seller < ApplicationRecord
  self.primary_key = 'ml_seller_id'
  has_many :items
end
