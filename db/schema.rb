# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170405130148) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "batches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "batches_checks", force: :cascade do |t|
    t.integer "batch_id"
    t.integer "check_id"
    t.index ["batch_id"], name: "index_batches_checks_on_batch_id", using: :btree
    t.index ["check_id"], name: "index_batches_checks_on_check_id", using: :btree
  end

  create_table "checks", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.json     "link_warnings", default: {}, null: false
    t.json     "link_errors",   default: {}, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "link_id"
    t.index ["link_id"], name: "index_checks_on_link_id", using: :btree
  end

  create_table "links", force: :cascade do |t|
    t.string   "uri",        null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "uid"
    t.string   "organisation_slug"
    t.string   "organisation_content_id"
    t.string   "app_name"
    t.text     "permissions"
    t.boolean  "remotely_signed_out",     default: false
    t.boolean  "disabled",                default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "batches_checks", "batches"
  add_foreign_key "batches_checks", "checks"
  add_foreign_key "checks", "links"
end
