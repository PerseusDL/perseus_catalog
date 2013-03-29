module ApplicationHelper
  include BlacklightHelper

  def should_render_show_field? document, solr_field
    
    (document.has?(solr_field.field) && !(document.values_at(solr_field.field)[0].empty?))||
      (document.has_highlight_field? solr_field.field if solr_field.highlight)
  end

  def find_related (object)
    if object.key?("cts_urn")
      #expression, find work and author
      work = Work.find_by_id(object["work_id"])
      auth = Author.find_by_id(work["author_id"])
      return work, auth
    elsif object.key?("standard_id")
      #work, find author and expressions
      exps = Expression.find(:all, :conditions => {:work_id => object["id"]})
      auth = Author.find_by_id(object["author_id"])
      return exps, auth
    else
      #author, find works
      works = Work.find(:all, :conditions => {:author_id => object["id"]})
      return works
    end

  end

  def find_missing_works (author)  
    error_works = AtomError.find(:all, :conditions => {:author_id => author["id"]})
    return error_works
  end
end
