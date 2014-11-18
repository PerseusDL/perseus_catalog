#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class Series < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :works
  
  def self.series_row(ser_title, ser_abb)
  #series name standardization
    case
      when (ser_title =~ /Teubner|Teubneriana/i || ser_abb =~ /Teubner/i)
        clean_title = "Bibliotheca Teubneriana"
      when (ser_title =~ /Loeb|LCL/i || ser_abb =~ /Loeb|LCL/i)
        clean_title = "Loeb Classical Library"
      when (ser_title =~ /Oxford|oxoniensis/i || ser_abb =~ /OCT/i)
        clean_title = "Oxford Classical Texts"
      when (ser_title =~ /Bohn/i)
        clean_title = "Bohn's Classical Library"
      else
        clean_title = ser_title.split(/,|\[|\(|;/)[0]
    end
    ser = Series.find_by_clean_title(clean_title)
    unless ser
      ser = Series.new
      ser.ser_title = ser_title
      ser.clean_title = clean_title
      ser.abbr_title = ser_abb if ser_abb
      ser.save
    end
    return ser
  end
end
