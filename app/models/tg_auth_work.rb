#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class TgAuthWork < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  has_many :authors
  has_many :textgroups

  def self.find_row(auth_id, work_id, textgroup_id)
    found_row = TgAuthWork.find(:first, :conditions => ["tg_id=? and auth_id=? and work_id=?", textgroup_id, auth_id, work_id])
    return found_row
  end
end
