#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class AuthorUrl < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.author_url_row(text, auth, node)
    text = text.strip
    if text =~ /orlabs\.oclc/
      url_end = text[/(lccn|np).+$/]
      text = "http://worldcat.org/wcidentities/#{url_end}"
      label = "Worldcat Identities"
    else
      url = AuthorUrl.find_by_url(text)
      unless url
        if node.attribute('displayLabel')
          label = node.attribute('displayLabel').value
        else
          case 
          when text =~ /wikipedia/
            label = "Wikipedia"
          when text =~ /viaf/
            label = "VIAF"
          when text =~ /quod\.lib\.umich/
            label = "Smith's Dictionary"
          when text =~ /id\.loc\.gov/
            label = "ID.gov"
          else
            label = text
          end  
        end
        url = AuthorUrl.new
        url.url = text
        url.author_id = auth.id
        url.display_label = label
        url.save
      end
    end
  end
end
