class XmlImporter
  

  require 'parser.rb'


  def import(file, file_type)
    raw_xml = File.read(file)
    puts file
    doc = Nokogiri::XML::Document.parse(raw_xml) 

    if file_type == "atom"
      puts "sending to atom parser"
      Parser.atom_parse(doc)
    elsif file_type == "error"
      puts "sending to atom error parser"
      Parser.error_parse(raw_xml)
    elsif file_type == "author" || "edtrans"
      puts "sending to MADS parser"
      Parser.mads_parse(doc, file_type)
    else
      puts "File type not recognized, check if in correct format: #{file}, #{file_type}"
    end
      puts "end import"
  end


  def multi_import(directory_path, file_type)
    d = Dir.new(directory_path)
    d.each do |file|
      if File.directory?("#{directory_path}/#{file}")  
          multi_import("#{directory_path}/#{file}", file_type) unless file =~ /\.|\.\.|CVS/
      else
        if file_type == ("author" or "edtrans")
          import("#{directory_path}/#{file}", file_type) if file =~ /\.mads\.xml/
        elsif file_type == "error"
          import("#{directory_path}/#{file}", file_type) if file =~ /errors\.aae/
        else
          import("#{directory_path}/#{file}", file_type) if file =~ /\.xml/
        end   
      end
    end
  end



end
