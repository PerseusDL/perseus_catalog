class Parser

  require 'mysql2'
  require 'nokogiri'
  require 'author.rb'
  require 'editors_or_translator.rb'
  require 'work.rb'

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
      auth_name = name_arr[0]

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

        person.field_of_activity = doc.xpath("//mads:fieldOfActivity").inner_text

        note_set = doc.xpath("//mads:note")
        note_list = []
        note_set.each {|node| note_list << node.inner_text}
        person.notes = note_list.join("; ")

        url_set = doc.xpath("//mads:url")
        url_list = []
        url_set.each {|node| url_list << node.inner_text}
        person.urls = url_list.join("; ")

        alt_ids = []
        doc.xpath("mads:mads/mads:identifier").each do |id|
          id_type = id.attribute('type').value
          #taking into account potential "Psuedo" authors without their own record
          if id.attribute('displayLabel')
            alt_id_name = id.attribute('displayLabel').value
            alt_ids << "#{alt_id_name}: #{id_type}#{id.inner_text}"
          else
            alt_ids << (id_type=~/stoa/ ? "#{id.inner_text}" : "#{id_type}#{id.inner_text}")
            unless person.mads_id
              case id_type 
                when "tlg", "phi", "stoa", "stoa author", "stoa author-text"
                  person.mads_id = (id_type=~/stoa/ ? "#{id.inner_text}" : "#{id_type}#{id.inner_text}")
              end 
            end
          end
        end
        person.alt_id = alt_ids.join("; ")

        #if record has none of the main id types, grab the first identifier to make sure there is an id saved
        frst_id = doc.xpath("//mads:identifier")[0]
        person.mads_id = "#{frst_id.attribute('type').value}#{frst_id.inner_text}" unless person.mads_id
 
        person.save
          
      end

      puts "MADS record imported!"

    rescue
        puts "Something went wrong! #{$!}" 
    end  
  end


  def self.mods_parse(doc)

  end


  def self.atom_parse(doc)
    #importing of information from atom feeds, will populate several tables

    begin
      #grab namespaces not defined on the root of the xml doc
      ns = doc.collect_namespaces

      #begin with identifying the work
      id = doc.xpath("atom:feed/atom:id").inner_text

      #find the author
      auth_raw = doc.xpath("//cts:groupname", ns).inner_text
      author = Author.find_by_name_or_alt_name(auth_raw)
   
      unless author
        author = Author.new
        author.name = auth_raw
        author.mads_id = id.split(".")[0]
        author.save
      end

      #find if there is a row for this work already, if not, create a new one and populate the row
      work = Work.find_by_standard_id(id)

      unless work
        work = Work.new
      end

      if work and author
        
        work.standard_id = id
        work.author_id = author.id
        w_set = doc.xpath("//cts:work", ns)
        work.title = w_set.xpath("dc:title", ns).inner_text
        work.language = w_set.attribute('lang').value
        work.save
      else
        puts "Missing a work or author entry in the tables, something is wrong, check the file for #{auth_raw} and/or #{id}"
      end

      #run through the MODS records contained in the feed to create expressions and series
      doc.xpath("//mods:mods", ns).each do |mods_rec|

        #we are organizing and identifying expressions with the cts_urns
        raw_urn = mods_rec.xpath("mods:identifier[@type='ctsurn'", ns).inner_text
        expression = Expressions.find_by_cts_urn(raw_urn)

        unless expression
          expression = Expressions.new
        end
        debugger
        expression.work_id = work.id
        expression.page_start = mods_rec.xpath("//extent/start", ns).inner_text
        expression.page_end = mods_rec.xpath("//extent/end", ns).inner_text

        #find the uniform, abbreviated and alternative titles
        mods_rec.xpath("mods:titleInfo", ns).each do |title_node|
          expression.title = title_node.inner_text if title_node.attribute('type').value == 'uniform'
          expression.abbr_title = title_node.inner_text if title_node.attribute('type').value == 'abbreviated'
          expression.alt_title = title_node.inner_text if title_node.attribute('type').value == 'alternative'
        end
        
        #find editors and translators
        mods_rec.xpath("//name").each do |names|
          raw_name = names.xpath("namePart[not(@type='date')]", ns).inner_text
          person = EditorsOrTranslator.find_by_name_or_alt_name(raw_name)
          unless person
            person = EditorsOrTranslator.new
            person.name = raw_name
            person.dates = names.xpath("namePart[@type='date']", ns).inner_text
            person.save
          end

          role_term = names.xpath("//roleTerm", ns).inner_text

          expression.editor = person.id if role_term =~ /editor|compiler/i
          expression.translator = person.id if role_term =~ /translator/i
        end

        expression.language = mods_rec.xpath("//languageTerm", ns).inner_text

        #the following group occurs in the originInfo tag
        expression.place_publ = mods_rec.xpath("//placeTerm[@type='text']", ns).inner_text
        expression.publisher = mods_rec.xpath("//publisher", ns).inner_text
        expression.date_publ = mods_rec.xpath("//dateIssued", ns).inner_text
        expression.date_mod = mods_rec.xpath("//dateModified", ns).inner_text
        expression.edition = mods_rec.xpath("//edition", ns).inner_text

        expression.phys_descr = mods_rec.xpath("//physicalDescription", ns).inner_text #will have \n, or need delimiter?
        
        #compile all note tags
        raw_notes = []
        mods_rec.xpath("//note", ns).each {|n| raw_notes << n}
        expression.notes  = raw_notes.join("; ")
        
        #compile all subject tags and subtags
        raw_subjects =[]
        mods_rec.xpath("//subject", ns).each do |s|
          parts =[]
          s.children.each {|s_part| parts << s_part}
          raw_subjects << parts.join(", ")
        end
        expression.subjects = raw_subjects.join("; ")

        #compile all urls
        raw_urls = []
        mods_rec.xpath("location/url", ns).each {|u| raw_urls << "#{u.attribute('displayLabel').value}, #{u.inner_text}"}
        expression.urls = raw_urls.join("; ")

        mods_rec.xpath("relatedItem", ns).each do |rel_item|
          #get host work info
          if rel_item.attribute('type').value == "host"
            expression.host_title = rel_item.xpath("titleInfo", ns).inner_text
            h_urls = []
            rel_item.xpath("location/url", ns).each {|u| h_urls << "#{u.attribute('displayLabel').value}, #{u.inner_text}"}
            expression.host_urls = h_urls.join("; ")
          end

          #get series info
          if rel_item.attribute('type').value == "series"
            rel_item.xpath("titleInfo", ns).each do |tf|
              if tf.attribute('abbreviated')
                ser_abb = tf.inner_text 
              else
                ser_title = tf.inner_text
              end
            end

            ser = Series.find_by_ser_title(ser_title)

            unless ser
              ser = Series.new
              ser.ser_title = ser_title
              ser.abbr_title = ser_abb if ser_abb
              ser.save
            end

            expression.series_id = ser.id if ser
          end

          #HAVE IGNORED CONSTITUENT ITEMS FOR NOW UNTIL I FIGURE OUT HOW TO HANDLE THEM
        end

        expression.save
        
      end

    rescue
      puts "Something went wrong! #{$!}"
    end
  end

end