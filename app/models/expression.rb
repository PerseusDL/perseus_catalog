#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class Expression < ActiveRecord::Base
  attr_accessible :abbr_title
  belongs_to :work

  belongs_to :editors_or_translator

  belongs_to :series

  has_many :expression_url

  def self.get_info(id)
    doc = Expression.find_by_cts_urn(id)
    return doc
  end



end
