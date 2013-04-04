# -*- encoding : utf-8 -*-
require 'blacklight/catalog'


class VisController < ApplicationController

  include Blacklight::Catalog
  require 'catalog_controller.rb'

end