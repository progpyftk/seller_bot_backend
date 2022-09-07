FactoryBot.define do
  factory :price_event do
    new_price { 1.5 }
    old_price { 1.5 }
    updated_at { "2022-06-15 10:54:45" }
  end
end
