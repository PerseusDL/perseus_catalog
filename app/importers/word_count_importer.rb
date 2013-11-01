#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class WordCountImporter
  require 'mysql2'
  require 'word_count.rb'
  require 'author.rb'

  def import_csv(file, type)
    begin
      raw_text = File.read(file)
      raw_arr = raw_text.split("\r")
      #dump into word_counts table, colums are:
      #0id 1authid 2total_words 3words_done 4tufts_google 5harvard_mellon 6to_do
      
      raw_arr.each do |l|
        line = l.split(",")
        #0total 1NA 2NA 3id 4name 5done 6tufts google 7harvard mellon 8to do/OCR 9NA 10NA

        a_id = line[3]
        if type == "tlg"
          a_id = sprintf("%04d", a_id) if !(a_id =~ /\d{4}/)
          mads_id = "tlg#{a_id}"
        else
          puts "will write when we have something other than greek authors"
        end
        #find author in authors table
        if mads_id
          author = Author.find_by_mads_or_alt_ids(mads_id)
          unless author
            author = Author.new
            name = line[4].downcase!
            author.name = name.capitalize!
            author.mads_id = mads_id
            author.save
          end
          word_row = WordCount.new
          word_row.auth_id = author.id
          word_row.total_words = line[0]
          word_row.words_done = line[5]
          word_row.tufts_google = line[6]
          word_row.harvard_mellon = line[7]
          word_row.to_do = line[8]
          word_row.save
        else
          puts "Cannot create mads_id, so no row will be saved for this"
        end
      end
    rescue Exception => e
      puts "Something went wrong! #{$!}"
      puts e.backtrace
    end
  end

end