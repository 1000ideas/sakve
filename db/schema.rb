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

ActiveRecord::Schema.define(:version => 20130326125314) do

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
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "global",     :default => false, :null => false
  end

  create_table "group_translations", :force => true do |t|
    t.integer  "group_id"
    t.string   "locale"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
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
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "folder_id"
  end

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
    t.integer  "object_file_size"
    t.datetime "object_updated_at"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  create_table "transfers", :force => true do |t|
    t.string   "name"
    t.string   "recipients"
    t.integer  "user_id"
    t.string   "token",               :limit => 64
    t.string   "object_file_name"
    t.string   "object_content_type"
    t.integer  "object_file_size"
    t.datetime "object_updated_at"
    t.datetime "expires_at"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  create_table "user_groups", :force => true do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",               :default => "", :null => false
    t.string   "encrypted_password",  :default => "", :null => false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
