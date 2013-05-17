module ApplicationHelper
  include BlacklightHelper

  def should_render_show_field? document, solr_field
    
    (document.has?(solr_field.field) && !(document.values_at(solr_field.field)[0].empty?))||
      (document.has_highlight_field? solr_field.field if solr_field.highlight)
  end

  def find_related (object)
    #REWORK THIS TO USE THE TG_AUTH_WORKS TABLE
    if object.key?("cts_urn")
      #expression, find work and author
      work = Work.find_by_id(object["work_id"])
      tg = Textgroup.find_by_id(work["textgroup_id"])
      return work, tg
    elsif object.key?("standard_id")
      #work, find author and expressions
      exps = Expression.find(:all, :conditions => {:work_id => object["id"]})
      tg = Textgroup.find_by_id(object["textgroup_id"])
      return exps, tg
    else
      #author, find works
      phi = object["phi_id"]
      tlg = object["tlg_id"]
      stoa = object ["stoa_id"]
      tg_arr = Textgroup.find(:all, :conditions => {:urn_end => [phi, tlg, stoa]})
      ids = []
      tg_arr.each {|row| ids << row["id"]}
      works = Work.find(:all, :conditions => {:textgroup_id => ids})
      return works
    end

  end

  def find_missing_works (author)  
    error_works = AtomError.find(:all, :conditions => {:author_id => author["id"]})
    return error_works
  end
end
