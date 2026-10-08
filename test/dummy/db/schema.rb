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

ActiveRecord::Schema[8.1].define(version: 2026_10_09_000004) do
  create_table "hub_kernel_mcp_authorization_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.integer "client_id", null: false
    t.string "person_gid", null: false
    t.string "redirect_uri", null: false
    t.string "code_challenge", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_hub_kernel_mcp_authorization_codes_on_client_id"
    t.index ["code_digest"], name: "index_hub_kernel_mcp_authorization_codes_on_code_digest", unique: true
  end

  create_table "hub_kernel_mcp_clients", force: :cascade do |t|
    t.string "uid", null: false
    t.string "name"
    t.json "redirect_uris", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "registered_from"
    t.index ["registered_from", "created_at"], name: "index_hub_kernel_mcp_clients_on_registered_from_and_created_at"
    t.index ["uid"], name: "index_hub_kernel_mcp_clients_on_uid", unique: true
  end

  create_table "hub_kernel_mcp_connections", force: :cascade do |t|
    t.string "token_digest", null: false
    t.integer "client_id", null: false
    t.string "person_gid", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "refresh_token_digest"
    t.datetime "refresh_expires_at"
    t.datetime "last_used_at"
    t.string "code_digest"
    t.index ["client_id"], name: "index_hub_kernel_mcp_connections_on_client_id"
    t.index ["code_digest"], name: "index_hub_kernel_mcp_connections_on_code_digest"
    t.index ["refresh_token_digest"], name: "index_hub_kernel_mcp_connections_on_refresh_token_digest", unique: true
    t.index ["token_digest"], name: "index_hub_kernel_mcp_connections_on_token_digest", unique: true
  end

  add_foreign_key "hub_kernel_mcp_authorization_codes", "hub_kernel_mcp_clients", column: "client_id"
  add_foreign_key "hub_kernel_mcp_connections", "hub_kernel_mcp_clients", column: "client_id"
end
