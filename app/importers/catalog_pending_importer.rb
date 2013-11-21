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


  def pending_mods_import
    multi_agents
    cite_key
    @error_report = File.open("#{ENV['HOME']}/catalog_pending/errors/error_log#{Date.today}.txt", 'w')
    pending_mads = "#{ENV['HOME']}/catalog_pending/mads"
    pending_mods = "#{ENV['HOME']}/catalog_pending/mods"
    #update_git_dir("catalog_pending")

    #cite_tables_backup

    #go through items in catalog_pending
    pending_mads_import(pending_mads)
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
        end
      end
    end
    #if mads split off?
    #find needed info, cts urns, author names, titles, language, etc.
    #look for constituent items
      #if they are there, peel off to a different method 
    #search the authors, textgroups, and works tables
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
  end

  def clean_dirs(dir)
    dirs_arr = Dir.entries(dir).map {|e| File.join(dir, e)}.select{|f| f unless f =~ /\.$/ || f =~ /\.\.$/ || f =~ /DS_Store/}
  end

  def pending_mads_import(pending_mads)

  end

  def split_constituents(mods_xml, file_name)

  end

  def find_basic_info(xml_record, file_name)
    f_n = file_name[/\/.+\.xml/]
    id = find_id(xml_record, file_name, f_n)
    if id
      #split for mads vs mods info, can search for and compare author values
      #mods_xml.search("mods/titleInfo/title") take uniform if it exists
      #mods_xml.search("mods/name/role/roleTerm") == "creator"
      #mods_xml.search("mods/language/languageTerm")
      debugger
      
      w_id = id =~ /tlg/ ? "urn:cts:greekLit:#{id}" : "urn:cts:latinLit:#{id}"
      a_id = w_id[/urn:cts:\w+:\w+\d+[a-z]*/]
      auth_nset = find_author(a_id)
      if auth_nset.empty?
        #no row for this author, add a row here and in tgs
      end
      tg_nset = find_textgroup(a_id)
      unless tg_nset
        #no row for this textgroup, add a row
      end
      work_nset = find_work(w_id)
      if work_nset.empty?
        #no row for this author, add a row
      end
    

    #use id to try to find a tg and work
    #compare to values found in the record
    #is ANYTHING is different throw an error, require exact matches

    #return hash of values
    end
  end

  def find_id(xml_record, file_name, f_n)
    begin
      ids = f_n =~ /mads/ ? xml_record.search("mads:mads/mads:identifier") : xml_record.search("mods/identifier")
      id = nil
      #parsing found ids, take tlg or phi over stoa unless there is an empty string or "none"
      ids.each do |node|
        if node.attribute('type')
          val = node.attribute('type').value
          if val == "tlg" || val == "phi" || val =~ /stoa/
            id = node.inner_text unless node.inner_text == "none" || node.inner_text == ""
            if id
              #stoas only need the - removed
              if id =~/stoa\d+[a-z]*-/
                id = id.gsub('-', '.') 
                break
              end
              #I hate that the ids aren't padded with 0s...            
              id_step = id.split(".").each_with_index {|x, i| i == 0 ? sprintf("%04d", x) : sprintf("%03d", x)}
              #add in tlgs or phis
              id = id_step.map {|x| "#{val}#{x}"}.to_s
              break 
            end
          end
        end
      end
      #if no id found throw an error   
      unless id
        puts "Have not found a suitable id, file will be moved to the error directory.\n"      
        @error_report << "For file #{f_n} : Could not find a suitable id, please check 
        that there is a tlg, phi, or stoa id or that, if a mads, the mads namespace is present.\n\n"
        `mv #{file_name} #{ENV['HOME']}/catalog_pending/errors/#{f_n}`
        return
      else
        return id
      end
    rescue
      puts "Encountered error #{$!}, file will be moved to the error directory.\n"
      @error_report << "For file #{f_n} : There was an error while trying to find an id, error message was #{$!}.\n\n"
      `mv #{file_name} #{ENV['HOME']}/catalog_pending/errors/#{f_n}`
    end
  end

  def add_row #put in cite_colls?

  end

end