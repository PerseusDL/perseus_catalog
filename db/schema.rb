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

ActiveRecord::Schema.define(:version => 20130326150435) do

  create_table "authors", :force => true do |t|
    t.string   "mads_id"
    t.string   "alt_id"
    t.string   "name",              :null => false
    t.string   "alt_parts"
    t.string   "dates"
    t.string   "alt_names"
    t.string   "field_of_activity"
    t.text     "notes"
    t.text     "urls"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "bookmarks", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "user_type"
  end

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.string   "role",                           :default => "comments"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "editors_or_translators", :force => true do |t|
    t.string   "mads_id"
    t.string   "alt_id"
    t.string   "name",              :null => false
    t.string   "alt_parts"
    t.string   "dates"
    t.string   "alt_names"
    t.string   "field_of_activity"
    t.text     "notes"
    t.text     "urls"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "expressions", :force => true do |t|
    t.integer  "work_id",       :null => false
    t.string   "title"
    t.string   "alt_title"
    t.string   "abbr_title"
    t.string   "host_title"
    t.integer  "editor_id"
    t.integer  "translator_id"
    t.string   "language"
    t.string   "place_publ"
    t.string   "publisher"
    t.integer  "date_publ"
    t.integer  "date_mod"
    t.string   "edition"
    t.string   "phys_descr"
    t.text     "notes"
    t.string   "subjects"
    t.string   "cts_urn",       :null => false
    t.string   "clean_cts_urn", :null => false
    t.integer  "series_id"
    t.integer  "page_start"
    t.integer  "page_end"
    t.integer  "word_count"
    t.string   "urls"
    t.string   "host_urls"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "expressions", ["editor_id"], :name => "e_ed_idx"
  add_index "expressions", ["series_id"], :name => "e_series_idx"
  add_index "expressions", ["translator_id"], :name => "e_trans_idx"
  add_index "expressions", ["work_id"], :name => "e_work_idx"

  create_table "searches", :force => true do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "user_type"
  end

  add_index "searches", ["user_id"], :name => "index_searches_on_user_id"

  create_table "series", :force => true do |t|
    t.string   "ser_title"
    t.string   "abbr_title"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.string   "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "",    :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "guest",                  :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "works", :force => true do |t|
    t.string   "standard_id", :null => false
    t.string   "clean_id",    :null => false
    t.integer  "author_id"
    t.string   "title",       :null => false
    t.string   "language"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "works", ["author_id"], :name => "w_auth_idx"

  add_foreign_key "expressions", "editors_or_translators", :name => "e_ed", :column => "editor_id", :dependent => :delete
  add_foreign_key "expressions", "editors_or_translators", :name => "e_trans", :column => "translator_id", :dependent => :delete
  add_foreign_key "expressions", "series", :name => "e_series", :dependent => :delete
  add_foreign_key "expressions", "works", :name => "e_work", :dependent => :delete

  add_foreign_key "works", "authors", :name => "w_auth", :dependent => :delete

end
