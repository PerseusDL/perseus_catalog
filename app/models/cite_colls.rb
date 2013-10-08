#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

module CiteColls
  require 'nokogiri'
  require 'mechanize'

  def cite_base(search = false)
    cite_url = "http://sosol.perseus.tufts.edu/testcoll/"
    if search
      cite_url = "#{cite_url}list?withXslt=citequery.xsl&coll=urn:cite:perseus:"
    end
    return cite_url
  end

  def set_agent(a_alias = 'Mac Safari')
    @agent = Mechanize.new
    @agent.user_agent_alias= a_alias
    return @agent
  end


  def multi_agents
    #this and agent_rotate is my tricky way to get around google fusion api's user limits...
    @agent_arr = []
    @agent_arr << set_agent
    @agent_arr << set_agent('Windows Mozilla')
    @agent_arr << set_agent('Linux Firefox')
    @agent_arr << set_agent('Mac Mozilla')
    @agent_arr << set_agent('Windows IE 9')
  end


  def multi_get(url)
    page = @agent_arr[0].get(url)
    new_first = @agent_arr.pop(1)
    @agent_arr = new_first.concat(@agent_arr)
    return page
  end


  def cite_key
    key = "&key=AIzaSyBdwnszqWzCMQfDZvevtjVz-2bQTmwzxN0"
  end

  def process_pending
    pending_dir = "#{ENV['HOME']}/catalog_pending"
    update_git_dir("catalog_pending")
    #go through both mads and mods directories in catalog_pending
    #need a chron job to update catalog_pending from github?
    #what are we going to save the info in these as?
    
    #after the pull, iterate through files
      #check if processed or have error tag, 
        #if yes, skip
        #else add file name to list
    #return list of files, array?

  end


  def process_works

    #using CITE works_collection
    works_xml = find_works
    #iterate through urn list
    works_xml.each do |work_urn|

        tg_id = work_urn[/urn:cts:(latinLit|greekLit):\D+\d{4}/]
        #find out if textgroup is in textgroup_collection
        
        if find_textgroup(tg_id)

          #look at list returned from process_pending, iterate through that, looking for mods files
          find_mods(work_urn, tg_id)
        end
      
    end

  end


  def get_all_works
    puts "processing Works CITE collection"
    
    #CITE collection 
    begin  
      result = multi_get("#{cite_base}api?req=GetValidReff&urn=urn:cite:perseus:catwk#{cite_key}")
    rescue Mechanize::ResponseCodeError => e
      if e.response_code =~ /500/
        puts "500, retry in 1 second"
        sleep 1
        retry
      end
    end
    #'result' will be a Mechanize::XML document which is based upon Nokogiri::XML::Document
    #before returning we have to dig to get to the level we want, namely the result, get a nokogiri NodeSet
    works_list = result.search("reply").children
   
    return works_list
  end


  def find_textgroup(tg_urn)
    #locates and matches textgroup urn input
    begin
      tg_raw = multi_get("#{cite_base(true)}cattg&prop=textgroup&textgroup=#{tg_urn}#{cite_key}")
      sleep 1
    rescue Mechanize::ResponseCodeError => e
      if e.response_code =~ /500/
        puts "500, retry in 1 second"
        retry
      end
    end
    #for some strange reason, can't use search method on a cite query page to pull out the tg_urn....
    noko_tg = tg_raw.search("reply")
    unless noko_tg.children.empty?
      tg_name = noko_tg.children.xpath("cite:citeProperty[@label='Groupname (English)']").inner_text
    else
      tg_name = nil
    end
    return tg_name
  end


  def find_author(tg_id)
    begin
      auth_raw = multi_get("#{cite_base(true)}primauth&prop=canonical_id&canonical_id=#{tg_id}#{cite_key}")
      noko_auth = auth_raw.search("reply")
      if noko_auth.children.empty?
        #serch alt ids
        auth_raw = multi_get("#{cite_base(true)}primauth&prop=alt_ids&alt_ids=#{tg_id}:CONTAINS#{cite_key}")
        noko_auth = auth_raw.search("reply")
      end

      unless noko_auth.children.empty?
        auth_cts = noko_auth
        #auth_mads = noko_auth.children.xpath("cite:citeProperty[@label='MADS File']")
        #will return a full or empty nodeset
        #also ideally I'd want to search on related_works, but none of them have that atm
      else
        auth_cts = []
      end
      return auth_cts
    rescue Mechanize::ResponseCodeError => e
      if e.response_code =~ /500/
        puts "500, retry in 1 second"
        sleep 1
        retry
      end
    end
  end


  def find_mods(work, textgroup)
    #locates and returns mods records in process_pending list matching work
    #iterate through list
      #look for work and textgroup ids in file
  end
end