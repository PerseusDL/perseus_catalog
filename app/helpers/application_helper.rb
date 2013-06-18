module ApplicationHelper
  include BlacklightHelper

  require 'rss'
  require 'open-uri'

  def should_render_show_field? document, solr_field
    
    (document.has?(solr_field.field) && !(document.values_at(solr_field.field)[0].empty?))||
      (document.has_highlight_field? solr_field.field if solr_field.highlight)
  end

  def find_related (object)
    if object.attribute_present?("cts_urn")
      #expression, find work and author
      work = Work.find_by_id(object.work_id)
      taw_arr = TgAuthWork.find(:all, :conditions => {:work_id => object.work_id})
      auth = Author.find(taw_arr.collect {|a| a.auth_id})
      tg = Textgroup.find(taw_arr.collect {|d| d.tg_id})
      return work, auth, tg
    elsif object.attribute_present?("standard_id")
      #work, find author and expressions
      taw_arr = TgAuthWork.find(:all, :conditions => {:work_id => object.id})
      exps = Expression.find(:all, :conditions => {:work_id => object.id}, :order => 'cts_label')
      auth = Author.find(taw_arr.collect {|a| a.auth_id})
      tg = Textgroup.find(taw_arr.collect {|d| d.tg_id})
      non_cat = NonCatalogedExpression.find(:all, :conditions => {:work_id => object.id}, :order => 'cts_label')
      return exps, auth, tg, non_cat
    elsif object.attribute_present?("urn_end")
      #textgroup, find associated author(s) and works
      taw_arr = TgAuthWork.find(:all, :conditions => {:tg_id => object.id})
      auths = Author.find(taw_arr.collect {|a| a.auth_id})
      works = Work.find(taw_arr.collect {|w| w.work_id}, :order => "title")
      return auths, works
    else
      #author, find works and associated textgroup(s)
      taw_arr = TgAuthWork.find(:all, :conditions => {:auth_id => object.id})
      tgs = Textgroup.find(taw_arr.collect {|d| d.tg_id})
      works = Work.find(taw_arr.collect {|d| d.work_id}, :order => "title")
      return works, tgs
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
          h_text << (content_tag :dd, (link_to r.display_label, r.url, :target => "_blank"))
        else
          h_info << (content_tag :dd, (link_to r.display_label, r.url, :target => "_blank"))
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
    case type
      when "author"
        text = "Author info:"
      when "expression"
        text = "Find text here:"
      when "expression_info"
        text = "Other catalog records"
      when "host"
        text = "Host work text:"
      when "host_info"
        text = "Host catalog records:"
    end
    text
  end

#methods to help the browse list
  def render_author_list
    auth_arr = Author.all(:order => 'name')
    results = ""
    auth_arr.each do |auth|
      auth_name = auth.name
      solr_id = auth.unique_id
      unless auth_name == ""      
        works_link = link_to "Search for Works", "/?f[auth_facet][]=#{auth_name}"
      else
        auth_name = "[Unnamed]"
        works_link = link_to "Search for Works", "/?f[auth_facet][]="
      end
      auth_link = link_to "View Authority Record", catalog_path(:id => solr_id)
      auth_record = content_tag(:li, auth_link)
      spacer = content_tag(:li, " ")
      works_search = content_tag(:li, works_link)
      list = content_tag(:ul, auth_record.html_safe + spacer + works_search.html_safe, :class => 'inline')
      results << content_tag(:dt, auth_name) + content_tag(:dd, list)

    end
    content_tag(:dl, results.html_safe)
  end


  def render_rss_feed

    url = 'http://sites.tufts.edu/perseuscatalog/feed/'
    
    feed_title = ""
    things_list = ""
    open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed_title = content_tag(:h4, "#{feed.channel.title}")
      things = ""
      feed.items.each_with_index do |item, index|
        if index < 2
          title = item.title
          link = item.link
          title_link = link_to "<strong>#{title}</strong>".html_safe, link, :target => "_blank"
          
          description = item.description          
          des_array = description.split("</p>")
          link_out = content_tag(:p, (link_to "Read more...", link, :target => "_blank"))
          frst = des_array[0]+'</p>'
          content = 
          things << content_tag(:li, title_link + frst.html_safe + link_out.html_safe, :class => 'feed-list')
        else
          break
        end
      end
      blog_link = link_to "<strong>See more posts</strong>".html_safe, 'http://sites.tufts.edu/perseuscatalog/', :target => "_blank"
      things << content_tag (:li, blog_link, :class => 'feed-list')
      
      things_list = content_tag(:ul, things.html_safe)
      
    end
    return feed_title.html_safe + things_list.html_safe
  end

end
