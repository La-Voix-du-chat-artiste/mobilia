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

ActiveRecord::Schema[7.1].define(version: 2023_10_25_181835) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "absences", force: :cascade do |t|
    t.date "started_on"
    t.date "ended_on"
    t.integer "reason", default: 0, null: false
    t.bigint "transporter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["transporter_id"], name: "index_absences_on_transporter_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "label"
    t.string "street"
    t.string "postcode"
    t.string "town"
    t.string "country"
    t.float "latitude"
    t.float "longitude"
    t.string "addressable_type", null: false
    t.bigint "addressable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "email"
    t.integer "kind", default: 0, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "archived_at"
    t.bigint "favorite_trip_transporter_id"
    t.bigint "favorite_trip_back_transporter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["favorite_trip_back_transporter_id"], name: "index_customers_on_favorite_trip_back_transporter_id"
    t.index ["favorite_trip_transporter_id"], name: "index_customers_on_favorite_trip_transporter_id"
  end

  create_table "daily_quests", force: :cascade do |t|
    t.date "started_on"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_daily_quests_on_company_id"
  end

  create_table "missions", force: :cascade do |t|
    t.time "drop_time"
    t.integer "drop_duration"
    t.integer "position", default: 1, null: false
    t.bigint "customer_id", null: false
    t.bigint "place_id", null: false
    t.bigint "daily_quest_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_missions_on_customer_id"
    t.index ["daily_quest_id"], name: "index_missions_on_daily_quest_id"
    t.index ["place_id"], name: "index_missions_on_place_id"
  end

  create_table "places", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.boolean "enabled", default: true, null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_places_on_company_id"
  end

  create_table "settings", force: :cascade do |t|
    t.json "options", default: {}, null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_settings_on_company_id"
  end

  create_table "steps", force: :cascade do |t|
    t.string "title"
    t.datetime "started_at"
    t.datetime "arrival_at"
    t.integer "departure_point_icon", default: 0, null: false
    t.integer "arrival_point_icon", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.json "route", default: {}, null: false
    t.bigint "transporter_id"
    t.bigint "mission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["mission_id"], name: "index_steps_on_mission_id"
    t.index ["transporter_id"], name: "index_steps_on_transporter_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "access_count_to_reset_password_page", default: 0
    t.string "type"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.json "availabilities", default: {}, null: false
    t.datetime "archived_at"
    t.bigint "vehicle_id"
    t.bigint "company_id"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
    t.index ["vehicle_id"], name: "index_users_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "name"
    t.string "number_plate"
    t.float "width"
    t.float "height"
    t.float "length"
    t.integer "max_regular_seats", default: 0, null: false
    t.integer "max_wheelchair_seats", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.boolean "substitution", default: false, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id"], name: "index_vehicles_on_company_id"
    t.index ["number_plate"], name: "index_vehicles_on_number_plate", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "settings", "companies"
end
