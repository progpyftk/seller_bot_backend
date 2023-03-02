FactoryBot.define do
  factory :logistic_event do
    new_logistic { "MyString" }
    old_logistic { "MyString" }
    change_time { "2022-06-12 19:17:50" }
  end
end
