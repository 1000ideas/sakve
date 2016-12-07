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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160420080858) do

  create_table "attachments", :force => true do |t|
    t.string   "upload_file_name"
    t.string   "upload_content_type"
    t.integer  "upload_file_size"
    t.datetime "upload_updated_at"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "folders", :force => true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "user_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.boolean  "global",           :default => false, :null => false
    t.integer  "transfer_id"
    t.boolean  "processing",       :default => false
    t.integer  "subfolders_count", :default => 0
  end

  add_index "folders", ["transfer_id"], :name => "index_folders_on_transfer_id"

  create_table "group_translations", :force => true do |t|
    t.integer  "group_id",    :null => false
    t.string   "locale",      :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "title"
    t.string   "description"
  end

  add_index "group_translations", ["group_id"], :name => "index_group_translations_on_group_id"
  add_index "group_translations", ["locale"], :name => "index_group_translations_on_locale"

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "members_count", :default => 0, :null => false
  end

  create_table "item_tags", :force => true do |t|
    t.integer  "item_id",    :null => false
    t.integer  "tag_id",     :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "item_tags", ["item_id", "tag_id"], :name => "index_item_tags_on_item_id_and_tag_id", :unique => true

  create_table "items", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.string   "object_file_name"
    t.string   "object_content_type"
    t.integer  "object_file_size"
    t.datetime "object_updated_at"
    t.integer  "user_id"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
    t.integer  "folder_id"
    t.string   "convert_status",      :default => "unprocessed"
  end

  create_table "selection_downloads", :id => false, :force => true do |t|
    t.string   "id",         :limit => 32
    t.integer  "user_id"
    t.text     "ids"
    t.text     "fids"
    t.boolean  "done",                     :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "selection_downloads", ["id"], :name => "index_selection_downloads_on_id"

  create_table "shares", :force => true do |t|
    t.integer  "collaborator_id"
    t.string   "collaborator_type"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "shares", ["collaborator_id", "collaborator_type", "resource_id", "resource_type"], :name => "unique_shares", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name",                       :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "items_count", :default => 0, :null => false
  end

  create_table "transfer_files", :force => true do |t|
    t.string   "token",               :limit => 16
    t.integer  "user_id"
    t.string   "object_file_name"
    t.string   "object_content_type"
    t.integer  "object_file_size",    :limit => 8
    t.datetime "object_updated_at"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.string   "upload_status",                     :default => "new", :null => false
  end

  create_table "transfer_stats", :force => true do |t|
    t.integer  "transfer_id"
    t.string   "client_ip",   :limit => 15
    t.text     "browser"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "transfer_stats", ["transfer_id"], :name => "index_transfer_stats_on_transfer_id"

  create_table "transfers", :force => true do |t|
    t.string   "name"
    t.string   "recipients"
    t.integer  "user_id"
    t.string   "token",               :limit => 64
    t.string   "object_file_name"
    t.string   "object_content_type"
    t.integer  "object_file_size",    :limit => 8
    t.datetime "object_updated_at"
    t.datetime "expires_at"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.boolean  "done",                              :default => false
    t.string   "group_token",         :limit => 16
    t.integer  "statistics_count",                  :default => 0
    t.integer  "folders_count",                     :default => 0
    t.boolean  "expired",                           :default => false
    t.text     "infos_hash"
    t.string   "message"
    t.boolean  "extracted",                         :default => false
  end

  create_table "user_groups", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                :default => "", :null => false
    t.string   "encrypted_password",                   :default => "", :null => false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "reset_password_sent_at"
    t.string   "reset_password_token"
    t.datetime "banned_at"
    t.datetime "activated_at"
    t.string   "auth_token",             :limit => 32
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
