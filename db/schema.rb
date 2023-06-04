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

ActiveRecord::Schema[7.0].define(version: 2023_05_13_105551) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "schedule", precision: nil
    t.string "status"
    t.bigint "clinic_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority_number"
    t.boolean "cancelled", default: false
    t.index ["clinic_id"], name: "index_appointments_on_clinic_id"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "clinic_queues", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "schedule", precision: nil
    t.integer "queue_type"
    t.bigint "clinic_id", null: false
    t.integer "status"
    t.boolean "skip_for_now", default: false
    t.index ["clinic_id"], name: "index_clinic_queues_on_clinic_id"
    t.index ["user_id"], name: "index_clinic_queues_on_user_id"
  end

  create_table "clinic_schedules", force: :cascade do |t|
    t.string "day"
    t.time "start_time"
    t.time "end_time"
    t.bigint "clinic_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "slots", default: 15
    t.index ["clinic_id"], name: "index_clinic_schedules_on_clinic_id"
  end

  create_table "clinic_special_cases", force: :cascade do |t|
    t.date "day"
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.string "reason"
    t.bigint "clinic_schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "slots"
    t.index ["clinic_schedule_id"], name: "index_clinic_special_cases_on_clinic_schedule_id"
  end

  create_table "clinics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "start_time"
    t.time "end_time"
    t.integer "appointment_duration"
    t.string "room_number"
    t.boolean "active"
    t.index ["end_time"], name: "index_clinics_on_end_time"
    t.index ["start_time"], name: "index_clinics_on_start_time"
    t.index ["user_id"], name: "index_clinics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: ""
    t.string "encrypted_password", default: "", null: false
    t.string "firstname", default: ""
    t.string "lastname", default: ""
    t.date "birthdate"
    t.string "gender"
    t.integer "role", default: 1
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mobile_number", null: false
    t.integer "doctor_clinic_notification_time_buffer", default: 10
    t.string "facebook_key"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "appointments", "clinics"
  add_foreign_key "appointments", "users"
  add_foreign_key "clinic_queues", "clinics"
  add_foreign_key "clinic_queues", "users"
  add_foreign_key "clinic_schedules", "clinics"
  add_foreign_key "clinic_special_cases", "clinic_schedules"
  add_foreign_key "clinics", "users"
end
