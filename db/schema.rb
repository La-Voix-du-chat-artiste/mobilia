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

ActiveRecord::Schema[8.1].define(version: 2026_09_14_103000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "absences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ended_on"
    t.integer "reason", default: 0, null: false
    t.date "started_on"
    t.bigint "transporter_id", null: false
    t.datetime "updated_at", null: false
    t.index ["transporter_id"], name: "index_absences_on_transporter_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.bigint "addressable_id", null: false
    t.string "addressable_type", null: false
    t.string "country"
    t.datetime "created_at", null: false
    t.string "label"
    t.float "latitude"
    t.float "longitude"
    t.string "postcode"
    t.string "street"
    t.string "town"
    t.datetime "updated_at", null: false
    t.index ["addressable_type", "addressable_id"], name: "index_addresses_on_addressable"
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "archived_at"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "enabled", default: true, null: false
    t.bigint "favorite_trip_back_transporter_id"
    t.bigint "favorite_trip_transporter_id"
    t.string "first_name"
    t.integer "kind", default: 0, null: false
    t.string "last_name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_customers_on_company_id"
    t.index ["favorite_trip_back_transporter_id"], name: "index_customers_on_favorite_trip_back_transporter_id"
    t.index ["favorite_trip_transporter_id"], name: "index_customers_on_favorite_trip_transporter_id"
  end

  create_table "daily_quests", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.date "started_on"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_daily_quests_on_company_id"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "callback_priority"
    t.text "callback_queue_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "jobs_finished_at"
    t.text "on_discard"
    t.text "on_finish"
    t.text "on_success"
    t.jsonb "serialized_properties"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id", null: false
    t.datetime "created_at", null: false
    t.interval "duration"
    t.text "error"
    t.text "error_backtrace", array: true
    t.integer "error_event", limit: 2
    t.datetime "finished_at"
    t.text "job_class"
    t.uuid "process_id"
    t.text "queue_name"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
    t.index ["process_id", "created_at"], name: "index_good_job_executions_on_process_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_type", limit: 2
    t.jsonb "state"
    t.datetime "updated_at", null: false
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "key"
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "active_job_id"
    t.uuid "batch_callback_id"
    t.uuid "batch_id"
    t.text "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "cron_at"
    t.text "cron_key"
    t.text "error"
    t.integer "error_event", limit: 2
    t.integer "executions_count"
    t.datetime "finished_at"
    t.boolean "is_discrete", default: true, null: false
    t.text "job_class"
    t.text "labels", array: true
    t.integer "lock_type", limit: 2
    t.datetime "locked_at"
    t.uuid "locked_by_id"
    t.datetime "performed_at"
    t.integer "priority"
    t.text "queue_name"
    t.uuid "retried_good_job_id"
    t.datetime "scheduled_at"
    t.jsonb "serialized_params"
    t.datetime "updated_at", null: false
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["created_at"], name: "index_good_jobs_on_created_at"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at", unique: true
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at_only", where: "(finished_at IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_on_discarded", order: :desc, where: "((finished_at IS NOT NULL) AND (error IS NOT NULL))"
    t.index ["id"], name: "index_good_jobs_on_unfinished_or_errored", where: "((finished_at IS NULL) OR (error IS NOT NULL))"
    t.index ["job_class"], name: "index_good_jobs_on_job_class"
    t.index ["labels"], name: "index_good_jobs_on_labels", where: "(labels IS NOT NULL)", using: :gin
    t.index ["locked_by_id"], name: "index_good_jobs_on_locked_by_id", where: "(locked_by_id IS NOT NULL)"
    t.index ["priority", "created_at"], name: "index_good_job_jobs_for_candidate_lookup", where: "(finished_at IS NULL)"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_for_candidate_dequeue_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["priority", "scheduled_at", "id"], name: "index_good_jobs_on_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["priority", "scheduled_at"], name: "index_good_jobs_on_priority_scheduled_at_unfinished_unlocked", where: "((finished_at IS NULL) AND (locked_by_id IS NULL))"
    t.index ["queue_name", "scheduled_at", "id"], name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished", where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["queue_name"], name: "index_good_jobs_on_queue_name"
    t.index ["scheduled_at", "queue_name"], name: "index_good_jobs_on_scheduled_at_and_queue_name"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "missions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.bigint "daily_quest_id", null: false
    t.integer "drop_duration"
    t.time "drop_time"
    t.bigint "place_id", null: false
    t.integer "position", default: 1, null: false
    t.boolean "round_trip", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_missions_on_customer_id"
    t.index ["daily_quest_id"], name: "index_missions_on_daily_quest_id"
    t.index ["place_id"], name: "index_missions_on_place_id"
  end

  create_table "places", force: :cascade do |t|
    t.datetime "archived_at"
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "enabled", default: true, null: false
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_places_on_company_id"
  end

  create_table "settings", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.json "options", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_settings_on_company_id", unique: true
  end

  create_table "steps", force: :cascade do |t|
    t.datetime "arrival_at"
    t.integer "arrival_point_icon", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "departure_point_icon", default: 0, null: false
    t.bigint "mission_id", null: false
    t.integer "role", default: 0, null: false
    t.json "route", default: {}, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.bigint "transporter_id"
    t.datetime "updated_at", null: false
    t.index ["mission_id"], name: "index_steps_on_mission_id"
    t.index ["transporter_id"], name: "index_steps_on_transporter_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "access_count_to_reset_password_page", default: 0
    t.datetime "archived_at"
    t.json "availabilities", default: {}, null: false
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.string "crypted_password"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.integer "role", default: 0, null: false
    t.string "salt"
    t.string "type"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email", "company_id"], name: "index_users_on_email_and_company_id", unique: true
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
    t.index ["vehicle_id"], name: "index_users_on_vehicle_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.float "height"
    t.float "length"
    t.integer "max_regular_seats", default: 0, null: false
    t.integer "max_wheelchair_seats", default: 0, null: false
    t.string "name"
    t.string "number_plate"
    t.integer "status", default: 0, null: false
    t.boolean "substitution", default: false, null: false
    t.datetime "updated_at", null: false
    t.float "width"
    t.index ["company_id", "number_plate"], name: "index_vehicles_on_company_id_and_number_plate", unique: true
    t.index ["company_id"], name: "index_vehicles_on_company_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "settings", "companies"
end
