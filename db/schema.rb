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

ActiveRecord::Schema.define(:version => 20130513191533) do

  create_table "atom_errors", :force => true do |t|
    t.string   "standard_id", :null => false
    t.integer  "author_id"
    t.string   "title",       :null => false
    t.string   "language"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "atom_errors", ["author_id"], :name => "er_auth_idx"

  create_table "author_urls", :force => true do |t|
    t.integer  "author_id"
    t.text     "url"
    t.string   "display_label"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "author_urls", ["author_id"], :name => "url_auth_idx"

  create_table "authors", :force => true do |t|
    t.string   "unique_id",         :null => false
    t.string   "cite_urn"
    t.string   "phi_id"
    t.string   "tlg_id"
    t.string   "stoa_id"
    t.string   "alt_id"
    t.string   "name",              :null => false
    t.string   "alt_parts"
    t.string   "dates"
    t.text     "alt_names"
    t.string   "field_of_activity"
    t.text     "notes"
    t.string   "related_works"
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

  create_table "expression_urls", :force => true do |t|
    t.integer  "exp_id",        :null => false
    t.string   "url"
    t.string   "display_label"
    t.boolean  "host_work"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "expression_urls", ["exp_id"], :name => "eu_exp_idx"

  create_table "expressions", :force => true do |t|
    t.integer  "work_id",       :null => false
    t.integer  "tg_id",         :null => false
    t.string   "title"
    t.string   "alt_title"
    t.string   "abbr_title"
    t.string   "host_title"
    t.integer  "editor_id"
    t.integer  "translator_id"
    t.string   "language"
    t.string   "place_publ"
    t.string   "place_code"
    t.string   "publisher"
    t.integer  "date_publ"
    t.integer  "date_mod"
    t.string   "edition"
    t.string   "phys_descr"
    t.text     "notes"
    t.string   "subjects"
    t.string   "cts_urn",       :null => false
    t.string   "cts_label"
    t.string   "cts_descr"
    t.integer  "series_id"
    t.integer  "page_start"
    t.integer  "page_end"
    t.integer  "word_count"
    t.integer  "oclc_id"
    t.string   "var_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "expressions", ["editor_id"], :name => "e_ed_idx"
  add_index "expressions", ["series_id"], :name => "e_series_idx"
  add_index "expressions", ["translator_id"], :name => "e_trans_idx"
  add_index "expressions", ["work_id"], :name => "e_work_idx"

  create_table "non_cataloged_expressions", :force => true do |t|
    t.string   "cts_urn",    :null => false
    t.integer  "work_id",    :null => false
    t.string   "cts_label"
    t.string   "ed_trans"
    t.string   "var_type"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "non_cataloged_expressions", ["work_id"], :name => "nce_w_idx"

  create_table "non_cataloged_works", :force => true do |t|
    t.string   "urn",             :null => false
    t.integer  "textgroup_id",    :null => false
    t.string   "title"
    t.string   "ed_trans"
    t.boolean  "exp_edition"
    t.boolean  "exp_translation"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "non_cataloged_works", ["textgroup_id"], :name => "ncw_tg_idx"

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
    t.string   "clean_title", :null => false
    t.string   "abbr_title"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "textgroups", :force => true do |t|
    t.string   "urn",        :null => false
    t.string   "urn_end",    :null => false
    t.string   "group_name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "tg_auth_works", :force => true do |t|
    t.integer  "tg_id"
    t.integer  "auth_id"
    t.integer  "work_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "tg_auth_works", ["auth_id"], :name => "taw_aid_idx"
  add_index "tg_auth_works", ["tg_id"], :name => "taw_tg_idx"
  add_index "tg_auth_works", ["work_id"], :name => "taw_wid_idx"

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

  create_table "word_counts", :force => true do |t|
    t.integer  "auth_id",        :null => false
    t.integer  "total_words"
    t.integer  "words_done"
    t.integer  "tufts_google"
    t.integer  "harvard_mellon"
    t.integer  "to_do"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "word_counts", ["auth_id"], :name => "wc_auth_idx"

  create_table "works", :force => true do |t|
    t.string   "standard_id",  :null => false
    t.integer  "textgroup_id"
    t.string   "title",        :null => false
    t.string   "language"
    t.integer  "word_count"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "works", ["textgroup_id"], :name => "w_tg_idx"

  add_foreign_key "atom_errors", "authors", :name => "er_auth", :dependent => :delete

  add_foreign_key "author_urls", "authors", :name => "url_auth", :dependent => :delete

  add_foreign_key "expression_urls", "expressions", :name => "eu_exp", :column => "exp_id", :dependent => :delete

  add_foreign_key "expressions", "editors_or_translators", :name => "e_ed", :column => "editor_id", :dependent => :delete
  add_foreign_key "expressions", "editors_or_translators", :name => "e_trans", :column => "translator_id", :dependent => :delete
  add_foreign_key "expressions", "series", :name => "e_series", :dependent => :delete
  add_foreign_key "expressions", "works", :name => "e_work", :dependent => :delete

  add_foreign_key "non_cataloged_expressions", "works", :name => "nce_tg", :dependent => :delete

  add_foreign_key "non_cataloged_works", "textgroups", :name => "ncw_tg", :dependent => :delete

  add_foreign_key "tg_auth_works", "authors", :name => "taw_aid", :column => "auth_id", :dependent => :delete
  add_foreign_key "tg_auth_works", "textgroups", :name => "taw_tg", :column => "tg_id", :dependent => :delete
  add_foreign_key "tg_auth_works", "works", :name => "taw_wid", :dependent => :delete

  add_foreign_key "word_counts", "authors", :name => "wc_auth", :column => "auth_id", :dependent => :delete

  add_foreign_key "works", "textgroups", :name => "w_tg", :dependent => :delete

end
