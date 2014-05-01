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
  require 'google/api_client'
  require 'google/api_client/client_secrets'


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



  def update_git_dir(dir_name)
    start_time = Time.now
    data_dir = "#{ENV['HOME']}/#{dir_name}"
    unless File.directory?(data_dir)
      `git clone https://github.com/PerseusDL/#{dir_name}.git $HOME/#{dir_name}`
    end
    
    if File.mtime(data_dir) < start_time
      puts "Pulling the latest files from the #{dir_name} GitHub directory"
      `git --git-dir=#{data_dir}/.git --work-tree=#{data_dir} pull`
    end

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

  def fusion_auth
    #if anyone else implements this:
    #for this to work, you will need to obtain the private key for the google dev service account
    
    @client=Google::APIClient.new(:application_name => 'autoImport', :application_version => '1.0.0')
    @ft = @client.discovered_api('fusiontables')
    path_to_key = "#{ENV['HOME']}/gkey/9aa4bd6b8f715613724b1e61d9c99a37f5d7722b-privatekey.p12"
    key = Google::APIClient::KeyUtils.load_from_pkcs12(path_to_key, 'notasecret')
    @client.authorization=Signet::OAuth2::Client.new(:token_credential_uri => 'https://accounts.google.com/o/oauth2/token', :audience => 'https://accounts.google.com/o/oauth2/token', :scope => 'https://www.googleapis.com/auth/fusiontables', :issuer => '202250365961-4r8cli9tm8dkaudk3rm6jl5ol3t9tcdt@developer.gserviceaccount.com', :signing_key => key)
    @client.authorization.fetch_access_token!
  end


  def cite_key
    key = "&key=AIzaSyDo63Clfa5Z9Mf1rw1uKdA-mNVADg49Oic"
  end

  def table_keys
    keys = {:Authors => "1JKDi1OHvxWoh1w38mnQfUDey2pB_nx3UnRITvcA", 
            :Textgroups => "1I0Zkm1mAfydn6TfFEWH2h0D3boAd4q7zC-4vuUY", 
            :Works => "1PQY6nVHZV8Ng42-qrbiLKXwDz9XoNlStKi3xKfU",
            :Versions => "1STn9raQzWZDeIC4f_LHuLDUPPW3BDkpFfyKrKtw"
            }
  end

  def cite_tables_backup 
    #backup the current cite tables and upload to github
    #maintain number of backups at 5
    update_git_dir("cite_collections")
    cite_dir = "#{ENV['HOME']}/cite_collections"
    cite_backups_dir = "#{cite_dir}/csv_backups"

    #0authors table, 1textgroups, 2works, 3versions
    t_ks = table_keys
    #grab the csv files of the tables
    t_ks.each_pair do |name, key|
      table_csv = @agent.get"https://www.google.com/fusiontables/exporttable?query=select+*+from+#{key}"
      saved_file = File.new("#{cite_backups_dir}/Perseus#{name}Collection_#{Date.today}.csv", "w")
      saved_file.close
    end

    #check that we only have the last 5 backups
    file_list = Dir.entries(cite_backups_dir).map {|e| File.join(cite_backups_dir, e)}.select {|f| File.file? f}.sort_by {|f| File.mtime f}
    if file_list.length >= 24
      to_delete = file_list.first(4)
      to_delete.each {|x| File.delete(x)}
    end 

    #push to git
    `git --git-dir=#{cite_dir}/.git --work-tree=#{cite_dir} commit -a -m "csv backups for #{Date.today}"`
    `git --git-dir=#{cite_dir}/.git --work-tree=#{cite_dir} push`
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

  #I could abstract these into a cts query method, but dealing with the urls is a little tricky, so not doing it right now
  def find_work(work_urn)
    begin
      work_raw = multi_get("#{cite_base(true)}catwk&prop=work&work=#{work_urn}#{cite_key}")
    rescue Mechanize::ResponseCodeError => e
      if e.response_code =~ /500/
        puts "500, retry in 1 second"
        retry
      end
    end
    
    noko_work = work_raw.search("reply")
    if noko_work.children.empty?
      #work not found, row needs to be added
      return []
    else
      return noko_work
    end
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
    noko_tg = tg_raw.search("reply")
    if noko_tg.children.empty?
      tg_cts = []
    else
      tg_cts = noko_tg.children
    end
    return tg_cts
  end

  def find_textgroup_name(tg_urn)
    tg_nodes = find_textgroup(tg_urn)
    unless tg_nodes.empty?
      tg_name = noko_tg.children.xpath("cite:citeProperty[@label='Groupname (English)']").inner_text
    else
      tg_name = nil
    end
    return tg_name
  end

  def find_author(tg_id)
    begin
      auth_raw = multi_get("#{cite_base(true)}author&prop=canonical_id&canonical_id=#{tg_id}#{cite_key}")
      noko_auth = auth_raw.search("reply")
      if noko_auth.children.empty?
        #serch alt ids
        auth_raw = multi_get("#{cite_base(true)}author&prop=alt_ids&alt_ids=#{tg_id}:CONTAINS#{cite_key}")
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

  def find_auth_by_path(mads_path)
    begin
      mads_path = mads_path[/\d+\.mads\.xml/] if mads_path =~ /\+/
      auth_raw = multi_get("#{cite_base(true)}author&prop=mads_file&mads_file=#{mads_path}:CONTAINS#{cite_key}")
      noko_auth = auth_raw.search("reply")
      unless noko_auth.children.empty?
        auth_cts = noko_auth
      else
        auth_cts = []
      end
      return auth_cts
    rescue Mechanize::ResponseCodeError => e
      if e.response_code =~ /500|403/
        puts "bad response, retry in 2 seconds"
        sleep 2
        retry
      end
    end
  end


  def find_vers_by_cts(table_key, cts_urn)
    query = "SELECT * FROM #{table_key} WHERE 'version' LIKE '#{cts_urn}'"
    response = @client.execute(:api_method => @ft.query.sql, :parameters => {:sql => query, :alt => "csv"})
    csv_res = response.body.split("\n")
  end

  def add_cite_row(table_key, columns, values)
    query = "INSERT INTO #{table_key} (#{columns}) VALUES (#{values})"
    response = @client.execute(:api_method => @ft.query.sql, :parameters => {:sql => query})
    res = response.body.split("\n")[7]
    if res
      row_id = res[/\d+/]
      it_worked = false
      times = 0
      while it_worked != true do
        if times == 10
          raise "Confirm insert has run too many times for row_id #{row_id}, terminating"
        end
        sleep 5
        it_worked = confirm_insert(table_key, values.split("'")[1], row_id)
        times += 1
      end
    end
  end

  def update_cite_row(table_key, col_val_pairs, row_id)
    query = "UPDATE #{table_key} SET #{col_val_pairs.join(', ')} WHERE ROWID = #{row_id}"
    response = @client.execute(:api_method => @ft.query.sql, :parameters => {:sql => query})
  end

  def generate_urn(table_key, code)
    query = "SELECT urn FROM #{table_key} ORDER BY urn DESC"
    response = @agent.get("https://www.googleapis.com/fusiontables/v1/query?sql=#{query}&alt=csv#{cite_key}")
    last_urn = response.body.split("\n")[1]
    unless last_urn
      new_urn = "urn:cite:perseus:#{code}.1.1"
    else
      new_urn = inc_urn(last_urn, code)
    end
  end

  def inc_urn(last_urn, code)
    count = last_urn.split(".")[1].to_i + 1
    new_urn = "urn:cite:perseus:#{code}.#{count.to_s}.1"
  end

  def confirm_insert(table_key, uri, row_id)
    found_id = get_row_id(table_key, uri)
    row_id == found_id
    #!! AAAAHHHHHHHH This works but other immediate info pulls don't
  end

  def get_row_id(table_key, urn)
    query ="SELECT ROWID FROM #{table_key} WHERE urn = '#{urn}'"
    response = @agent.get("https://www.googleapis.com/fusiontables/v1/query?sql=#{query}&alt=csv#{cite_key}")
    row_id = response.body.split("\n")[1]
  end

  def find_mods(work, textgroup)
    #locates and returns mods records in process_pending list matching work
    #iterate through list
      #look for work and textgroup ids in file
  end
end