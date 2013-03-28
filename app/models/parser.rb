class Parser

  require 'mysql2'
  require 'nokogiri'
  require 'author.rb'
  require 'editors_or_translator.rb'
  require 'work.rb'
  require 'atom_error.rb'



  #FOR ALL: NEED TO ADD IN A LAST MODIFIED CHECK, PREVENT CONSTANT RE-WRITING OF ENTIRE TABLE ONCE EVERYTHING IS SET

  def self.mads_parse(doc, file_type)

    #MADS maps to the authors table, the fields in the table are
    #id, name, alt_parts, birth_date, death_date, alt_names, field_of_activity
    #notes, urls, mads_id
    begin
      
      #pull the author authority name
      auth_set = doc.xpath("//mads:authority//mads:namePart[not(@type='date')]")
      name_arr=[]
      auth_set.each {|node| name_arr << node.inner_text}
      auth_name = name_arr.join(" ")

      var_set = doc.xpath("//mads:variant")
      name_var = []
      var_set.each {|node| name_var << node.inner_text.strip.gsub(/\n\s+/, ", ")}
      other_names = name_var.join("; ")

      #just in case we have an author without an authority name
      if auth_name == nil or auth_name == " "
        auth_name = name_var[0]
      end

      if file_type == "author"
        person = Author.find_by_name_or_alt_name(auth_name)
      else
        person = EditorsOrTranslator.find_by_name_or_alt_name(auth_name)
      end

      #determine if author already in the table, if not, make a new row
      unless person
        file_type == "author" ? person = Author.new : person = EditorsOrTranslator.new
      end

      if person
        puts "saving record for #{auth_name}"
        person.name = auth_name
        person.alt_names = other_names
        temp = name_arr.drop(1)
        person.alt_parts = temp.join("; ")
        person.dates = doc.xpath("//mads:authority//mads:namePart[@type='date']").inner_text

        person.field_of_activity = turn_to_list(doc, "//mads:fieldOfActivity", "; ")

        person.notes = turn_to_list(doc, "//mads:note", "; ")

        person.urls = turn_to_list(doc, "//mads:url", "; ")

        ids = []
        count = ["", 0, false]
        doc.xpath("mads:mads/mads:identifier").each do |id|
          if id.attribute('type')
            id_type = id.attribute('type').value 
            id_type = "stoa" if id_type =~ /stoa/
            nums = id.inner_text.gsub(/\.\w+|-\w+/, "")
            #standardize the numbers, pad with 0s if needed
            nums = sprintf("%04d", nums) if !(nums =~ /\s|[a-z]|\d{4}/)
            #taking into account potential "Psuedo" authors without their own record
            if (id.attribute('displayLabel') && (id.attribute('displayLabel').value != "SHA"))
              alt_id_name = id.attribute('displayLabel').value
              ids << "#{alt_id_name}: #{id_type}#{nums}"
            else
              ids << (id_type=~/stoa/ ? "#{nums}" : "#{id_type}#{nums}")

              #count the occurances of related work ids, will try to use the id type that has the most related works
              rw_set = doc.xpath("mads:mads/mads:extension/identifier")
              count[2] = true unless rw_set.empty?
              type_set = rw_set.find_all {|node| node.attribute('type').value =~ /#{id_type}/}
              if type_set
                tl = type_set.length 
                if tl > count[1]
                  count[0] = id_type
                  count[1] = tl
                end
              end
            end
          end
        end
        person.alt_id = ids.join("; ")

        unless count[0] == ""
          best_id = ids.select{|x| x =~ /#{count[0]}/}
          person.mads_id = best_id.first 
        else
          if count[2] == true
            puts "Listed related works do not synch with ids"
            person.mads_id = ids.first
          else
            puts "No listed related works"
            person.mads_id = ids.first
          end
        end
        #if record has none of the main id types, grab the first identifier to make sure there is an id saved
        frst_id = doc.xpath("//mads:identifier")[0]
        person.mads_id = "#{frst_id.attribute('type').value}#{frst_id.inner_text}" unless person.mads_id
 
        person.save
          
      end

      puts "MADS record imported!"

    rescue Exception => e
      puts "Something went wrong! #{$!}" 
      puts e.backtrace
    end  
  end


  def self.turn_to_list(doc, path, join_type)

    node_set = doc.xpath(path)
    node_list = []
    node_set.each {|node| node_list << node.inner_text}
    node_string = node_list.join(join_type)
    return node_string

  end

  def self.error_parse(doc)
    #import of error files produced by producing the atom feed, for purposes of figuring out the gaps of the catalog
    begin
      doc.each do |line|
        clean_line = line.gsub(/\%20/, " ")
        l_arr = line.split('&')
        #0e_Perseus 1e_ids 2e_titles 3e_lang 4e_idTypes 5e_updateDate 6e_authorUrl 7e_authorNames 8e_collection 9e_authorId

        #get the id and id type, need to account for multiple ids listed
        id_arr = l_arr[1].split("%2C")
        id_type_arr = l_arr[4].split("%2C")

        id_arr.each_with_index {|id, ind| full_ids[ind] = "#{id}#{id_type_arr[ind]}"}
        puts "testing how this works"

        #get the title
        #get the language
        #get the author name and use the id to get probable mads id
        #search the authors table for the author, if they aren't there, create a new author
      end
    rescue Exception => e
      puts "Something went wrong! #{$!}" 
      puts e.backtrace
    end
  end

  def self.data_clean(piece)
    arr = piece.split("%2C")
    first = arr[0].gsub(/.+\=/, "")
    arr[0] = first
  end

  def self.atom_parse(doc)
    #importing of information from atom feeds, will populate several tables

    begin
      #grab namespaces not defined on the root of the xml doc
      ns = doc.collect_namespaces

      #begin with identifying the work
      id = doc.xpath("atom:feed/atom:id", ns).inner_text

      #find the author
      auth_raw = doc.xpath("//cts:groupname", ns).inner_text
      if id
        #search for the author by id
        a_id = id.split(".")[0]

        #an attempt to take into account the few that lack phi or tlg at the front
        unless a_id =~ /[a-z]+\d+/
          o_id = doc.xpath("atom:feed/atom:entry/atom:id").first.inner_text
          if o_id =~ /latinLit/
            a_id = "phi#{a_id}"
          elsif o_id =~ /greekLit/
            a_id = "tlg#{a_id}"
          end
        end
        author = Author.find_by_mads_or_alt_ids(a_id)
        
      end

    #if the author can not be found by id or alt_id, then create a new author in the table
      unless author
        author = Author.new
        author.name = auth_raw
        author.mads_id = id.split(".")[0]
        author.save
      end
      
      #grab the first word count, since right now all word counts are really work level
      w_c = doc.xpath("//mods:part/mods:extent/mods:total", ns)
      words = w_c.first.inner_text if w_c.first

      #find if there is a row for this work already, if not, create a new one and populate the row
      work = Work.find_by_standard_id(id)

      unless work
        work = Work.new
      end

      if work and author
        
        work.standard_id = id
        work.clean_id = id.gsub(/\.|\s/, "_")
        work.author_id = author.id
        w_set = doc.xpath("//cts:work", ns)
        work.title = w_set.xpath("dc:title", ns).inner_text
        work.language = w_set.attribute('lang').value
        work.word_count = words
        work.save
      else
        puts "Missing a work or author entry in the tables, something is wrong, check the file for #{auth_raw} and/or #{id}"
      end

      #run through the MODS records contained in the feed to create expressions and series
      doc.xpath("//mods:mods", ns).each do |mods_rec|
         
        #we are organizing and identifying expressions with the cts_urns
        raw_urn = mods_rec.xpath("mods:identifier[@type='ctsurn']", ns).inner_text
        if raw_urn == nil or raw_urn == ""
          throw "Lacks a ctsurn, can not save!!"
        end
        expression = Expression.find_by_cts_urn(raw_urn)

        unless expression
          expression = Expression.new
          expression.cts_urn = raw_urn
        end
  
        expression.clean_cts_urn = raw_urn.gsub(/\.|:|-/, "_")
        expression.work_id = work.id

        #find the uniform, abbreviated and alternative titles
        mods_rec.xpath("mods:titleInfo", ns).each do |title_node|
          raw_title = title_node.inner_text.strip.gsub(/\s*\n\s*/, ", ")
          if title_node.attribute('type')
            expression.title = raw_title if title_node.attribute('type').value == 'uniform'
            expression.abbr_title = raw_title if title_node.attribute('type').value == 'abbreviated'
            expression.alt_title = raw_title if title_node.attribute('type').value == 'alternative'
          else
            expression.alt_title = raw_title
          end
        end
        
        #find editors and translators
        mods_rec.xpath(".//mods:name", ns).each do |names|
          raw_name = names.xpath("mods:namePart[not(@type='date')]", ns).inner_text
          role_term = names.xpath(".//mods:roleTerm", ns).inner_text
          if role_term =~ /editor|compiler|translator/i
            person = EditorsOrTranslator.find_by_name_or_alt_name(raw_name)
            unless person
              person = EditorsOrTranslator.new
              person.name = raw_name
              person.dates = names.xpath("mods:namePart[@type='date']", ns).inner_text
              person.save
            end

            expression.editor_id = person.id if role_term =~ /editor|compiler/i
            expression.translator_id = person.id if role_term =~ /translator/i
          end
        end

        expression.language = mods_rec.xpath("mods:language/mods:languageTerm", ns).inner_text
          
        #the following group occurs in the originInfo tag
        raw_place = []
        mods_rec.xpath(".//mods:placeTerm[@type='text']", ns).each {|p| raw_place << p.inner_text}
        expression.place_publ = raw_place.join("; ")

        raw_pub =[]
        mods_rec.xpath(".//mods:publisher", ns).each {|pu| raw_pub << pu.inner_text}
        expression.publisher = raw_pub.join("; ")

        pub_date = mods_rec.xpath(".//mods:dateIssued", ns).inner_text.to_i
        expression.date_publ = pub_date unless pub_date == 0 or pub_date == nil
        mod_date = mods_rec.xpath(".//mods:dateModified", ns).inner_text.to_i        
        expression.date_mod = mod_date unless mod_date == 0 or mod_date == nil

        expression.edition = mods_rec.xpath(".//mods:edition", ns).inner_text

        raw_des = mods_rec.xpath(".//mods:physicalDescription", ns).inner_text
        expression.phys_descr =  raw_des.strip.gsub(/\s*\n\s*/,'\; ')
        
        #compile all note tags
        raw_notes = []
        mods_rec.xpath(".//mods:note", ns).each {|n| raw_notes << n.inner_text}
        expression.notes  = raw_notes.join("; ")
        
        #compile all subject tags and subtags
        raw_subjects =[]
        mods_rec.xpath(".//mods:subject", ns).each do |s|
          parts =[]
          s.children.each {|s_part| parts << s_part.inner_text.strip}
          parts.delete("")
          raw_subjects << parts.join(", ")
        end
        expression.subjects = raw_subjects.join("; ")

        #compile all urls
        raw_urls = []
        mods_rec.xpath("mods:location/mods:url", ns).each do |u|
          url_label = u.attribute('displayLabel')
          url_name = url_label.value if url_label
          if url_name
            raw_urls << "#{url_name}, #{u.inner_text}"
          else
            raw_urls << u.inner_text
          end
        end
        expression.urls = raw_urls.join("; ")

        mods_rec.xpath("mods:relatedItem", ns).each do |rel_item|
          #get host work info
          type_attr = rel_item.attribute('type')
          if type_attr and type_attr.value == "host"
            raw_ht =[]
            rel_item.xpath("mods:titleInfo", ns).children.each {|c| raw_ht << c.inner_text.strip}
            raw_ht.delete("")
            expression.host_title = raw_ht.join("; ")
            h_urls = []
            rel_item.xpath("mods:location/mods:url", ns).each do |u|
              url_label = u.attribute('displayLabel')
              url_name = url_label.value if url_label
              if url_name
                h_urls << "#{url_name}, #{u.inner_text}"
              else
                h_urls << u.inner_text
              end
            end
            expression.host_urls = h_urls.join("; ")
          end

          #get series info
          if type_attr and type_attr.value ==  "series"
            ser_title = nil
            ser_abb = nil
            rel_item.xpath("mods:titleInfo", ns).each do |tf|
              raw_ser = tf.inner_text.strip.gsub(/\s*\n\s*/,', ')
              if (tf.attribute('type') and tf.attribute('type').value == "abbreviated")
                ser_abb = raw_ser 
              else
                ser_title = raw_ser
              end
            end
            #series name standardization
            case
              when (ser_title =~ /Teubner/i or ser_abb =~ /Teubner/i)
                clean_title = "Bibliotheca Teubneriana"
              when (ser_title =~ /Loeb|LCL/i or ser_abb =~ /Loeb|LCL/i)
                clean_title = "Loeb Classical Library"
              when (ser_title =~ /Oxford|oxoniensis/i or ser_abb =~ /OCT/i)
                clean_title = "Oxford Classical Texts"
              when (ser_title =~ /Bohn/i)
                clean_title = "Bohn's Classical Library"
              else
                clean_title = ser_title.split(/,|\[|\(/)[0]
            end

            ser = Series.find_by_clean_title(clean_title)

            unless ser
              ser = Series.new
              ser.ser_title = ser_title
              ser.clean_title = clean_title
              ser.abbr_title = ser_abb if ser_abb
              ser.save
            end

            expression.series_id = ser.id if (ser and !expression.series_id)

          end

          #get page ranges and word counts
          mods_rec.xpath("mods:part/mods:extent", ns).each do |ex_tag|
            unit_attr = ex_tag.attribute('unit').value
            if unit_attr == "pages"
              expression.page_start = ex_tag.xpath("mods:start", ns).inner_text
              expression.page_end = ex_tag.xpath("mods:end", ns).inner_text
            elsif unit_attr == "words"
              expression.word_count = ex_tag.xpath("mods:total", ns).inner_text
            end
          end

          #get oclc id
          expression.oclc_id = rel_item.xpath("mods:identifier[@type='oclc']", ns).inner_text

          #HAVE IGNORED CONSTITUENT ITEMS FOR NOW UNTIL I FIGURE OUT HOW TO HANDLE THEM
        end

        expression.save
        
      end

    rescue Exception => e
      puts "Something went wrong! #{$!}"
      puts e.backtrace
    end
  end

end