#Copyright 2014 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================


class NewParser
  require 'mysql2'
  require 'nokogiri'
  require 'author.rb'
  require 'editors_or_translator.rb'
  require 'work.rb'
  require 'atom_error.rb'
  require 'author_url.rb'
  require 'textgroup.rb'
  require 'expression_url.rb'
  require 'series.rb'
  require 'xml_importer.rb'
  include CiteColls

  def atom_parse(doc)
    begin
      set_agent
      @error_report = File.open("#{BASE_DIR}/catalog_errors/error_log#{Date.today}.txt", 'w')
      #grab namespaces not defined on the root of the xml doc
      ns = doc.collect_namespaces
      atom_id = doc.xpath("atom:feed/atom:id", ns).inner_text
      #creates instance variables for cts ids
      
      get_cts_ids(atom_id)
      cite_work_arr = get_cite_rows('works', 'work', @work_cts)
      cite_tg_arr = get_cite_rows('textgroups', 'textgroup', @tg_cts)
      cite_auth_arr = get_cite_rows('authors', 'canonical_id', @auth_cts)

      #there should only be one work, but this gets it out of the array, 
      #work is a json object, less hassle than parsing XML
      cite_work_arr.each do |w|
        tg = textgroup_row(cite_tg_arr)
        #auth will be an array since there is the possibility of multiple authors
        auth = author_row(cite_auth_arr, cite_tg_arr[0], doc, ns)
        work = work_row(w, tg, doc, ns)
        #link it all in tg_auth_work table
        version_rows(tg, auth, work, doc, ns)
      end
    rescue Exception => e
      puts "Something went wrong for the work parse! #{$!}"
      puts e.backtrace
    end
  end


  def get_cts_ids(atom_id)
    @lit_type = atom_id[/\w+Lit/]
    @work_cts = atom_id[/urn(:|\w|\.|-)+/]
    @tg_cts = @work_cts[/urn.+\./].chop
    @auth_cts = @tg_cts[/:\w+$/].delete(':')
  end


  def textgroup_row(cite_tg_arr)
    tg = nil
    cite_tg_arr.each do |cite_tg|
      if cite_tg['textgroup'] =~ /urn:cts/
        tg = Textgroup.get_info(cite_tg['textgroup'])
        unless tg
          tg = Textgroup.new
          tg.urn = @tg_cts
          tg.urn_end = @auth_cts
          tg.group_name = cite_tg['groupname_eng']
          tg.save
        else
          unless tg.group_name == cite_tg['groupname_eng']
            tg.group_name = cite_tg['groupname_eng']
            tg.save
          end
        end
      else
        message = "A CITE Textgroup has a non-conforming urn, #{cite_tg['textgroup']}"
        error_handler(message)
      end
    end
    return tg
  end
  

  def author_row(cite_auth_arr, cite_tg_row, doc, ns)
    #since there are textgroups without mads and the cite authors are a record of our mads
    #we will lack cite authors where we have authors in the catalog, therefore
    #cite_auth_arr might be empty, but want to still update/add these authors so as to provide the ability to search for them
    #but they must have at least a textgroup, otherwise there is no way for them to have any sort of unique id
    auth_arr = []
    final_auth_arr = []
    unless cite_tg_row['has_mads'] == "false"
      cite_auth_arr.each do |a|
        auth_arr = Author.find_by_major_ids(a['canonical_id'])
        
        if auth_arr.empty?
          auth = Author.new_auth(a)
        else
          if auth_arr.length == 1
            auth = auth_arr[0]  
            auth.unique_id = a['urn'] unless auth.unique_id == a['urn']
            auth.name = a['authority_name'] unless auth.name == a['authority_name']
            auth.alt_id = a['alt_ids']
          else
            names = []
            auth_arr.each {|au| names << au.name}
            message = "There is more than one author for urn #{@auth_cts}, need to investigate #{names.join(',')}"
            error_handler(message)
          end
        end
        auth.related_works = a['related_works']
    
        #have to go to the MADS files now
        #need to narrow down section of XML used, in case there is more than one author
        auth_ids = doc.xpath(".//mads:identifier[@type='citeurn']", ns)
        mads_xml = nil
        auth_ids.each do |node| 
          if node.inner_text == a['urn']
            mads_xml = node.parent
          end
        end

        alt_parts = mads_xml.xpath("//mads:authority//mads:namePart[@type='termsOfAddress']", ns)
        dates = doc.xpath(".//mads:authority//mads:namePart[@type='date']", ns)
        auth.alt_parts = alt_parts.inner_text if alt_parts
        auth.dates = dates.inner_text if dates
      
        abbrs = turn_to_list(doc, ".//mads:variant[@type='abbreviation']", ";", ns, ", ")  
        other_names = turn_to_list(doc, ".//mads:related", ";", ns, ", ", "mads:name/mads:namePart[not(@type='date')]")
        if other_names.empty?  
          other_names = turn_to_list(doc, ".//mads:variant", ";", ns, ", ", "mads:name/mads:namePart[not(@type='date')]")
        else
          other_names << ";" + turn_to_list(doc, ".//mads:variant", ";", ns, ", ", "mads:name/mads:namePart[not(@type='date')]")
        end
        auth.alt_names = other_names
        auth.abbr = abbrs
        
        fields = turn_to_list(doc, ".//mads:fieldOfActivity", ";", ns)
        auth.field_of_activity = fields unless fields.empty?

        notes = turn_to_list(doc, ".//mads:note", ";", ns)
        auth.notes = notes unless notes.empty?
        
        auth_urls(auth, doc, ns)
        
        auth.save
        final_auth_arr << auth
      end
    else
      #need to create/find stub authors for textgroups that don't have mads files
      auth_arr = Author.find_by_major_ids(@auth_cts)
      if auth_arr.empty?
        auth = Author.new_auth(cite_tg_row, true)
      else
        if auth_arr.length == 1
          auth_arr[0].unique_id = cite_tg_row['urn'] unless auth_arr[0].unique_id == cite_tg_row['urn']
          auth_arr[0].name = cite_tg_row['groupname_eng'] unless auth_arr[0].name == cite_tg_row['groupname_eng']
          auth_arr[0].save
          final_auth_arr << auth_arr[0]
        else
          names = []
          auth_arr.each {|au| names << au.name}
          message = "There is more than one author for urn #{@auth_cts}, need to investigate #{names.join(',')}"
          error_handler(message)
        end
      end
    end
    return final_auth_arr
  end
  
  
  def auth_urls(auth, doc, ns)
    url_nodes = doc.xpath(".//mads:url", ns)
    if url_nodes
      url_nodes.each do |node|
        text = node.inner_text
        unless text.empty?
          AuthorUrl.author_url_row(text, auth, node)
        end
      end
    end
  end


  def work_row(w, tg, doc, ns)
    wrk = Work.get_info(@work_cts)
    unless wrk
      wrk = Work.new
    end
    wrk.standard_id = @work_cts unless wrk.standard_id == @work_cts
    wrk.textgroup_id = tg.id unless wrk.textgroup_id == tg.id
    wrk.title = w['title_eng'] unless wrk.title == w['title_eng']
    wrk.language = w['orig_lang'] unless wrk.language == w['orig_lang']
    count_node = doc.xpath(".//mods:extent[@unit='words']", ns)
    wrk.word_count = count_node.inner_text.strip if count_node
    wrk.save
    return wrk
  end
  

  def version_rows(tg, auth, work, doc, ns)
    #reminder, auth is an array while the others are ActiveRecord objects
    #versions is expressions in the blacklight db

    #going by what is in the atom feed since it is easier to look for versions
    #in the cite table than select the correct mods from the xml
    mods_nodes = doc.xpath(".//mods:mods", ns)
    unless mods_nodes.empty?
      mods_nodes.each do |mods|
        mods_cts_node = mods.xpath("mods:identifier[@type='ctsurn']", ns)
        if mods_cts_node
          mods_cts = mods_cts_node.inner_text
        else
          atom_ent = mods.parent.parent
          at_id = atom_ent.xpath(".//atom:id", ns)
          message = "No CTS urn in record #{at_id}, please check"
          error_handler(message)
          next
        end

        cite_vers = get_cite_rows("versions", "version", mods_cts)
        unless cite_vers.empty?
          #should only be one of these
          cite_vers.each do |vers|
            begin
              vers_cts = vers['version']
              exp = Expression.find_by_cts_urn(vers_cts)
              unless exp
                exp = Expression.new
              end
              exp.cts_urn = vers_cts
              exp.work_id = work.id
              exp.tg_id = tg.id
              exp.title = work.title
             
              #find alt and abbr titles
              alt_title_nodes = mods.xpath("mods:titleInfo[not(@type='uniform')]", ns)
              unless alt_title_nodes.empty?
                alt_titles = []
                alt_title_nodes.each do |alt_node|
                  t_type = alt_node.attribute('type')
                  if t_type
                    if t_type.value == "abbreviated"
                      abr_title = alt_node.inner_text.strip
                      exp.abbr_title << ((exp.abbr_title == nil || exp.abbr_title.empty?) ? abr_title : ";#{abr_title}")
                    else
                      alt_t = alt_node.inner_text.strip
                      exp.alt_title << ((exp.alt_title == nil || exp.alt_title.empty?) ? alt_t : ";#{alt_t}")
                    end
                  end
                end
              end
              #add the abbreviated title(s) to the work table
              #this might need to be an update method
              work.abbr_title = exp.abbr_title if work.abbr_title != exp.abbr_title
              work.save

              #find editors and translators
              mods.xpath(".//mods:name", ns).each do |names|
                 
                name_node = names.xpath("mods:namePart[not(@type='date')]", ns)
                raw_name = name_node.inner_text if name_node
                role_node = names.xpath(".//mods:roleTerm", ns)
                role_term = role_node.inner_text if role_node
                if role_term =~ /editor|compiler|translator/i
                  person = EditorsOrTranslator.find_by_name_or_alt_name(raw_name)
                  #check for this ed/trans in the cite tables
                  cite_auth_ed = get_cite_rows('authors', 'authority_name', raw_name)
                  cite_tg_ed  = get_cite_rows('textgroups', 'groupname_eng', raw_name)
                  if cite_auth_ed.empty? && cite_tg_ed.empty?
                    message = "There is no cite or cts id associated with this editor/translator, please add a mads record"
                    error_handler(message)
                  end
                  cite_auth_urn = cite_auth_ed.empty? ? nil : cite_auth_ed[0]['urn']
                  cite_tg_urn = cite_tg_ed.empty? ? nil : cite_tg_ed[0]['urn']
                  #if we have either an author or tg cite urn for an ed/trans, then we should add them to the catalog authors
                  if cite_auth_urn || cite_tg_urn
                    author_row(cite_auth_ed, cite_tg_ed, doc, ns)
                  end
                  unless person
                    person = EditorsOrTranslator.new
                    person.mads_id = cite_tg_urn if cite_tg_urn
                    person.alt_id = cite_auth_urn if cite_auth_urn
                    person.name = raw_name
                    dates_node = names.xpath("mods:namePart[@type='date']", ns)
                    person.dates = dates_node.inner_text if dates_node
                    person.save
                  end

                  exp.editor_id = person.id if role_term =~ /editor|compiler/i
                  exp.translator_id = person.id if role_term =~ /translator/i
                end
              end
              #record the language that the version is in
              exp.language = vers_cts[/\w+\d+$/][/\w+/]
              #translation or edition?
              exp.var_type = vers['ver_type']
              #get page ranges and word counts
              mods.xpath("mods:part/mods:extent", ns).each do |ex_tag|
                attrib = ex_tag.attribute('unit')
                unit_attr = attrib.value if attrib
                if unit_attr == "pages"
                  if ex_tag.children.length > 1
                    exp.pages = turn_to_list(ex_tag, "mods:start", "-", ns)
                  else
                    exp.pages = ex_tag.child.inner_text.strip
                  end
                elsif unit_attr == "words"
                  exp.word_count = ex_tag.xpath("mods:total", ns).inner_text
                end
              end             
              #get all host work information
              #some won't have more than one tag, but turn_to_list can work with single cases
              host_urls = []
              mods.xpath("mods:relatedItem[@type='host']", ns).each do |host|
                exp.host_title = turn_to_list(host, "mods:titleInfo", ";", ns, ", ")
                exp.place_publ = turn_to_list(host, "mods:place/mods:placeTerm[not(@type='code')]", ";", ns) 
                exp.place_code = turn_to_list(host, "mods:place/mods:placeTerm[@type='code']", ";", ns) 
                exp.publisher = turn_to_list(host, "mods:publisher", ";", ns)
                exp.date_publ = turn_to_list(host, "mods:dateIssued", ";", ns) 
                exp.date_mod = turn_to_list(host, "mods:dateModified", ";", ns)
                exp.edition = turn_to_list(host, "mods:edition", ";", ns)
                exp.phys_descr = turn_to_list(host, "mods:physicalDescription", ";", ns, ", ")
                exp.notes = turn_to_list(host, "mods:notes", ";", ns) 
                exp.subjects = turn_to_list(host, "mods:subject", ";", ns, "--")
                host_urls = url_get(host, "mods:url", ns)
                exp.oclc_id = turn_to_list(host, "mods:identifier[@type='oclc']", ";", ns)
              end
              #cts_label, cts_descr
              exp.cts_label = vers['label_eng']
              exp.cts_descr = vers['desc_eng']
              #series_id 
              ser = Series.series_row(mods, ns)
              exp.series_id = ser.id if (ser && !exp.series_id)
              
              exp.save

              #expression urls
              ex_u = url_get(mods, "mods:url", ns)
              ExpressionUrl.expr_urls(exp.id, ex_u)
              ExpressionUrl.expr_urls(exp.id, host_urls, true)

            rescue Exception => e
              message = "Something went wrong in the version row creation! #{$!}\n#{e.backtrace}"
              error_handler(message)
            end
          end
        else
          message = "There are no cite versions for #{@work_cts}, need to investigate"
          error_handler(message)
        end
      end
    end
  end

  def url_get(doc, path, ns)
    urls = []
    doc.xpath(path, ns).each do |url_node|
      dl = url.attribute("displayLabel")
      display = dl ? dl.value : nil
      url = url_node.inner_text.strip
      unless url.empty?
        unless display == nil || display.empty?
          u = [display, url]
        else
          u = [url, url]
        end
        urls << u
      else
        next
      end
    end
    return urls
  end
