FactoryBot.define do
  factory :item do
    item_id { "MyString" }
    title { "MyString" }
    ml_seller_id { "MyString" }
    price { 1.5 }
    base_price { 1.5 }
    available_quantity { 1 }
    sold_quantity { 1 }
    logistic_type { "MyString" }
  end
end
