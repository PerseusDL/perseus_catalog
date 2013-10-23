module ModsGeneratorHelper
  include ApplicationHelper

  def render_search_fields
    list = ["Textgroup ID", "Work ID", "Version Title", "Editor or Translator", "Publication Year"]
    render(:partial => "mods_search_field", :locals => {:field_list => list})
  end

end
