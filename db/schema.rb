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

ActiveRecord::Schema[6.1].define(version: 2017_07_13_101143) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "batch_checks", id: :serial, force: :cascade do |t|
    t.integer "batch_id", null: false
    t.integer "check_id", null: false
    t.integer "order", default: 0, null: false
    t.index ["batch_id"], name: "index_batch_checks_on_batch_id"
    t.index ["check_id"], name: "index_batch_checks_on_check_id"
  end

  create_table "batches", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_uri"
    t.string "webhook_secret_token"
    t.boolean "webhook_triggered", default: false, null: false
  end

  create_table "checks", id: :serial, force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "link_warnings", default: [], null: false, array: true
    t.string "link_errors", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "link_id", null: false
    t.string "problem_summary"
    t.string "suggested_fix"
    t.index ["link_id"], name: "index_checks_on_link_id"
  end

  create_table "links", id: :serial, force: :cascade do |t|
    t.string "uri", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.string "app_name"
    t.text "permissions"
    t.boolean "remotely_signed_out", default: false
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "batch_checks", "batches", on_delete: :cascade
  add_foreign_key "batch_checks", "checks"
  add_foreign_key "checks", "links"
end
