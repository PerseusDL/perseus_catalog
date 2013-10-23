class ModsGeneratorController < ActionController::Base
  http_basic_authenticate_with :name => "perseus", :password => "modsCreate2013"

  def index
  end

  def layout_name
    "mods_generator"
  end

end
