module ApplicationHelper
  include BlacklightHelper

  def should_render_show_field? document, solr_field
    
    (document.has?(solr_field.field) && !(document.values_at(solr_field.field)[0].empty?))||
      (document.has_highlight_field? solr_field.field if solr_field.highlight)
  end

  def find_related (object)
    #REWORK THIS TO USE THE TG_AUTH_WORKS TABLE
    if object.attribute_present?("cts_urn")
      #expression, find work and author
      work = Work.find_by_id(object.work_id)
      tg = Textgroup.find_by_id(work.textgroup_id)
      return work, tg
    elsif object.attribute_present?("standard_id")
      #work, find author and expressions
      exps = Expression.find(:all, :conditions => {:work_id => object.id}, :order => 'title, date_publ')
      auth = Author.find(:first, :conditions => ["id = (SELECT auth_id from tg_auth_works where work_id = ?)", object.id])
      return exps, auth
    else
      #author, find works
      phi = object.phi_id
      tlg = object.tlg_id
      stoa = object.stoa_id
      tg_arr = Textgroup.find(:all, :conditions => {:urn_end => [phi, tlg, stoa]})
      ids = []
      tg_arr.each {|row| ids << row.id}
      works = Work.find(:all, :conditions => {:textgroup_id => ids}, :order => 'title')
      return works
    end

  end

  def find_missing_works (author)  
    error_works = AtomError.find(:all, :conditions => {:author_id => author.id})
    return error_works
  end

#methods for the url_render partial
  def get_urls (type)
    if type == "expression" 
      rows = ExpressionUrl.find(:all, :conditions => [ "host_work = 0 and exp_id = ?", id]) 
    elsif type == "author" 
      rows = AuthorUrl.find(:all, :conditions => [ "author_id = ?", id]) 
    elsif type == "host" 
      rows = ExpressionUrl.find(:all, :conditions => [ "host_work = 1 and exp_id = ?", id]) 
    end 
    return rows
  end

  def render_url_list (rows, type)
  end
=begin    content_tag(:dt, url_list_intro(type)) + content_tag(:dd, )

     if 
  <dt>"Find the text here:"</dt>
   rows.each do |row| 
     url = row["url"] 
     label = row["display_label"] 
     if url 
       unless url == " " or url =="" 
         if type == "expression" 

        <dd> link_to label, url, :target => "_blank" </dd>
       end 
     end 
   end 

  def url_list_intro (type)

  end
=end
end
