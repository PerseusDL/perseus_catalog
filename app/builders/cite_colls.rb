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


  def set_agent(a_alias = 'Mac Safari')
    @agent = Mechanize.new
    @agent.user_agent_alias= a_alias
    return @agent
  end


  def update_git_dir(dir_name)
    start_time = Time.now
    data_dir = "#{BASE_DIR}/#{dir_name}"
    unless File.directory?(data_dir)
      `git clone https://github.com/PerseusDL/#{dir_name}.git $HOME/#{dir_name}`
    end
    
    if File.mtime(data_dir) < start_time
      puts "Pulling the latest files from the #{dir_name} GitHub directory"
      `git --git-dir=#{data_dir}/.git --work-tree=#{data_dir} pull`
    end

  end


  def get_cite_rows(type, key, value)
    #returns array of xml response
    j_arr = query_cite_tables(type, key, value)
    #check for redirects
    j_arr.each_with_index do |row, i|
      redir = row['redirect_to']
      unless redir == nil || redir.empty?
        if j_arr.any? {|r| r['urn'] == redir}
          j_arr.delete_at(i)
        else
          new_j_arr = query_cite_tables(type, 'urn', redir)
          j_arr.concat(new_j_arr)
        end
      end
    end
    return j_arr
  end

  def query_cite_tables(type, key, value)
    cite_url = "http://catalog.perseus.org/cite-collections/api/#{type}/search?#{key}=#{value}&format=json"
    #cite_url = "http://localhost:3000/cite-collections/api/#{type}/search?#{key}=#{value}&format=json"
    response = @agent.get(cite_url).body
    j_arr = JSON.parse(response)
    return j_arr
  end

end