=begin
  def series(mods, ns)
    #get series info
    mods.xpath("mods:relatedItem[@type='series']", ns).each do |series_node|
      ser_title = nil
      ser_abb = nil
      series_node.xpath("mods:titleInfo", ns).each do |tf|
        raw_ser = tf.inner_text.strip.gsub(/\s*\n\s*/,', ')
        if (tf.attribute('type') && tf.attribute('type').value == "abbreviated")
          ser_abb = raw_ser 
        else
          ser_title = raw_ser
        end
      end
      ser = Series.series_row(ser_title, ser_abb)
    end
  end
=end

  def error_handler(message)
    puts message
    @error_report << "#{message}\n\n"
    @error_report.close
    @error_report = File.open("#{BASE_DIR}/catalog_errors/error_log#{Date.today}.txt", 'a')
  end

  #multi variable is for specifying a separator when you are making a list out of a set of nodes that have children
  #and exc is for defining a further xpath if needed, like for removing the date nodes from alt names
  def turn_to_list(doc, path, join_type, ns, multi=nil, exc=nil)
    node_set = doc.xpath(path, ns)
    node_list = []
    unless node_set.empty?
      node_set.each do |node|
        if multi
          if exc
            sub_nodes = node.xpath(exc, ns)
            name = ""
            sub_nodes.each {|n| name << (name.empty? ? n.inner_text : ", #{n.inner_text}")}
            node_list << name
          else
            node_list << node.inner_text.gsub(/\s*\n\s*/, multi).gsub(/,,/, ",")
          end
        else
          node_list << node.inner_text.strip
        end
      end
      node_string = node_list.join(join_type)
    else
      node_string = ""
    end
    return node_string
  else
    return nil
  end

end