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

  MODS_NS = {"mods" => "http://www.loc.gov/mods/v3"}
  TI_NS = 'http://chs.harvard.edu/xmlns/cts'
  ATOM_NS = 'http://www.w3.org/2005/Atom'
  MODS_NS = 'http://www.loc.gov/mods/v3'
  MADS_NS = 'http://www.loc.gov/mads/v2'

  def textgroup_import
    set_agent
    cite_tg_arr = get_cite_rows('textgroups', 'textgroup', 'all')
    cite_tg_arr.each do |tg|
      textgroup_row(tg)
    end
  end

  def author_import
  
    set_agent
    cite_auth_arr = get_cite_rows('authors', 'canonical_id', 'all')
    cite_auth_arr.each do |auth|
      begin
        if auth['urn_status'] == "published"
          mads = get_xml("#{BASE_DIR}/catalog_data/mads/#{auth['mads_file']}")
          tg_row = Textgroup.find_by_urn_end(auth['canonical_id'])      
          author_row(auth, tg_row, mads)
        end
      rescue
        puts "error with #{auth}\n#{$!}"
      end
    end

  end

  def get_xml(file)
    file_string = File.open(file, "r+")
    file_xml = Nokogiri::XML::Document.parse(file_string, &:noblanks)
    file_string.close
    return file_xml
  end

  def atom_parse(doc)
    begin
      start_time = Time.now 
      set_agent
      @error_report = File.open("#{BASE_DIR}/catalog_errors/error_log#{Date.today}.txt", 'w')
      #grab namespaces not defined on the root of the xml doc
      atom_id = doc.xpath("atom:feed/atom:id", {"atom" => ATOM_NS}).inner_text
      puts "parsing #{atom_id}"
      #creates instance variables for cts ids
      get_cts_ids(atom_id)
      cite_work_arr = get_cite_rows('works', 'work', @work_cts)
      #just in case we get more than one work due to a fuzzy search
      if cite_work_arr.length > 1
        correct_row = nil
        cite_work_arr.each {|r| correct_row = r if r['work'] == @work_cts}
        cite_work_arr = [correct_row]
      end
      #there should only be one work, but this gets it out of the array, 
      #work is a json object, less hassle than parsing XML
      cite_work_arr.each do |w|
        if w['urn_status'] == "published"
          tg = nil
          tg = Textgroup.find_by_urn_end(@auth_cts)
          #auth will be an array since there is the possibility of multiple authors
          auth = []
          auth = Author.find_all_potential_authors(@auth_cts)
          work = nil
          work = work_row(w, tg, doc)
          #link it all in tg_auth_work table
          
          if auth.empty?
            #check names
            checking = tg.group_name ? Author.find_by_name_or_alt_name(tg.group_name) : nil
            unless checking
              #if has a tg but no auth, add tg to auth table
              a = Author.new
              a.unique_id = tg.urn
              case tg.urn_end
              when /phi/
                a.phi_id = tg.urn_end
              when /tlg/
                a.tlg_id = tg.urn_end
              when /stoa/
                a.stoa_id = tg.urn_end
              else
                a.alt_id = tg.urn_end
              end
              a.name = tg.group_name ? tg.group_name : work.title
              a.save
              auth << a
            else
              auth = [checking]
              a = auth[0]
            end
          else
            #looking in the rel_works to pinpoint an author
            a = nil
            auth.each do |row|
              rel_w = row.related_works
              if rel_w && rel_w != ""
                a = row if rel_w =~ /#{@work_cts}/
              end
            end
            #if no matches in rel_works just use first author
            a = auth[0] unless a
          end  
          taw = nil
          taw = TgAuthWork.find_row(a.id, work.id, tg.id)
          unless taw
            taw = TgAuthWork.new
            taw.tg_id = tg.id
            taw.auth_id = a.id
            taw.work_id = work.id
            taw.save
          end
          version_rows(tg, auth, work, doc)
        end
      end
    rescue Exception => e
      puts "Something went wrong for the work parse! #{$!}"
      puts e.backtrace
    end
  end


  def get_cts_ids(atom_id) 
    @lit_type = atom_id[/\w+Lit/]
    @work_cts = atom_id[/urn(:|\w|\.)+/]
    @tg_cts = @work_cts[/urn.+\./].chop
    @auth_cts = @tg_cts[/:\w+$/].delete(':')
  end


  def textgroup_row(cite_tg)
    tg = nil    
    if cite_tg['textgroup'] =~ /urn:cts/
      tg = Textgroup.find_by_urn_end(cite_tg['textgroup'][/\w+$/])
      unless tg
        tg = Textgroup.new
        tg.urn = cite_tg['textgroup']
        tg.urn_end = cite_tg['textgroup'][/\w+$/]
        tg.group_name = cite_tg['groupname_eng']
        tg.save
      else
        unless tg.urn == cite_tg['textgroup']
          tg.urn = cite_tg['textgroup']
          tg.save
        end
        unless tg.group_name == cite_tg['groupname_eng']
          tg.group_name = cite_tg['groupname_eng']
          tg.save
        end
      end
    else
      message = "A CITE Textgroup has a non-conforming urn, #{cite_tg['textgroup']}"
      error_handler(message)
    end
    return tg
  end
  

  def author_row(a, cite_tg_row, doc)
    #since there are textgroups without mads and the cite authors are a record of our mads
    #we will lack cite authors where we have authors in the catalog, therefore
    #cite_auth_arr might be empty, but want to still update/add these authors so as to provide the ability to search for them
    #but they must have at least a textgroup, otherwise there is no way for them to have any sort of unique id
    auth_arr = []
    final_auth_arr = []
    #if no cite author, no cite tg
    begin  
      unless cite_tg_row == nil || cite_tg_row['has_mads'] == 'false' || a.empty?        
        auth_arr = Author.find_by_major_ids(a['canonical_id'])
        auth_arr = [Author.find_by_name_or_alt_name(a['authority_name'])] if auth_arr.empty?
        if auth_arr.empty? || auth_arr[0] == nil
          auth_arr = []
          auth_arr << Author.new_auth(a)
        end
        if auth_arr.length == 1
          auth = auth_arr[0] 
          auth_cite = a['urn'][/^[\w:]+\.\d+/]
          auth.unique_id = auth_cite unless auth.unique_id == auth_cite
          auth.name = a['authority_name'] unless auth.name == a['authority_name']
          alt_ids_arr = a['alt_ids'].split(/;|,/)
          alt_ids_arr << a['canonical_id'] unless (a['canonical_id'] == nil && a['canonical_id'] == "")
          alt_ids_arr.each do |alt_id|
            auth.phi_id = alt_id if alt_id =~ /phi/
            auth.tlg_id = alt_id if alt_id =~ /tlg/
            auth.stoa_id = alt_id if alt_id =~ /stoa/
            
          end
          alt_ids_arr.delete(auth.phi_id)
          alt_ids_arr.delete(auth.tlg_id)
          alt_ids_arr.delete(auth.stoa_id)
          auth.alt_id = alt_ids_arr.join(';')
          
        else
          names = []
          auth_arr.each {|au| names << au.name}
          message = "There is more than one author for urn #{a['urn']}, need to investigate #{names.join(',')}"
          error_handler(message)
        end
        
        auth.related_works = a['related_works']
    
        #Don't actually need this bit, but is good at catching author id errors...
        auth_ids = doc.xpath(".//mads:identifier[@type='citeurn']", {"mads" => MADS_NS})
        mads_xml = nil
        auth_ids.each do |node| 
          if node.inner_text == a['urn']
            mads_xml = node.parent
          end
        end

        alt_parts = doc.xpath("//mads:authority//mads:namePart[@type='termsOfAddress']", {"mads" => MADS_NS})
        dates = doc.xpath(".//mads:authority//mads:namePart[@type='date']",{"mads" => MADS_NS})
        auth.alt_parts = alt_parts.inner_text if alt_parts
        auth.dates = dates.inner_text if dates
      
        abbrs = turn_to_list(doc, ".//mads:variant[@type='abbreviation']", ";", {"mads" => MADS_NS}, ", ")  
        other_names = turn_to_list(doc, ".//mads:related", ";", {"mads" => MADS_NS}, ", ", "mads:name/mads:namePart[not(@type='date')]")
        if other_names.empty?  
          other_names = turn_to_list(doc, ".//mads:variant", ";", {"mads" => MADS_NS}, ", ", "mads:name/mads:namePart[not(@type='date')]")
        else
          other_names << ";" + turn_to_list(doc, ".//mads:variant", ";", {"mads" => MADS_NS}, ", ", "mads:name/mads:namePart[not(@type='date')]")
        end
        auth.alt_names = other_names
        auth.abbr = abbrs
        
        fields = turn_to_list(doc, ".//mads:fieldOfActivity", ";", {"mads" => MADS_NS})
        auth.field_of_activity = fields unless fields.empty?

        notes = turn_to_list(doc, ".//mads:note", ";", {"mads" => MADS_NS}) 
        auth.notes = notes unless notes.empty?
        
        auth_urls(auth, doc)
        
        auth.save
        final_auth_arr << auth
        
      else
        #need to create/find stub authors for textgroups that don't have mads files
        #and for mads that don't have a textgroup
        if cite_tg_row == nil
          auth_arr = []
          auth_arr = Author.find_by_major_ids(a['canonical_id']) if a
          auth_arr = [Author.find_by_name_or_alt_name(a['authority_name'])] if auth_arr.empty?

          if auth_arr.empty? || auth_arr[0] == nil
            auth_arr = []
            auth_arr << Author.new_auth(a, false)
          end
          if auth_arr.length == 1
            auth_cite = a['urn'][/^[\w:]+\.\d+/]
            auth_arr[0].unique_id = auth_cite unless auth_arr[0].unique_id == auth_cite
            auth_arr[0].name = a['authority_name'] unless auth_arr[0].name == a['authority_name']
            auth_arr[0].save
            final_auth_arr << auth_arr[0]
          else
            names = []
            auth_arr.each {|au| names << au['authority_name']}
            message = "There is more than one author for urn #{a['urn']}, need to investigate #{names.join(',')}"
            error_handler(message)
          end
        else
          auth_arr = []
          auth_arr = Author.find_by_major_ids(cite_tg_row['urn'])
          auth_arr = [Author.find_by_name_or_alt_name(cite_tg_row['groupname_eng'])] if auth_arr.empty?
          if auth_arr.empty? || auth_arr[0] == nil
            auth_arr = []
            auth_arr << Author.new_auth(cite_tg_row, true)
          else
            if auth_arr.length == 1
              tg_cite = cite_tg_row['urn'][/^[\w:]+\.\d+/]
              auth_arr[0].unique_id = tg_cite unless auth_arr[0].unique_id == tg_cite
              auth_arr[0].name = cite_tg_row['groupname_eng'] unless auth_arr[0].name == cite_tg_row['groupname_eng']
              auth_arr[0].save
              final_auth_arr << auth_arr[0]
            else
              names = []
              auth_arr.each {|au| names << au.name}
              message = "There is more than one author for urn #{cite_tg_row['urn']}, need to investigate #{names.join(',')}"
              error_handler(message)
            end
          end
        end
      end
      return final_auth_arr
    rescue Exception => e
      message = "Error in author row creation for #{a['mads_file']}, #{$!}\n#{e.backtrace}"
      puts message
      error_handler(message)
    end
  end
  
  
  def auth_urls(auth, doc)
    url_nodes = doc.xpath(".//mads:url", {"mads" => MADS_NS})
    if url_nodes
      url_nodes.each do |node|
        text = node.inner_text
        unless text.empty?
          AuthorUrl.author_url_row(text, auth, node)
        end
      end
    end
  end


  def work_row(w, tg, doc)
    wrk = Work.get_info(@work_cts)
    unless wrk
      wrk = Work.new
    end
    wrk.standard_id = @work_cts unless wrk.standard_id == @work_cts
    wrk.textgroup_id = tg.id unless wrk.textgroup_id == tg.id
    wrk.title = w['title_eng'] unless wrk.title == w['title_eng']
    wrk.language = w['orig_lang'] unless wrk.language == w['orig_lang']
    count_node = doc.xpath(".//mods:extent[@unit='words']", {"mods" => MODS_NS})
    wrk.word_count = count_node.inner_text.strip if count_node
    wrk.save
    return wrk
  end
  

  def version_rows(tg, auth, work, doc)
    #reminder, auth is an array while the others are ActiveRecord objects
    #versions is expressions in the blacklight db

    #going by what is in the atom feed since it is easier to look for versions
    #in the cite table than select the correct mods from the xml

    mods_nodes = doc.xpath(".//mods:mods", {"mods" => MODS_NS})
    unless mods_nodes.empty?
       
      mods_nodes.each do |mods|
        error_handler("Checking #{mods.attr('ID')}")
        mods_cts_node = mods.xpath("mods:identifier[@type='ctsurn']", {"mods" => MODS_NS}) 
        if mods_cts_node
          mods_cts = mods_cts_node.inner_text
          message = "CTS found #{mods_cts}"
          error_handler(message)
        else
          atom_ent = mods.parent.parent
          at_id = atom_ent.xpath(".//atom:id", {"atom" => ATOM_NS})
          message = "No CTS urn in record #{at_id}, please check"
          error_handler(message)
          next
        end
        cite_vers = get_cite_rows("versions", "version", "^#{mods_cts}$")
        puts "cite_vers #{cite_vers.length} for #{mods_cts}"
        unless cite_vers.empty?
          #should only be one of these
          cite_vers.each do |vers|
            begin
              vers_cts = vers['version']
              par_name = mods.parent.name
              if par_name == "modsCollection"
                num = mods.attribute('ID').value
                label_parts = vers['label_eng'].split(";")
                num_label = label_parts[0] + ";" + num
              end
              exp_arr = Expression.where(cts_urn: vers_cts)
              if exp_arr == []
                exp = Expression.new
                exp.cts_label = num ? num_label : vers['label_eng']
              elsif exp_arr.length == 1
                if num
                  if exp_arr[0].cts_label == num_label
                    exp = exp_arr[0]
                  else
                    exp = Expression.new
                    exp.cts_label = num_label
                  end
                else
                  exp = exp_arr[0]
                end
              else
                exp = nil
                exp_arr.each do |e|                 
                  exp = exp_arr[0] if e.cts_label == num_label
                end
                unless exp
                  exp = Expression.new
                  exp.cts_label = num_label
                end
              end
              exp.cts_descr = vers['desc_eng']
              exp.cts_urn = vers_cts
              exp.work_id = work.id
              exp.tg_id = tg.id
              exp.title = work.title
             
              #find alt and abbr titles
              alt_title_nodes = mods.xpath("./mods:titleInfo[not(@type='uniform')]", {"mods" => MODS_NS})
              unless alt_title_nodes.empty?
                alt_titles = []
                alt_title_nodes.each do |alt_node|
                  t_type = alt_node.attribute('type')
                  if t_type
                    if t_type.value == "abbreviated"
                      abr_title = alt_node.inner_text.gsub(/\s{2,}/, " ").strip
                      if exp.abbr_title == nil || exp.abbr_title.empty?
                        exp.abbr_title = abr_title
                      else
                        exp.abbr_title << (exp.abbr_title =~ /#{abr_title}$/ ? "" : ";#{abr_title}")
                      end
                    else
                      alt_t = alt_node.inner_text.gsub(/\s{2,}/, " ").strip
                      if exp.alt_title == nil || exp.alt_title.empty?
                        exp.alt_title = alt_t
                      else
                        exp.alt_title << (exp.alt_title =~ /#{alt_t}$/ ? "" : ";#{alt_t}")
                      end
                    end
                  else
                    #sometimes alt titles don't have a type
                    alt_t = alt_node.inner_text.gsub(/\s{2,}/, " ").strip
                    if exp.alt_title == nil || exp.alt_title.empty?
                      exp.alt_title = alt_t
                    else
                      exp.alt_title << (exp.alt_title =~ /#{alt_t}$/ ? "" : ";#{alt_t}")
                    end                   
                  end
                end
              end
              #add the abbreviated title(s) to the work table
              #this might need to be an update method
              if work.abbr_title != exp.abbr_title
                work.abbr_title = exp.abbr_title
                work.save
              end

              #find editors and translators
              mods.xpath(".//mods:name", {"mods" => MODS_NS}).each do |names|
                name_node = names.xpath(".//mods:namePart[not(@type='date')]", {"mods" => MODS_NS})
                raw_name = name_node.inner_text if name_node
                role_node = names.xpath(".//mods:roleTerm", {"mods" => MODS_NS})
                role_term = role_node.inner_text if role_node
                if role_term =~ /editor|compiler|translator/i
                  if raw_name && raw_name.empty? == false
                    raw_name.gsub!(/\*/, "")
                    person = EditorsOrTranslator.find_by_name_or_alt_name(raw_name)
                    #check for this ed/trans in the cite tables
                    cite_auth_ed = get_cite_rows('authors', 'authority_name', raw_name)
                    cite_tg_ed  = get_cite_rows('textgroups', 'groupname_eng', raw_name)
                    if cite_auth_ed.empty? && cite_tg_ed.empty?
                      message = "There is no cite or cts id associated with this editor/translator, #{raw_name}, please add a mads record"
                      error_handler(message)
                    end
                    cite_auth_urn = cite_auth_ed.empty? ? nil : cite_auth_ed[0]['urn']
                    cite_tg_urn = cite_tg_ed.empty? ? nil : cite_tg_ed[0]['urn']

                    unless person
                      person = EditorsOrTranslator.new
                      person.mads_id = cite_tg_urn if cite_tg_urn
                      person.alt_id = cite_auth_urn if cite_auth_urn
                      person.name = raw_name
                      dates_node = names.xpath(".//mods:namePart[@type='date']", {"mods" => MODS_NS})
                      person.dates = dates_node.inner_text if dates_node
                      person.save
                    end

                    exp.editor_id = person.id if role_term =~ /editor|compiler/i
                    exp.translator_id = person.id if role_term =~ /translator/i
                  else
                    message = "There is no name for this editor/translator, skipping"
                    error_handler(message)
                    next
                  end
                end
              end
              #record the language that the version is in
              exp.language = vers_cts[/\w+\d+$/][/\D+/]
              #translation or edition?
              exp.var_type = vers['ver_type']
              #get page ranges and word counts
              mods.xpath(".//mods:part/mods:extent", {"mods" => MODS_NS}).each do |ex_tag|
                attrib = ex_tag.attribute('unit')
                unit_attr = attrib.value if attrib
                if unit_attr == "pages"
                  chil = ex_tag.xpath("mods:list", {"mods" => MODS_NS})
                  unless chil.empty?
                    exp.pages = chil.inner_text
                  else
                    pg_s = ex_tag.xpath(".//mods:start", {"mods" => MODS_NS})
                    pg_e = ex_tag.xpath(".//mods:end", {"mods" => MODS_NS})
                    pages = pg_s.inner_text if pg_s
                    pages = pages + "-#{pg_e.inner_text}" if pg_e
                    exp.pages = pages
                  end
                elsif unit_attr == "words"
                  exp.word_count = ex_tag.xpath(".//mods:total", {"mods" => MODS_NS}).inner_text
                end
              end             
              #get all host work information
              #some won't have more than one tag, but turn_to_list can work with single cases
              host_urls = []
              hosts = mods.xpath(".//mods:relatedItem[@type='host']", {"mods" => MODS_NS})
              if hosts.empty?
                hosts = mods
                #not collecting urls, since there is no host section
                mods_host_process(exp, hosts)
              else
                hosts.each do |host|
                  host_urls = mods_host_process(exp, host)
                  if exp.table_of_cont == nil || exp.table_of_cont == ""
                    tb_cont = mods.xpath(".//mods:tableOfContents", {"mods" => MODS_NS})
                    exp.table_of_cont = tb_cont.inner_text unless tb_cont.empty?
                  end
                end
              end
              
              #series_id 
              ser = Series.series_row(mods, {"mods" => MODS_NS})
              exp.series_id = ser.id if ser
              
              exp.save

              #expression urls
              ex_u = url_get(mods, "./mods:location/mods:url", {"mods" => MODS_NS})
              ExpressionUrl.expr_urls(exp.id, ex_u)
              ExpressionUrl.expr_urls(exp.id, host_urls, true)

            rescue Exception => e
              message = "Something went wrong in the version row creation for #{vers['version']}! #{$!}\n#{e.backtrace}"
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

  def mods_host_process(exp, host)
    exp.host_title = turn_to_list(host, "./mods:titleInfo[not(@type='uniform')]", ";", {"mods" => MODS_NS}, ", ")
    host.xpath(".//mods:originInfo", {"mods" => MODS_NS}).each do |orig|
      exp.place_publ = turn_to_list(orig, ".//mods:place/mods:placeTerm[not(@type='code')]", ";", {"mods" => MODS_NS}) 
      exp.place_code = turn_to_list(orig, ".//mods:place/mods:placeTerm[@type='code']", ";",{"mods" => MODS_NS}) 
      exp.publisher = turn_to_list(orig, ".//mods:publisher", ";", {"mods" => MODS_NS})
      exp.date_publ = turn_to_list(orig, ".//mods:dateIssued", ";", {"mods" => MODS_NS})
      exp.date_publ = turn_to_list(orig, ".//mods:dateCreated", ";", {"mods" => MODS_NS}) if (exp.date_publ == nil || exp.date_publ == "")
      exp.date_publ = turn_to_list(orig, ".//mods:copyrightDate", ";", {"mods" => MODS_NS}) if (exp.date_publ == nil || exp.date_publ == "")
      date_int = date_process(exp.date_publ)
      exp.date_int = (date_int == 0 ? nil : date_int)
      exp.date_mod = turn_to_list(orig, ".//mods:dateModified", ";", {"mods" => MODS_NS})
      exp.edition = turn_to_list(orig, ".//mods:edition", ";", {"mods" => MODS_NS})
    end
    exp.phys_descr = turn_to_list(host, ".//mods:physicalDescription", ";", {"mods" => MODS_NS}, ", ")
    exp.notes = turn_to_list(host, ".//mods:note", ";", {"mods" => MODS_NS}) 
    subj = turn_to_list(host, ".//mods:subject", ";", {"mods" => MODS_NS}, "--")
    exp.subjects = sub_geo_codes(subj)                
    tb_cont = host.xpath(".//mods:tableOfContents", {"mods" => MODS_NS})
    exp.table_of_cont = tb_cont.inner_text unless tb_cont.empty?
    host_urls = url_get(host, ".//mods:url", {"mods" => MODS_NS})
    exp.oclc_id = turn_to_list(host, ".//mods:identifier[@type='oclc']", ";", {"mods" => MODS_NS})
    return host_urls
  end

  def url_get(doc, path, ns)
    urls = []
    doc.xpath(path, ns).each do |url_node|
      dl = url_node.attribute("displayLabel")
      display = dl ? dl.value : nil
      url = url_node.inner_text.strip
      unless url.empty?
        unless display == nil || display.empty?
          #clean the display text... random spacing in some
          arr = display.split(/\s/)
          arr.delete("")
          u = [arr.join(" "), url]
        else
          case url
            when /hdl/
              display = "HathiTrust"
            when /books\.google/
              display = "Google Books"
            when /lccn/
              display = "LC Permalink"
            when /worldcat/
              display = "WorldCat"
            when /archive\.org/
              display = "Open Content Alliance"
            when /perseus/
              display = "Perseus"
          else
            display = url
          end              
          u = [display, url]
        end
        urls << u
      else
        next
      end
    end
    return urls
  end

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
        unless node_list.include?(node.inner_text)
          if multi
            if exc
              sub_nodes = node.xpath(exc, ns)
              name = ""
              sub_nodes.each {|n| name << (name.empty? ? n.inner_text : ", #{n.inner_text}")}
              node_list << name
            else
              node_list << node.inner_text.strip.gsub(/\n\s*/, multi).gsub(/,,| ,/, ",")
            end
          else
            node_list << node.inner_text.strip
          end
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

  def sub_geo_codes(subj)
    subj_arr = subj.split(";")
    subj_arr.each_with_index do |s, i|
      if s =~ /-{3,}/
        code = s[/\w+(-?\w+)*/]
        place = ""
        geocodes = File.read("#{BASE_DIR}/perseus_catalog/tmp_files/geo_codes.csv").split("\n")
        geocodes.each do |row|
          r = row.split(',')
          if r[0] == code
            place = r[1]
            break
          end
        end
        subj_arr[i] = place
        subj = subj_arr.join(";")
      end
    end
    return subj
  end

  def date_process(date_s)
    date_s.gsub(/-\?|\?/, "0") if (date_s && date_s != "")
    d = date_s[/\d+/]
    date_i = d.to_i
    return date_i
  end

end
