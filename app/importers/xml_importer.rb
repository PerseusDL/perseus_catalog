#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class XmlImporter
  
  require 'new_import.rb'
  require 'parser.rb'


  def import(rec_file, file_type)
    begin
      auth_and_tg
      if File.directory?(rec_file)
        multi_import(rec_file, file_type)
      else
        single_import(rec_file, file_type)
      end
    rescue Exception => e
      puts "#{$!}\n #{e.backtrace}"
    end
  end

  def auth_and_tg
    begin
      tg = NewParser.new
      au = NewParser.new
      tg.textgroup_import
      au.author_import
    rescue Exception => e
      puts "#{$!}\n #{e.backtrace}"
    end
  end

  def single_import(file, file_type)
    raw_xml = File.read(file)
    puts file
    doc = Nokogiri::XML::Document.parse(raw_xml) 

    if file_type == "atom"
       
      puts "sending to atom parser"
      parser = NewParser.new
      parser.atom_parse(doc)       
    else
      puts "File type not recognized, check if in correct format: #{file}, #{file_type}, #{$!}"
    end
      puts "end import"
  end


  def multi_import(directory_path, file_type)
    d = Dir.new(directory_path)
    d.each do |file|
      if File.directory?("#{directory_path}/#{file}")  
          multi_import("#{directory_path}/#{file}", file_type) unless file =~ /\.|\.\.|CVS|Lit|mads/
      else
        if file_type == ("author" or "edtrans")
          single_import("#{directory_path}/#{file}", file_type) if file =~ /\.mads\.xml/
        elsif file_type == "error"
          single_import("#{directory_path}/#{file}", file_type) if file =~ /errors\.aae/
        else
          single_import("#{directory_path}/#{file}", file_type) if file =~ /\.xml|\.csv/
        end   
      end
    end
  end



end
