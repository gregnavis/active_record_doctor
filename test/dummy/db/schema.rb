# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160604081452) do

  create_table "comments", force: :cascade do |t|
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "comments", ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"

  create_table "employers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "employers", ["id"], name: "index_employers_on_id"

  create_table "profiles", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "profile_id"
    t.integer  "employer_id"
    t.string   "country_code", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "users", ["email"], name: "index_users_on_email"
  add_index "users", ["email"], name: "unique_index_on_users_email", unique: true
  add_index "users", ["employer_id", "country_code"], name: "index_users_on_employer_id_and_country_code"
  add_index "users", ["last_name", "first_name", "email"], name: "index_users_on_last_name_and_first_name_and_email"
  add_index "users", ["last_name", "first_name"], name: "index_users_on_last_name_and_first_name"
  add_index "users", ["last_name", "first_name"], name: "unique_index_on_users_last_name_and_first_name", unique: true
  add_index "users", ["last_name"], name: "index_users_on_last_name"

end
