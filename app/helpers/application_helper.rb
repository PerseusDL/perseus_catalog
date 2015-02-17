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
      #also taking in to related works listed with the authors
      rel_works = object.related_works == nil ? [] : object.related_works.split(';')
      w_ids = works.collect {|w| w.standard_id[/\w+\.\w+$/]}
      rel_works.each do |rw|
        unless w_ids.include?(rw)
          ws = Work.find(:all, :conditions => ["standard_id rlike ?", rw])
          works << ws[0] unless ws.empty?
        end
      end
      return works, tgs
    end

  end

  def find_missing_works (author)  
    error_works = AtomError.find(:all, :conditions => {:author_id => author.id})
    return error_works
  end

#methods for the url_render partial
  def get_urls (type, id)
    if type =~ /expression/
      rows = ExpressionUrl.find(:all, :conditions => [ "host_work = 0 and exp_id = ?", id]) 
    elsif type == "author" 
      rows = AuthorUrl.find(:all, :conditions => [ "author_id = ?", id]) 
    elsif type =~ /host/ 
      rows = ExpressionUrl.find(:all, :conditions => [ "host_work = 1 and exp_id = ?", id]) 
    elsif type == "test"
      rows = ExpressionUrl.find(:all, :conditions => [ "exp_id = ?", id])
      unless rows.empty?
        weeded = []
        rows.each {|r| weeded << r unless r.display_label =~ /WorldCat|OCLC|LC|Open Library/i}
        return weeded
      end
    end 
    return rows
  end

#get an edition or translation for quick-find on works page
  def select_expression_url(arr)
    got_it = nil
    url = nil
    arr.each do |row|
      #favor perseus expressions
      if row.cts_urn =~ /perseus/
        urls = get_urls("expression", row.id)
        got_it = row
        unless urls.empty?
          urls.each do |ur|
            if ur.url =~ /perseus/
              url = ur
              break
            end
          end
          #if it hits here, there is no perseus url, which is weird
          url = urls[0] unless url
        end   
      end    
      #just go with the first expression that isn't a host work link if no perseus
      if got_it == nil 
        urls = get_urls("expression", row.id)
        unless urls.empty?
          urls.each do |ur|
            unless ur.url =~ /worldcat|oclc|lccn|openlibrary/i
              url = ur
              got_it = row 
              break
            end
          end
        end
      end
    end
    return got_it, url
  end 

#render urls for any type of record
  def render_url_list (rows, type)
    dt_tag = content_tag :dt, type_text_display(type)
    if type == "author"
      a = rows.collect do |r|
        unless r.url == "" or r.url == nil
          content_tag :dd, (link_to r.display_label, r.url) 
        end
      end
      b = a.join.html_safe
      return (dt_tag + b) unless b.empty?
    elsif type =~ /info/
      h_info = []
      rows.each do |r|
        unless r.url == "" or r.url == nil
          if r.display_label =~ /WorldCat|OCLC|LC|Open Library/i
            h_info << (content_tag :dd, (link_to r.display_label, r.url, :target => "_blank"))
          end
        end
      end
      info_tags = nil
      unless h_info.empty?
        info_tags = dt_tag + h_info.join.html_safe
      end
      return info_tags if info_tags
    else
      h_text = []
      rows.each do |r|
        unless r.url == "" or r.url == nil
          unless r.display_label =~ /WorldCat|OCLC|LC|Open Library/i
            h_text << (content_tag :dd, (link_to r.display_label, r.url, :target => "_blank"))
          end
        end
      end

      #getting the tags to display correctly is a little bit of a headache...
      combo_tags = nil
      unless h_text.empty?
        combo_tags = dt_tag + h_text.join.html_safe
      end
      return combo_tags if combo_tags
    end 
  end

#label text for url list
  def type_text_display (type)
    text = nil
    case type
      when "author"
        text = "Author info:"
      when "expression"
        text = "Find the text:"
      when "expression_info"
        text = "Other catalog records:"
      when "host"
        text = "Find the full book:"
      when "host_info"
        text = "Host catalog records:"
    end
    text
  end

#methods to help the browse list
  def render_author_list
    auth_arr = Author.all(:order => 'name')
    results = ""
    @top_auths = []
    auth_arr.each do |auth|
      auth_name = auth.name
      solr_id = auth.unique_id

      works_arr = Author.get_works(auth.id)
      words = 0
      unless works_arr.empty?
        #need to find the actual work, the array is just ids for works
        works_arr.each do |w| 
          w_row = Work.find(w)
          words = (words + w_row.word_count.to_i) if w_row.word_count
        end
        @top_auths << [auth_name, words]
      end
      unless works_arr.empty?      
        works_link = link_to "Search for Works", "/?f[auth_facet][]=#{auth_name}"
      end
      auth_link = link_to "View Authority Record", catalog_path(:id => solr_id)
      auth_record = content_tag(:li, auth_link)
      spacer = content_tag(:li, " ")
      works_search = content_tag(:li, works_link)
      list = content_tag(:ul, auth_record.html_safe + spacer + works_search.html_safe, :class => 'inline')
      unless words == 0
        auth_entry = content_tag(:dt, auth_name) + content_tag(:dd, "Words Represented: #{words.to_s}") + content_tag(:dd, list)
      else
        auth_entry = content_tag(:dt, auth_name) + content_tag(:dd, list)
      end
      results << auth_entry

    end
    content_tag(:dl, results.html_safe)
  end

  def author_word_counts
    @top_auths.sort!{|a1, a2| a2[1] <=> a1[1]} 
    top_ten = @top_auths.first(10)    
    return top_ten
  end

  def get_pages(exp)
    pgs = exp.pages
    pg = nil
    pg = pgs.split('-')[0] unless (pgs == "" || pgs == nil)
    return pg
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
      things << content_tag(:li, blog_link, :class => 'feed-list')
      
      things_list = content_tag(:ul, things.html_safe)
      
    end
    return feed_title.html_safe + things_list.html_safe
  end

end
