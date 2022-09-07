# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
item = Item.find_by(ml_item_id: "MLB1738846830")
item.logistic_events.create(
    new_logistic: "fulfillment",
    old_logistic: "xp_drop_off",
    change_time: "2022-06-15 23:48:56.503056"
)

item.logistic_events.create(
    new_logistic: "xp_drop_off",
    old_logistic: "fulfillment",
    change_time: "2022-05-15 23:48:56.503056"
)

item.logistic_events.create(
    new_logistic: "fulfillment",
    old_logistic: "xp_drop_off",
    change_time: "2022-04-15 23:48:56.503056"
)

item.logistic_events.create(
    new_logistic: "xp_drop_off",
    old_logistic: "fulfillment",
    change_time: "2022-03-15 23:48:56.503056"
)

item.logistic_events.create(
    new_logistic: "fulfillment",
    old_logistic: "xp_drop_off",
    change_time: "2022-02-15 23:48:56.503056"
)

item.logistic_events.create(
    new_logistic: "xp_drop_off",
    old_logistic: "fulfillment",
    change_time: "2022-02-15 23:48:56.503056"
)
