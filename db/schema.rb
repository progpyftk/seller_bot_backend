# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_12_21_004853) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "items", primary_key: "ml_item_id", id: :string, force: :cascade do |t|
    t.string "title"
    t.float "price"
    t.float "base_price"
    t.integer "available_quantity"
    t.integer "sold_quantity"
    t.string "logistic_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "seller_id"
    t.string "permalink"
    t.boolean "free_shipping"
    t.string "sku"
    t.index ["seller_id"], name: "index_items_on_seller_id"
  end

  create_table "logistic_events", force: :cascade do |t|
    t.string "new_logistic"
    t.string "old_logistic"
    t.datetime "change_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "item_id"
  end

  create_table "price_events", force: :cascade do |t|
    t.float "new_price"
    t.float "old_price"
    t.datetime "change_time"
    t.string "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "sellers", primary_key: "ml_seller_id", id: :string, force: :cascade do |t|
    t.string "nickname"
    t.string "code"
    t.string "access_token"
    t.string "refresh_token"
    t.datetime "last_auth_at"
    t.string "auth_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "stocks", force: :cascade do |t|
    t.string "sku"
    t.integer "quantity"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "variations", force: :cascade do |t|
    t.string "variation_id"
    t.string "sku"
    t.string "ml_item_id"
    t.bigint "item_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_variations_on_item_id"
  end

  add_foreign_key "logistic_events", "items", primary_key: "ml_item_id"
  add_foreign_key "price_events", "items", primary_key: "ml_item_id"
end
