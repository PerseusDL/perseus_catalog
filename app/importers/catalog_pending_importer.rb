#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================


class CatalogPendingImporter
  include CiteColls

  #The Plan
    #Xif mads split off
    #find needed info, cts urns, author names, titles, language, etc.
    #Xlook for constituent items
      #if they are there, peel off to a different method 
    #Xsearch the authors, textgroups, and works tables
      #if not found, add a row with whatever info is needed
    #search versions table for all versions
      #if none, give urn:cts:(greekLit/latinLit):(id):(opp/perseus)-(lang)1
      #if some
        #check titles and descriptions
          #if the same or close, throw an error and save info for human review
          #if no similar titles, find the appropriate language and number and give the next number
    #if the urn is successfully assigned
      #add an id tag with the ctsurn
      #add mods namespace prefix to tags that need it
      #save in catalog_data with path based on the urn

  #This should throw an error at the slightest issue so it gets looked at by a human and either the record is
  #fixed or it is added by hand to the CITE tables

  def pending_mods_import
    multi_agents
    cite_key
    @error_report = File.open("#{ENV['HOME']}/catalog_pending/errors/error_log#{Date.today}.txt", 'w')
    pending_mads = "#{ENV['HOME']}/catalog_pending/mads"
    pending_mods = "#{ENV['HOME']}/catalog_pending/mods"
    #update_git_dir("catalog_pending") UNCOMMENT THIS

    #cite_tables_backup UNCOMMENT THIS

    #go through items in catalog_pending
    #pending_mads_import(pending_mads) UNCOMMENT THIS
    mods_dirs = clean_dirs(pending_mods)
    mods_dirs.each do |name_dir|
          
      level_down = clean_dirs(name_dir)
      collect_xml = level_down.select { |f| File.file? f}
      if collect_xml.empty?
        level_down.each do |publisher_dir|
          collect_xml = clean_dirs(publisher_dir)
        end
      end
      collect_xml.each do |mods|
        mods_string = File.read(mods)
        mods_xml = Nokogiri::XML::Document.parse(mods_string, &:noblanks)
        unless mods_xml.search("//relatedItem[@type='constituent']").empty?
          #has constituent items, needs to be passed to a method to create new mods
          split_constituents(mods_xml, mods)
        else
          info_hash = find_basic_info(mods_xml, mods)
          #have the info from the record and cite tables, now process it
          #:a_name,:a_id,:cite_auth,:cite_tg :w_title,:w_id,:cite_work,:w_lang
          
          
        end
      end
    end
    
  end

  

  def pending_mads_import(pending_mads)
    mads_dirs = clean_dirs(pending_mads)
    mads_dirs.each do |name_dir|

      mads = clean_dirs(name_dir).select { |f| f =~ /mads/}[0]
      mads_string = File.read(mads)
      mads_xml = Nokogiri::XML::Document.parse(mads_string, &:noblanks)
      info_hash = find_basic_info(mads_xml, mads)
    end
  end

  def split_constituents(mods_xml, file_path)

  end

  def find_basic_info(xml_record, file_path)
    #a regex ugly enough that only its mother could love it, 
    #all to get a file name that I had earlier but cleverly turned into the path that I needed then...
    f_n = file_path[/(\/[a-zA-Z1-9\.\(\)]+)?\.xml/] 
    id, alt_ids = find_rec_id(xml_record, file_path, f_n)
    #for mads the w_id and a_id will be the same
    w_id = id =~ /tlg/ ? "urn:cts:greekLit:#{id}" : "urn:cts:latinLit:#{id}"
    a_id = w_id[/urn:cts:\w+:\w+\d+[a-z]*/]
    if id
      #search for and compare author values
      auth_name = find_rec_author(xml_record, file_path, f_n)
      auth_nset = find_author(a_id)      
      tg_nset = find_textgroup(a_id)   
      
      info_hash = { :file_name => f_n,
                    :a_name => auth_name,
                    :a_id => a_id,
                    :cite_auth => auth_nset,
                    :cite_tg => tg_nset}

      if f_n =~ /mods/
        work_title = nil
        xml_record.search("mods/titleInfo").each do |title_node|
          #take uniform if it exists
          type = title_node.attribute("type")
          if type && type.value == "uniform"
            work_title = title_node.search("title").inner_text
          end
          unless work_title && type
            work_title = title_node.search("title").inner_text
          end
          unless work_title
            work_title = title_node.search("title").inner_text
          end
        end

        work_nset = find_work(w_id)
       
        orig_lang = xml_record.search("mods/language/languageTerm")
        info_hash.merge!(:w_title => work_title,
                      :w_id => w_id,
                      :cite_work => work_nset,
                      :w_lang => orig_lang)
      else
        #need alt ids and related works
        alts = xml_record.search()
        #alt ids, grab all ids, each do clean_id, find the a_id, strip it out, remove any "none"
        #related works, easy, find <mads:description>List of related work identifiers and grab siblings

      end
      
      return info_hash       
    end
  end

  def add_to_cite_tables(info_hash, mads) #mads is a bool
    #need to know if mods or mads
    keys = table_keys
    auth_col = "urn, authority_name, canonical_id, mads_file, alt_ids, related_works, urn_status, redirect_to, created_by, edited_by"
    tg_col = "urn, textgroup, groupname_eng, has_mads, mads_possible, notes, urn_status, created_by, edited_by"
    work_col = "urn, work, title_eng, notes, urn_status, created_by, edited_by"

    if info_hash[:cite_auth].empty?

      #double check that we don't have a name that matches the author name
      #no row for this author, add a row 
      debugger
      urn = generate_urn(keys[:Authors], "author")
      if mads
        frst_let = info_hash[:a_name][0,1]
        mads_path = "#{ENV['HOME']}/catalog_data/mads/PrimaryAuthors/#{frst_let}/#{info_hash[:a_name]}/#{info_hash[:file_name]}"
        values = "#{urn}, #{info_hash[:a_name]}, #{info_hash[:a_id]}, #{mads_path}, "
      end
      add_cite_row(keys[:Authors], auth_col)
    else
      #find name returned from cite tables, compare to name from record
      #if they aren't equal, throw an error, 
      #else move on if all info filled out if mods, double check can't add more info for mads
    end

    if info_hash[:cite_tg].empty?
      #double check that we don't have a name that matches the author name
      #no row for this textgroup, add a row
      #
    end

    if info_hash[:work_nset].empty?
      #no row for this work, add a row
    end
  end



  def find_rec_id(xml_record, file_path, f_n)
    begin
      ids = f_n =~ /mads/ ? xml_record.search("/mads:mads/mads:identifier") : xml_record.search("mods/identifier")
      found_id = nil
      alt_ids = []
      #parsing found ids, take tlg or phi over stoa unless there is an empty string or "none"
      ids.each do |node|
        id = clean_id(node)
        alt_ids << id
        if id =~ /tlg|phi|stoa/ #might need to expand this for LCCN, VIAF, etc. if we start using them
          found_id = id 
        end
      end
      #if no id found throw an error   
      unless found_id    
        message = "For file #{f_n} : Could not find a suitable id, please check 
        that there is a tlg, phi, or stoa id or that, if a mads, the mads namespace is present."
        error_handler(message, file_path, f_n)
        return
      else
        return found_id, alt_ids
      end
    rescue 
      message = "For file #{f_n} : There was an error while trying to find an id, error message was #{$!}."
      error_handler(message, file_path, f_n)
    end
  end


  def find_rec_author(xml_record, file_path, f_n)
    begin
      #grab mads authority name
      if f_n =~ /mads/ 
        name_ns = xml_record.search("/mads:mads/mads:authority/mads:name/mads:namePart")
        n = [] 
        unless name_ns.empty?
          name_ns.each {|x| n << x.inner_text}
          a_name = n.join(" ")
        else
          message = "For file #{f_n} : Could not find an authority name, please check the record."
          error_handler(message, file_path, f_n)
          return
        end
      else   
      #grab the name with the "creator" role      
        names = []
        name_ns = xml_record.search("mods/name")
        unless name_ns.empty?
          name_ns.each do |node|
            if node.search("role/roleTerm").inner_text == "creator"
              n = []
              node.search("namePart").each {|x| n << x.inner_text}
              names << n.join(" ")             
            end
          end
          if names.empty?
            message = "For file #{f_n} : Could not find an author name, please check the record."
            error_handler(message, file_path, f_n)
            return
          else
            a_name = names[0] if names.length == 1
            error_handler("For #{f_n} : should we worry about multiple creators in a record?", file_path, f_n) if names.length > 1
          end
        else
          message = "For file #{f_n} : Could not find an author name, please check the record."
          error_handler(message, file_path, f_n)
          return
        end
      end
      return a_name
    rescue
      message = "For file #{f_n} : There was an error while trying to find the author, error message was #{$!}."
      error_handler(message, file_path, f_n)
    end
  end


  def clean_dirs(dir)
    dirs_arr = Dir.entries(dir).map {|e| File.join(dir, e)}.select{|f| f unless f =~ /\.$/ || f =~ /\.\.$/ || f =~ /DS_Store/}
  end

  def clean_id(node)
    if node.attribute('type')
      val = node.attribute('type').value
      if val
        id = node.inner_text unless node.inner_text == "none" || node.inner_text == ""
        #stoas only need the - removed
        if id =~/(stoa\d+[a-z]*-|stoa\d+[a-z]*)/
          id = id.gsub('-', '.')      
        else
          #I hate that the ids aren't padded with 0s...            
          id_step = id.split(".").each_with_index {|x, i| i == 0 ? sprintf("%04d", x) : sprintf("%03d", x)}
          #add in tlgs or phis
          id = id_step.map {|x| "#{val}#{x}"}.to_s
        end
        return id
      end
    end
  end

  def error_handler(message, file_path, f_n)
    #move all files with errors to the error directory for human review
    puts message
    @error_report << "#{message}\n\n"
    `mv "#{file_path}" "#{ENV['HOME']}/catalog_pending/errors#{f_n}"`
  end

  def add_row #put in cite_colls?

  end

end