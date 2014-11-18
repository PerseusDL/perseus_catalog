#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class Author < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  has_many :atom_errors

  def self.find_by_name_or_alt_name(name)
    found_name = Author.find_by_name(name) || Author.find_by_alt_names(name)
  end

  def self.find_by_major_ids(id)
    found_id = Author.find(:all, :conditions => ["? in (phi_id, tlg_id, stoa_id)", id])    
    found_id = Author.find(:all, :conditions => ["alt_id rlike ?", id]) if found_id.empty?
    return found_id
  end

  def self.find_all_potential_authors(id)
    found_id = []
    found_id << Author.find_by_major_ids(id)    
    found_id << Author.find(:all, :conditions => ["related_works rlike ?", id]) 
    return found_id
  end

  def self.get_info(id)
    doc = Author.find_by_unique_id(id)
    return doc
  end

  def self.new_auth(a, stub=false)
    auth = Author.new
    auth.unique_id = a['urn']
      
    if stub == true
      #take info from tg cite table for stub authors with no mads
      if @auth_cts
        cts_id = @auth_cts
      else
        cts_id = ""
      end
      auth_name = a['groupname_eng']
    else
      #author with mads
      if a['canonical_id'] && a['canonical_id'] != ""
        cts_id = a['canonical_id']
      else
        cts_id = ""
      end
      auth.alt_id = a['alt_ids']
      auth_name = a['authority_name']
    end

    #cts id placement
    case
    when cts_id =~ /phi/
      auth.phi = cts_id
    when cts_id =~ /tlg/
      auth.tlg = cts_id 
    when cts_id =~ /stoa/
      auth.stoa = cts_id 
    else
      auth.alt_id = auth.alt_id ? "#{auth.alt_id};#{cts_id}" : "#{cts_id}"
    end

    auth.name = auth_name

    return auth
  end
end
