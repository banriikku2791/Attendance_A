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

ActiveRecord::Schema.define(version: 20200207144057) do

  create_table "attendance_changes", force: :cascade do |t|
    t.date "worked_on"
    t.string "note"
    t.datetime "after_started_at"
    t.datetime "after_finished_at"
    t.datetime "before_started_at"
    t.datetime "before_finished_at"
    t.integer "superior_employee_number"
    t.string "request"
    t.datetime "request_at"
    t.datetime "confirm_at"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attendance_id"
    t.datetime "deleted_at"
    t.boolean "deleted_flg", default: false
    t.string "before_note"
    t.string "before_ck_tomorrow_kintai"
    t.index ["attendance_id"], name: "index_attendance_changes_on_attendance_id"
    t.index ["user_id"], name: "index_attendance_changes_on_user_id"
  end

  create_table "attendance_ends", force: :cascade do |t|
    t.date "worked_on"
    t.string "end_at"
    t.string "reason"
    t.integer "superior_employee_number"
    t.string "request"
    t.datetime "request_at"
    t.datetime "confirm_at"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "tomorrow_flg", default: false
    t.integer "attendance_id"
    t.string "before_end_at"
    t.boolean "tomorrow_flg_before", default: false
    t.string "before_reason"
    t.index ["attendance_id"], name: "index_attendance_ends_on_attendance_id"
    t.index ["user_id"], name: "index_attendance_ends_on_user_id"
  end

  create_table "attendance_fixes", force: :cascade do |t|
    t.date "worked_on"
    t.integer "superior_employee_number"
    t.string "request"
    t.datetime "request_at"
    t.datetime "confirm_at"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_attendance_fixes_on_user_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "end_at"
    t.string "reason"
    t.string "request_end"
    t.string "request_change"
    t.string "ck_tomorrow", default: "0"
    t.string "ck_tomorrow_kintai", default: "0"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "bases", force: :cascade do |t|
    t.integer "base_number"
    t.string "base_name"
    t.string "work_bunrui"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gameninfos", force: :cascade do |t|
    t.integer "keyid"
    t.date "worked_on"
    t.string "started_at"
    t.string "finished_at"
    t.string "ck_tomorrow_kintai"
    t.string "note"
    t.string "employee_number"
    t.string "normal_msg"
    t.string "error_msg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "affiliation"
    t.datetime "basic_time", default: "2020-02-10 23:00:00"
    t.datetime "work_time", default: "2020-02-10 22:30:00"
    t.boolean "superior", default: false
    t.string "designated_work_start_time", default: "0800"
    t.string "designated_work_end_time", default: "1700"
    t.string "basic_work_time", default: "0800"
    t.integer "employee_number"
    t.string "uid"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
