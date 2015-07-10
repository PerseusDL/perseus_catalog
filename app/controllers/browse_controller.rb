# -*- encoding : utf-8 -*-

class BrowseController < ApplicationController
  before_filter :set_cache_buster
  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  def index
    auth_list, @alphaParams = Author.order(:name).alpha_paginate(params[:letter], {db_mode: true, db_field: "name", default_field: "a", include_all: false, js: false})
    @auth_list = auth_list.page params[:page]
  end

end
