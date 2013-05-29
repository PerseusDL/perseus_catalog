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
      exps = Expression.find(:all, :conditions => {:work_id => object.id}, :order => 'cts_label, date_publ')
      auth = Author.find(:first, :conditions => ["id = (SELECT auth_id from tg_auth_works where work_id = ?)", object.id])
      non_cat = NonCatalogedExpression.find(:all, :conditions => {:work_id => object.id}, :order => 'cts_label')
      return exps, auth, non_cat
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
  def get_urls (type, id)
    if type == "expression" 
      rows = ExpressionUrl.find(:all, :conditions => [ "host_work = 0 and exp_id = ?", id]) 
    elsif type == "author" 
      rows = AuthorUrl.find(:all, :conditions => [ "author_id = ?", id]) 
    elsif type == "host" 
      rows = ExpressionUrl.find(:all, :conditions => [ "host_work = 1 and exp_id = ?", id]) 
    end 
    return rows
  end

#render urls for any type of record
  def render_url_list (rows, type)
    dt_tag = content_tag :dt, type_text_display(type)
    if type == "author"
      a = rows.collect do |r| 
        content_tag :dd, (link_to r.display_label, r.url) 
      end
      b = a.join.html_safe
      return (dt_tag + b) unless b.empty?
    else
      h_text = []
      h_info = []
      rows.each do |r|
        unless r.display_label =~ /WorldCat|LC/i
          h_text << (content_tag :dd, (link_to r.display_label, r.url))
        else
          h_info << (content_tag :dd, (link_to r.display_label, r.url))
        end
      end

      #getting the tags to display correctly is a little bit of a headache...
      combo_tags = nil
      unless h_text.empty?
        combo_tags = dt_tag + h_text.join.html_safe
      end
      info_tags = nil
      unless h_info.empty?
        info_tags = content_tag(:dt, type_text_display("#{type}_info")) + h_info.join.html_safe
      end
       
      if combo_tags and info_tags
        return combo_tags + info_tags
      else
        return (combo_tags ? combo_tags : info_tags)
      end
    end 
  end

#label text for url list
  def type_text_display (type)
    text = nil
    case 
      when type == "author"
        text = "Author info:"
      when type == "expression"
        text = "Find text here:"
      when type == "expression_info"
        text = "Other catalog records"
      when type == "host"
        text = "Host work text:"
      when type == "host_info"
        text = "Host catalog records:"
    end
    text
  end

end
