#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class ExpressionUrl < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :expression

  def self.find_url_match(id, url)
    match = ExpressionUrl.find(:first, :conditions => {:exp_id => id, :url => url})
    return match
  end


  def self.expr_urls(expr_id, urls, host=false)
    unless urls.empty?
      urls.each do |url|
        url_row = ExpressionUrl.find_url_match(expr_id, url[1])
        unless url_row
          url_row = ExpressionUrl.new
        end
        url_row.exp_id = expr_id
        url_row.url = url[1]
        url_row.display_label = url[0]
        url_row.host_work = host
        url_row.save
      end
    end
  end
end
