#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================




class LexProcessor
  require 'nokogiri'
  require 'mechanize'
  require 'mysql2'
  require 'work.rb'
  require 'expression.rb'
  require 'expression_url.rb'

  #FUTURE CONSIDERATIONS as of 11/5/13:
    #X1-Actually replace the current n values with the urns, leaving intact what we can't do yet
    #2-Some bibl tags are wrong
    #3-Need to handle both if they don't have a cts urn, currently just skip them, what happens with line citations with these? Acceptable to include?
    #4-Need to handle the inscriptions and papyri that don't currently match up
    #5-Should try to parse not found abbreviations to full name (see scrape_abbr) then check against db to get urn
    #6-If there is no n in the bibl, need to parse what info there is
    #7-Take into account 'ib.' and just numbers (multiple instances of the word being referenced in the same work)
    #8-Give the cts urn to the level that we can with the info provided, so at least an author if it is a broad reference to say, how Homer uses this word throughout the works
    #9-Must anticipate and handle random numbers that seem to have no associated info


  def lex_process(file)
    
    lex_xml = Nokogiri::XML(open(file))
    lex_name = file[/lsj|ml|ls|lewis/]
    bibl_file = File.open("#{ENV['HOME']}/lexica/#{lex_name}#{Date.today}.txt", 'w')
    error_file = File.open("#{ENV['HOME']}/lexica/#{lex_name}bibl_errors#{Date.today}.txt", 'w')    

    #pull up the trismegistos db for finding papyri uris
    agent = Mechanize.new
    tm_page = agent.get("http://www.trismegistos.org/tm/publication_lookup.php")

    #find and iterate through bibl tags
    bibls = lex_xml.xpath('//bibl')
    bibls.each do |bib|
      begin
        
        uri = nil
        #at this point, want to identify the contents of the n attribute, if it exists
        n = bib.attribute("n")
        if n
          n_val = n.value

          #see if abbreviation or other non abo value
          unless n_val =~ /Perseus\:abo/   
            #for now we skip if it is ibid or a straight line/passage reference
            next if n_val =~ /ibid|^\d+$/       
            #if abbreviation find abo in Perseus list and modify the n_val
            success, n_val = perseus_abbr_find(n_val)
            unless success
              error_file << "Abbreviation #{n.value} not found in the Perseus abbreviation file\n\n"
              #should try to go in here and parse the abbreviation (see scrape_abbr) to full name then check against db
              next
            end
          end
          
          #if abo, parse/figure out that
          if n_val =~ /Perseus\:abo/            
            n_split = n_val.split(':')
            #save the line reference portion
            lines = n_split.drop(3) 
            #way too few abos in the db, should take apart to tlg/phi portion           
            n_part = n_split[2]
                       
            unless n_part.empty?
              #catch if any papyri references
              if n_part =~ /pap/
                
                #check against the trismegistos db to find out the standard uri
                #n_part in form like pap,BGU, need to also take into account the other part like 8:11
                name_abbr = n_part.split(",")
                #convert to lower case and insert spaces after periods
                pap_name = name_abbr[1].gsub(".", ". ").downcase.rstrip
                pap_node = nil
                #this is a pain
                tm_page.search("tr").each do |tr|
                  if tr.attribute("lo") && tr.attribute("lo").value =~ /#{pap_name}/
                    pap_node = tr
                    break
                  end
                end
                if pap_node 
                  href_val = pap_node.search("td/a")[0].attribute("onclick").value
                  #A PAIN
                  comma_split = href_val.split(',')
                  if comma_split.length == 2
                    publ_abbr = comma_split[0].split('"')[1]
                  else
                    comma_split.delete_at(comma_split.length - 1)
                    publ_abbr = comma_split.join(',').split('"')[1]
                  end
                  #getting volume and number info, only trying two cases, too much wrong/weird data to try much else
                  split_len = n_split.length
                  num = ""
                  vol = ""
                  if split_len == 4
                    num = n_split[3]
                  elsif split_len == 5
                    vol = n_split[3]
                    num = n_split[4]
                  end
                  
                  results = agent.get("http://www.trismegistos.org/tm/list_texref.php?publ_one=#{publ_abbr}&vol_one=#{vol}&nr_one=#{num}&extra_one=&submit_lookup=Search&sort1_field=vol&sort2_field=nr")
                  #look for results, if more than one, go with nothing, if nothing move on, else grab the tm number
                  if agent.page.search('//div[@id="content"]/p')[1].inner_text =~ /Total number of records found\: 1Records/
                    tm_full = results.body[/TM \d+/]
                    tm_number = tm_full[/\d+/]
                    uri = "http://www.trismegistos.org/text/#{tm_number}"
                  else
                    error_file << "Could not get results for #{n.value} from TM\n\n"                    
                  end

                end
                #this would be where we replace the uri, for now, put it in the bibl_file
                bibl_file << "Change #{n.value} to #{uri}\n\n"
                puts "Change #{n.value} to #{uri}"
                if uri
                  bib.attribute('n').value = uri
                end
              else

                #if not papyri, is tlg or phi (probably, need to double check this is true)
                split_n = n_part.split(",")
                stand_id = split_n[0]+split_n[1]+"."+split_n[0]+split_n[2]              
              
                urn = nil
                if stand_id
                  expressions = Expression.find(:all, :conditions => ["cts_urn rlike ? AND var_type = 'edition'", stand_id])              
                  expressions.each {|expr| urn = expr.cts_urn if expr.cts_urn =~ /perseus/}
                  #have to put the line/book references back onto the end of the urn, has some number of : to delineate
                  if urn
                    uri = urn + ":#{lines.join(':')}"
                    bibl_file << "Change #{n_part} to #{uri}\n\n"
                    puts "Change #{n.value} to #{uri}"
                    if uri
                      bib.attribute('n').value = uri
                    end
                  else
                    error_file << "No expression returned for #{stand_id}\n\n"
                    #in this case just provide the work urn?
                  end
                else
                  error_file << "Can not construct a standard id for #{n.value}\n\n"
                end
              end
            else
              #if empty something is wrong, make a note in error file and move on
              error_file << "Something is wrong for #{n.value}"
            end 
          else
            #still no abo, make a note in the error file and skip it, shouldn't ever hit this
            error_file << "Second check, abbreviation #{n.value} not found in the Perseus abbreviation file\n\n"
          end
        end

      rescue Exception => e
        puts "Something went wrong! #{$!}" 
        error_file << "#{$!}\n#{e.backtrace}\n\n"
      end
    end
    bibl_file.close
    error_file.close
    new_xml = File.open("#{ENV['HOME']}/lexica/#{lex_name}#{Date.today}.xml", 'w')
    new_xml << lex_xml
    new_xml.close
  end


  def scrape_abbr
    agent = Mechanize.new
    ls_file = File.open("#{ENV['HOME']}/lexica/ls_abbr.tsv", 'w')
    
    page = agent.get('http://latinlexicon.org/LNS_abbreviations.php')

    #0Auth abbr, 1Auth name, 2Work abbr, 3Work name

    #pattern of ul li (author), ul li (works)
    main_text = page.search('div/ul')
    main_text.each do |ul|
      
      lis = ul.xpath('li')
      lis.each do |li|
        auth_abbrs, auth_name = ls_node_list(li)
        auth_abbrs.each {|x| ls_file << "'#{x}'\t'#{auth_name}'\t\t\n"}

        work_lis = li.xpath('ul/li')
        work_lis.each do |w_li|
          work_abbrs, work_name = ls_node_list(w_li)
          auth_abbrs.each do |a_abbr|
            work_abbrs.each {|w_abbr| ls_file << "'#{a_abbr}'\t'#{auth_name}'\t'#{w_abbr}'\t'#{work_name}'\n"}
          end
        end
      end
    end
    ls_file.close

  end

  def ls_node_list(li)
    #'b' tag give the abbr
    abbr_nodes = li.xpath('b')
    unless abbr_nodes.empty?
      abbr_arr = []
      abbr_nodes.each {|x| abbr_arr << x.inner_text.split(/,$/)[0]}
    end

    #the next tag is the full name, following tags are additional information
    if li.children[1]
      unless li.children[1].inner_text =~ /\sor\s/
        raw_name = li.children[1].inner_text
      else
        raw_name = li.children[3] ? li.children[3].inner_text : ""
      end
      name = raw_name.strip.split(/(,|\.|;)$/)[0]
    else
      name = ""
    end
    return abbr_arr, name 
  end


  def perseus_abbr_find(n_val)

    spl = n_val.split(/\s/)
    abbr = ""
    #if anything but the first cell is "p." need to skip it since it is for page number, should also remove the p from citation
    spl.each do |x| 
      if x != "p." && x != "prol."
        abbr << "#{x} " if x =~ /[a-zA-Z]+\./
      end
    end
    abbr_list = File.open("#{ENV['HOME']}/lexica/abbreviations/perseus.abb",'r').read
    abbr_nice = abbr_list.split("\n")
    got_it = nil
    abbr_nice.each do |line|      
      if line.include?(abbr.rstrip)
        got_it = line
        if got_it =~ /in #{abbr.rstrip}| [a-zA-Z]+\. #{abbr.rstrip}/
          got_it = nil
          next
        else
          break
        end
      end
    end
    if got_it
      abo_match = got_it.match(/abo\:[a-z]+,[0-9]{4},[0-9]{3}/)
      if abo_match && abo_match[0]
        match = "Perseus:#{abo_match[0]}"
        to_remove = spl.index('p.')
        clean_spl = spl.delete(to_remove) if to_remove
        if clean_spl.length == 2
          #accounting for authors with no work name provided
          lines = spl.drop(1).join(':')
        else
          lines = spl.drop(2).join(':')
        end
        lines = lines.gsub('.', ":")
        return true, match + ":#{lines}"
      else
        return false, n_val
      end
    else
      return false, n_val
    end
  end


  def ls_abbr_find(n_val)
  end

end