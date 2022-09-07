class Item < ApplicationRecord
  include ActiveModel::Dirty
  self.primary_key = 'ml_item_id'
  belongs_to :seller
  has_many :logistic_events
  has_many :price_events
end
