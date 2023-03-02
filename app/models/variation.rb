class Variation < ApplicationRecord
  self.primary_key = 'variation_id'
  belongs_to :item
end
