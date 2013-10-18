
class MadsComp
require 'nokogiri'
include CiteColls
  
  #takes a directory, iterates through the files within, throwing the contents into file
  def compile(dir, dest_xml)   
    dir_arr = Dir.entries("#{dir}")
    dir_arr.each do |sub_dir|
      unless sub_dir == "." or sub_dir ==".." or sub_dir == ".DS_Store"
        file_arr = Dir.entries("#{dir}/#{sub_dir}")
        file_arr.each do |f|
          unless f == "." or f ==".." or f == ".DS_Store"
            if f =~ /mads.xml/
              
              cont = File.open("#{dir}/#{sub_dir}/#{f}", 'r') 
              xml = Nokogiri::XML::Document.parse(cont)
              dest_xml.root.add_child(xml.root)
            end
          end
        end
      end
    end

  end

  def insert_cite_urns(file_name, sub_dir)
    # 1) look up each file in the authors CITE collection using the path and the mads_file field
    cite_auth = find_auth_by_path(sub_dir)
    mads_xml = Nokogiri::XML::Document.parse(File.open(file_name, 'r'), &:noblanks)
    ns = mads_xml.collect_namespaces
    urn = cite_auth.children.search('//cite:citeObject').attribute("urn").value
    # 2) do XML juju   
    if mads_xml.search('//mads:mads/mads:identifier[@type="citeurn"]', ns).empty?
      first_id = mads_xml.xpath("mads:mads/mads:identifier", ns).first
      new_node_string = "<mads:identifier type='citeurn'>#{urn}</mads:identifier>"
      new_node = first_id.parse(new_node_string.strip)
      first_id.add_previous_sibling(new_node)
      file = File.open(file_name, 'w')
      file << mads_xml.to_xml
      file.close
      puts "added id #{urn}"
    else
      puts "already has a citeurn, skipping"
    end
    # 3) ???
    # 4) Profit!
  end

  def file_find(dir)
    dir_arr = Dir.entries("#{dir}")
    dir_arr.each do |sub_dir|
      if File.directory?("#{dir}/#{sub_dir}")
        file_find("#{dir}/#{sub_dir}") unless sub_dir == "." or sub_dir ==".." or sub_dir == ".DS_Store"
      else
        if sub_dir =~ /mads.xml/
          full_path = "#{dir}/#{sub_dir}"
          insert_cite_urns(full_path, sub_dir)
        end
      end
    end
  end

end