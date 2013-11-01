#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================

class AtomBuild
  require 'nokogiri'
  require 'mechanize'
  include CiteColls


 
  def update_git_dir(dir_name)
    start_time = Time.now
    data_dir = "#{ENV['HOME']}/#{dir_name}"
    unless File.directory?(data_dir)
      `git clone https://github.com/PerseusDL/#{dir_name}.git $HOME/#{dir_name}`
    end
    
    #if File.mtime(data_dir) < start_time
    #  puts "Pulling the latest files from the #{dir_name} GitHub directory"
    #  `git --git-dir=#{data_dir}/.git --work-tree=#{data_dir} pull`
    #end

  end


  def build_feeds
    begin  
      st = Time.now
      
      today_date = st.strftime("%Y%m%d")
      #pull most recent catalog_data files
      catalog_dir = "#{ENV['HOME']}/catalog_data"
      update_git_dir("catalog_data")


      #create the feed directory if it doesn't exist
      feed_directories = "#{ENV['HOME']}/FRBR.feeds.all.#{today_date}"
      unless File.directory?(feed_directories)
        Dir.mkdir(feed_directories)
        Dir.mkdir("#{feed_directories}/greekLit")
        Dir.mkdir("#{feed_directories}/latinLit")
      end

      @mads_directory = "#{feed_directories}/mads"
      unless File.directory?(@mads_directory)
        Dir.mkdir(@mads_directory)
      end

      error_file = File.new("#{feed_directories}/errors.txt", 'w')

      
      
      #step through works      
      works_xml = get_all_works
      works_xml.children.each do |work_tag|       
        cite_urn = work_tag.inner_text
        if cite_urn =~ /urn:cite:perseus:catwk\.\d+\.\d+/
          raw_obj = multi_get("#{cite_base}api?req=GetObject&urn=#{cite_urn}#{cite_key}")
          #puts raw_obj.search("reply")
          if raw_obj.search("citeProperty[@label='CTS Work URN']").empty?
            puts "Getting 500, sleep then retry"
            sleep 2
            redo
          end
          #pull out the urn we really care about
          @work_urn = raw_obj.search("citeProperty[@label='CTS Work URN']").inner_text
          @work_title = raw_obj.search("citeProperty[@label='Uniform Title (English)']").inner_text
          puts "Saved work #{@work_urn}"         
        else
          next
        end
        #grab all of the work info
        @tg_urn = @work_urn[/urn:cts:(latinLit|greekLit):\D+\d{4}([a-z])?/]
        @lit_type = @tg_urn[/(latinLit|greekLit)/]      
        @tg_id = @tg_urn[/(tlg|phi|stoa)\d{4}([a-z])?/]
        @tg_name = find_textgroup(@tg_urn)
        @work_id = @work_urn[/(tlg|phi|stoa|abo)(\d{3}|X\d{2,3}|\d{1,2})(x\d{2}|[a-z]*)?$/]
        @work_id = @work_urn[/stoa\d{4}$/] if @tg_id == "stoa0233a"

        tg_dir = "#{feed_directories}/#{@lit_type}/#{@tg_id}"
        unless File.directory?(tg_dir)
          #create the tg_feed and populate the header          
          make_dir_and_feed(tg_dir, "#{feed_directories}/#{@lit_type}", "textgroup")         
        end
        #open tg_feed for current state and make sure that the formatting will be nice
        tg_file = File.open("#{tg_dir}.atom.xml", 'r+')
        tg_xml = Nokogiri::XML::Document.parse(tg_file, &:noblanks)
        tg_file.close       
        tg_marker = find_node("//cts:textgroup", tg_xml)
        #add the work info to the tg_feed header
        tg_builder = add_work_node(tg_marker)

        #create the work_feed and open the file for proper formatting of info to be added
        work_dir = "#{tg_dir}/#{@work_id}"
        make_dir_and_feed(work_dir, feed_directories, "work")
        work_file = File.open("#{feed_directories}/#{@tg_id}.#{@work_id}.atom.xml", 'r+')
        work_xml = Nokogiri::XML::Document.parse(work_file, &:noblanks)
        work_file.close
        work_marker = find_node("//cts:textgroup", work_xml)
        work_builder = add_work_node(work_marker)



        #have to establish all mads info up here so the mads additions can be done at different stages depending on the feed type
        mads_cts_nodes = find_author(@tg_id)
        mads_num = 1
        @mads_arr =[]
        unless mads_cts_nodes.empty?
          mads_cts_nodes.children.each do |node|
            unless node.text? 
              mads_path  = node.xpath("cite:citeProperty[@label='MADS File']").inner_text
              mads_file = File.open("#{catalog_dir}/mads/#{mads_path}", "r")
              mads_xml = Nokogiri::XML::Document.parse(mads_file, &:noblanks)
              mads_file.close
              mads_urn = node.attribute("urn").value
              @mads_arr << [mads_urn, mads_num, mads_path, mads_xml]
              mads_num += 1
            end
          end
        end

        #grab all mods files for the current work and iterate through
        work_mods_dir = "#{catalog_dir}/mods/#{@lit_type}/#{@tg_id}/#{@work_id}"
        if File.directory?(work_mods_dir)
          entries_arr = Dir.entries("#{work_mods_dir}")
          entries_arr.each do |sub_dir|
            unless sub_dir == "." or sub_dir ==".." or sub_dir == ".DS_Store"
              
              mods_arr = Dir.entries("#{work_mods_dir}/#{sub_dir}")
              mods_arr.each do |m_f|   
         
                unless m_f == "." or m_f ==".." or m_f == ".DS_Store"
                  @ver_id = sub_dir
                  @ver_urn = "#{@work_urn}.#{@ver_id}"
                  orig_lang = lang_code_find
                  ver_type = @ver_id =~ /#{orig_lang}/ ? "edition" : "translation"
                  @mods_num = m_f[/mods\d+/] #need to add in a dash between the mods and the number
                  
                  #create ver_feed head
                  make_dir_and_feed(work_dir, work_dir, ver_type)
                  ver_file = File.open("#{work_dir}/#{@tg_id}.#{@work_id}.#{@ver_id}.atom.xml", 'r')
                  ver_xml = Nokogiri::XML::Document.parse(ver_file, &:noblanks)
                  ver_file.close
                  ver_marker = find_node("//cts:textgroup", ver_xml)
                  #add the work info to the ver_feed header
                  ver_builder = add_work_node(ver_marker)

                  #open the mods file once we have it
                  mods_file = File.open("#{work_mods_dir}/#{sub_dir}/#{m_f}", 'r+') if m_f =~ /\.xml/            
                  mods_xml = Nokogiri::XML::Document.parse(mods_file, &:noblanks)
                  mods_file.close
                  #if it is a perseus version, get the relevant info from the perseus_xml
                  if m_f =~ /perseus/ 
                    #open the perseus cts file
                    perseus_file = File.open("#{catalog_dir}/perseus/perseuscts.xml", 'r')
                    perseus_xml = Nokogiri::XML::Document.parse(perseus_file, &:noblanks)
                    perseus_file.close
                    #have to remove the namespaces or it is impossible to find anything with xpath
                    perseus_xml.remove_namespaces!
                    ed_node = perseus_xml.search("#{ver_type}[@urn='#{@ver_urn}']")
                  else
                    ed_node = nil
                  end
                  #TO DO: need to add a re assignment of @ver_urn if more than one mods for an ed?
                  label, description = create_label_desc (mods_xml)
                  
                  params = {
                    "docs" => [tg_builder, work_builder, ver_builder],
                    "label" => label,
                    "description" => description,
                    "lang" => orig_lang,
                    "type" =>ver_type,
                    "perseus_info" => ed_node
                  }
                  
                  add_ver_node(params)
                  
                  mods_head = build_mods_head(ver_type)
                  content = find_node("//atom:content", mods_head.doc)
                  content.add_child(mods_xml.root)
                  add_mods_node(params['docs'], mods_head)

                  ver_mads = build_mads_head(ver_builder)
                  add_mads_node(ver_builder, ver_mads)


                  ver_file = File.open("#{work_dir}/#{@tg_id}.#{@work_id}.#{@ver_id}.atom.xml", 'w')
                  ver_file << ver_builder.to_xml
                  ver_file.close
                end
              end
            end
          end

          #since the tg feed is opened and added to each don't want to do that multiple times
          unless has_mads?(tg_builder)
            tg_mads = build_mads_head(tg_builder)
            add_mads_node(tg_builder, tg_mads)
          end
          tg_file = File.open("#{feed_directories}/#{@lit_type}/#{@tg_id}.atom.xml", 'w')
          tg_file << tg_builder.to_xml
          tg_file.close

          work_mads = build_mads_head(work_builder)
          add_mads_node(work_builder, work_mads)
          work_file = File.open("#{feed_directories}/#{@tg_id}.#{@work_id}.atom.xml", 'w')
          work_file << work_builder.to_xml
          work_file.close
          
        end

      end
      puts "Feed build started at #{st}"
    rescue Mechanize::ResponseCodeError => e
      if e.response_code =~ /500|403/
        puts "500, retry in 2 seconds"
        sleep 2
        retry
      end
    
    rescue Exception => e
      puts "Something went wrong! #{$!} #{e.backtrace}"
      error_file << "#{$!}/n#{e.backtrace}/n/n"
    end

    puts "Feed build completed at #{Time.now}"
  end
        

  

  def xml_clean(nodes, sep = "")
    empty_test = nodes.class == "Nokogiri::XML::NodeSet" ? nodes.empty? : nodes.blank?
    unless empty_test
      cleaner = ""
      nodes.children.each do |x| 
        cleaner << x.inner_text + sep
      end
      clean = cleaner.gsub(/\s+#{sep}|\s{2, 5}/, " ").strip
      return clean
    else
      return ""
    end
  end


  def create_label_desc(mods_xml)
    ns = mods_xml.collect_namespaces
    if !mods_xml.search('/mods:mods/mods:relatedItem[@type="host"]/mods:titleInfo', ns).empty?
      raw_title = mods_xml.search('/mods:mods/mods:relatedItem[@type="host"]/mods:titleInfo', ns).first
    elsif !mods_xml.search('/mods:mods/mods:titleInfo[not(@type)]', ns).empty?
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[not(@type)]', ns).first
    elsif !mods_xml.search('/mods:mods/mods:titleInfo[@type="alternative"]', ns).empty?
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[@type="alternative"]', ns).first
    elsif !mods_xml.search('/mods:mods/mods:titleInfo[@type="translated"]', ns).empty?
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[@type="translated"]', ns).first
    else
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[@type="uniform"]', ns)                  
    end                

    
    label = "#{@work_title}, #{xml_clean(raw_title, ' ')}"

    #mods:name, mods:roleTerm.inner_text == "editor" or "translator"
    names = mods_xml.search('//mods:name', ns)
    ed_trans = ""
    author_n = ""
    names.each do |m_name|
      if m_name.inner_text =~ /editor|translator/
        ed_trans = xml_clean(m_name, ", ")
      elsif m_name.inner_text =~ /creator/
        author_n = xml_clean(m_name, ", ")
        author_n.gsub!(/,,/, ",")
      end
    end
    #pull out basic bibliographic info
    place = xml_clean(mods_xml.search('//mods:originInfo//mods:placeTerm[@type="text"]', ns), ",")
    pub = xml_clean(mods_xml.search('//mods:originInfo/mods:publisher', ns), ",")
    date = xml_clean(mods_xml.search('//mods:originInfo/mods:dateIssued', ns), ",")
    date_m = xml_clean(mods_xml.search('//mods:originInfo/mods:dateModified', ns), ",")
    edition = xml_clean(mods_xml.search('//mods:originInfo/mods:edition', ns))
    
    origin = "#{place} #{pub} #{date} #{date_m} #{edition}"
    origin.gsub!(/,\s{2, 5}|,\s+$/, " ")
    
    description = "#{author_n}. #{ed_trans}. #{origin}."
    
    return label, description
  end


  def make_dir_and_feed(dir, dir_base, type)
    Dir.mkdir(dir) unless File.directory?(dir)
     
    #constructing textgroup feed head
    if type == "textgroup"
      atom_name = "#{dir_base}/#{@tg_id}.atom.xml"
    elsif type == "work"
      atom_name = "#{dir_base}/#{@tg_id}.#{@work_id}.atom.xml"
    else
      atom_name ="#{dir_base}/#{@tg_id}.#{@work_id}.#{@ver_id}.atom.xml"
    end 

    unless File.exists?(atom_name)  
      feed = build_feed_head(type)
      feed_file = File.new(atom_name, 'w')
      feed_file << feed.to_xml
      feed_file.close
    end
  end


  def find_node(n_xpath, xml_doc, urn = false)
    ns = xml_doc.collect_namespaces
    n_xpath = "#{n_xpath}[@urn='#{@work_urn}']" if urn
    target_node = xml_doc.xpath(n_xpath, ns).last
  end


  def lang_code_find
    #this will need extending once we add more than greek and latin original languages
    if @lit_type == "latinLit"
      lang_code = "lat"
    elsif @lit_type == "greekLit"
      lang_code = "grc"
    end
  end


#xml creation/manipulation methods

  def build_feed_head(feed_type)
    
    if feed_type =~ /textgroup/
      atom_id = "http://data.perseus.org/catalog/#{@tg_urn}/atom"
      atom_urn = @tg_urn
    elsif feed_type =~ /work/
      atom_id = "http://data.perseus.org/catalog/#{@work_urn}/atom"
      atom_urn = @work_urn
    else
      atom_id = "http://data.perseus.org/catalog/#{@ver_urn}/atom"
      atom_urn = @ver_urn
    end
     
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |a_feed|

      #the first section, before the actual text inventory begins is the same for all feed levels
      #only items that change are variables for ids/urls and basic text in the titles
      a_feed.feed('xmlns:atom' => 'http://www.w3.org/2005/Atom'){
        a_feed.parent.namespace = a_feed.parent.namespace_definitions.find{|ns|ns.prefix=="atom"}        
        a_feed['atom'].id_(atom_id)
        a_feed['atom'].author('Perseus Digital Library')
        a_feed['atom'].rights('This data is licensed under a Creative Commons Attribution-ShareAlike 3.0 United States License')
        a_feed['atom'].title("The Perseus Catalog: atom feed for CTS #{feed_type} #{atom_urn}") 
        a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => atom_id) 
        a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "http://catalog.perseus.org/catalog/#{atom_urn}")
        a_feed['atom'].updated(Time.now)
        a_feed['atom'].entry {
          a_feed['atom'].id_("#{atom_id}#ctsti")
          a_feed['atom'].author('Perseus Digital Library')
          a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => "#{atom_id}#ctsti")
          a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "http://catalog.perseus.org/catalog/#{atom_urn}")
          a_feed['atom'].title {
            a_feed.text( if feed_type =~ /textgroup|work/
              "The Perseus Catalog: Text Inventory for CTS #{feed_type} #{atom_urn}"
            else
              "The Perseus Catalog: Text Inventory excerpt for CTS #{feed_type} #{atom_urn}"
            end)
          }
          #Text inventory start
          a_feed['atom'].content(:type => 'text/xml') {
            a_feed.TextInventory('xmlns:cts' => "http://chs.harvard.edu/xmlns/cts/ti", :tiversion => "4.0") {
              a_feed.parent.namespace = a_feed.parent.namespace_definitions.find{|ns|ns.prefix=="cts"}
              a_feed.ctsnamespace('xmlns' => "http://chs.harvard.edu/xmlns/cts/ti", :abbr => "greekLit", :ns => "http://perseus.org/namespaces/cts/greekLit"){
                a_feed.descripton('xml:lang' => 'eng'){a_feed.text("Greek texts hosted by the Perseus Digital Library")}
              }

              a_feed.ctsnamespace('xmlns' => "http://chs.harvard.edu/xmlns/cts/ti", :abbr => "latinLit", :ns => "http://perseus.org/namespaces/cts/latinLit"){
                a_feed.descripton('xml:lang' => 'eng'){a_feed.text("Latin texts hosted by the Perseus Digital Library")}
              }

              a_feed.collection('xmlns' => 'http://chs.harvard.edu/xmlns/cts/ti', :id => 'Perseus:collection:Greco-Roman', :isdefault => 'yes'){
                a_feed.title('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Greek and Roman Materials')}
                a_feed.creator('xmlns' => 'http://purl.org/dc/elements/1.1/'){a_feed.text('The Perseus Digital Library')}
                a_feed.coverage('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Primary and secondary sources for the study of ancient Greece
      and Rome')}
                a_feed.descripton('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Primary and secondary sources for the study of ancient Greece
      and Rome')}
                a_feed.rights('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Licensed under a Creative Commons Attribution-ShareAlike 3.0 United States License')}
              }

              a_feed.collection('xmlns' => 'http://chs.harvard.edu/xmlns/cts/ti', :id => 'Perseus:collection:Greco-Roman-protected'){
                a_feed.title('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Greek and Roman Materials')}
                a_feed.creator('xmlns' => 'http://purl.org/dc/elements/1.1/'){a_feed.text('The Perseus Digital Library')}
                a_feed.coverage('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Primary and secondary sources for the study of ancient Greece
      and Rome')}
                a_feed.descripton('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Primary and secondary sources for the study of ancient Greece
      and Rome')}
                a_feed.rights('xmlns' => 'http://purl.org/dc/elements/1.1/', 'xml:lang' => 'eng'){a_feed.text('Content is under copyright.')}
              }
              #Textgroup name
              a_feed.textgroup(:urn => @tg_urn){
                a_feed.groupname('xmlns:cts' => "http://chs.harvard.edu/xmlns/cts/ti", 'xml:lang' => "eng"){
                  a_feed.text(@tg_name)
                }
              }
            }
          }
        }
      }
      
    end
    return builder    
  end


  def add_work_node(marker_node)
    lang_code = lang_code_find        
    builder = Nokogiri::XML::Builder.with(marker_node) do |feed|
      feed.work('xmlns:cts' => "http://chs.harvard.edu/xmlns/cts/ti", :urn => @work_urn, 'xml:lang' => "#{lang_code}"){
        feed.title('xmlns:cts' => "http://chs.harvard.edu/xmlns/cts/ti", 'xml:lang' => "#{lang_code}"){
          feed.text(@work_title)
        }
      }
    end
    return builder
  end


  def add_ver_node(params)
    #params hash: "docs" => [tg_builder, work_builder, ver_builder], "label" => label, "description" => description,
    #             "lang" => orig_lang, "type" =>ver_type, "perseus_info" => ed_node
    params["docs"].each do |doc|
      node = find_node("//cts:work", doc.doc, true)
      builder = Nokogiri::XML::Builder.with(node) do |feed|
        feed.send("#{params['type']}", "xmlns:cts" => "http://chs.harvard.edu/xmlns/cts/ti", 'urn' => @ver_urn){
          feed.label('xml:lang' => 'eng'){feed.text(params['label'])}
          feed.description('xml:lang' => 'eng'){feed.text(params['description'])}
        }
      end

      #have to add in the perseus_info if it exists, but only doing structure info
      #since I've found a lot of bad descriptions
      if params['perseus_info']
        online = params['perseus_info'].xpath('online')[0].clone
        member = params['perseus_info'].xpath('memberof')[0].clone
        ed = find_node("//cts:#{params['type']}", builder.doc)
        ed.add_child(online)
        ed.add_child(member)
      end
    end
  end


  def build_mods_head(type)
    atom_id = "http://data.perseus.org/catalog/#{@ver_urn}/atom#mods-#{@mods_num}"
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |a_feed|
      a_feed.feed('xmlns:atom' => 'http://www.w3.org/2005/Atom'){
        a_feed.parent.namespace = a_feed.parent.namespace_definitions.find{|ns|ns.prefix=="atom"}
        a_feed['atom'].entry{
          a_feed['atom'].id_(atom_id)
          a_feed['atom'].author('Perseus Digital Library')
          a_feed['atom'].title("MODS file for CTS #{type} #{@ver_urn}")
          a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => atom_id) 
          a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "http://catalog.perseus.org/catalog/#{@ver_urn}")
          a_feed['atom'].content(:type => 'text/xml')
        }
      }
    end
    return builder
  end


  def add_mods_node(builders, mods_head)
    builders.each do |builder|

      if has_mads?(builder)
        first_mads = builder.doc.xpath("//atom:link[@href='http://data.perseus.org/collections/#{@mads_arr[0][0]}']")
        right_entry = first_mads[0].parent
        right_entry.add_previous_sibling(find_node("//atom:entry", mods_head.doc).clone)
      else
        builder.doc.root.add_child(find_node("//atom:entry", mods_head.doc).clone)  
        
        #for some reason the mods prefix definition is removed when adding perseus records, have to add it back
        if @ver_id =~ /perseus/
          perseus_mods = find_node("//atom:entry/atom:content", builder.doc).child
          perseus_mods.add_namespace_definition('mods', 'http://www.loc.gov/mods/v3')
        end

      end
    end
  end


  def has_mads?(builder)
    builder.doc.inner_text =~ /The Perseus Catalog: MADS file/ ? true : false
  end

  #might eventually create atom feeds for the mads too
  def build_mads_head(builder)
    mads_heads = []
    @mads_arr.each do |arr|
      #@mads arr contains 0mads_urn, 1mads_num, 2mads_path, 3mads_xml
      atom_id_node = find_node("atom:feed/atom:id", builder.doc)
      if atom_id_node.inner_text =~ /#{@tg_urn}\/atom/
        type = "textgroup"
        atom_id = "http://data.perseus.org/catalog/#{@tg_urn}/atom#mads-#{arr[1]}"
        urn = @tg_urn
      else 
        type = "work"
        urn = @work_urn
        if atom_id_node.inner_text =~ /#{@work_urn}\/atom/
          atom_id = "http://data.perseus.org/catalog/#{@work_urn}/atom#mads-#{arr[1]}"
        else
          atom_id = "http://data.perseus.org/catalog/#{@ver_urn}/atom#mads-#{arr[1]}"
        end        
      end
      #the atom:links and some text below will probably change when we properly label our authors in the mysql database
      m_builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |a_feed|
        a_feed.feed('xmlns:atom' => 'http://www.w3.org/2005/Atom'){
          a_feed.parent.namespace = a_feed.parent.namespace_definitions.find{|ns|ns.prefix=="atom"}
          a_feed['atom'].entry{
            a_feed['atom'].id_(atom_id)
            a_feed['atom'].link(:type => "application/atom+xml", :rel => 'self', :href => atom_id)
            a_feed['atom'].link(:type => "text/xml", :rel => "alternate", :href => "http://data.perseus.org/collections/#{arr[0]}")
            a_feed['atom'].author('Perseus Digital Library')
            a_feed['atom'].title("The Perseus Catalog: MADS file for author of CTS #{type} #{urn}")
            a_feed['atom'].content(:type => 'text/xml')            
          }
        }
      end
      mads_heads << m_builder
    end
    return mads_heads
  end

  def add_mads_node(builder, mads_heads)
    mads_heads.each do |head|
      num = head.doc.xpath('//atom:id').inner_text[/\d+$/]
      arr = @mads_arr.rassoc(num.to_i)
      content = find_node("//atom:content", head.doc)
      content.add_child(arr[3].clone.root)
      
      #make a mads atom file
      id = arr[0][/author.\d+.\d/]
      unless File.exists?("#{@mads_directory}/#{id}.atom.xml")
        mads_atom = File.new("#{@mads_directory}/#{id}.atom.xml", 'w')
        mads_atom << head.doc.clone
        mads_atom.close
      end

      builder.doc.root.add_child(find_node("//atom:entry", head.doc).clone)
    end
  end

end