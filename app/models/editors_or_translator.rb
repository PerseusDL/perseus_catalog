#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class EditorsOrTranslator < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works

  def self.find_by_name_or_alt_name(name)
    found_name = EditorsOrTranslator.find_by_name(name) || EditorsOrTranslator.find_by_alt_names(name)
  end
end
