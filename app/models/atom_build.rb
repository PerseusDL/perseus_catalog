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



  def cite_base
    cite_url = "http://sosol.perseus.tufts.edu/testcoll/"
    return cite_url
  end

  def set_agent
    @agent = Mechanize.new
  end

  def process_pending
    debugger
    pending_dir = "#{ENV['HOME']}/catalog_pending"
    update_git_dir("catalog_pending")
    #go through both mads and mods directories in catalog_pending
    #need a chron job to update catalog_pending from github?
    #what are we going to save the info in these as?
    
    #after the pull, iterate through files
      #check if processed or have error tag, 
        #if yes, skip
        #else add file name to list
    #return list of files, array?

  end


  def process_works

    #using CITE works_collection
    works_xml = find_works
    #iterate through urn list
    works_xml.each do |work_urn|

        tg_id = work_urn[/urn:cts:(latinLit|greekLit):\D+\d{4}/]
        #find out if textgroup is in textgroup_collection
        
        if find_textgroup(tg_id)

          #look at list returned from process_pending, iterate through that, looking for mods files
          find_mods(work_urn, tg_id)
        end
      
    end

  end


  def find_works
    puts "processing Works CITE collection"
    
    #CITE collection   
    result = @agent.get("#{cite_base}api?req=GetValidReff&urn=urn:cite:perseus:catwk")
    #'result' will be a Mechanize::XML document which is based upon Nokogiri::XML::Document
    #before returning we have to dig to get to the level we want, namely the result, get a nokogiri NodeSet
    works_list = result.search("reply")
   
    return works_list
  end


  def find_textgroup
    #locates and matches textgroup urn input
    tg_raw = @agent.get("http://sosol.perseus.tufts.edu/testcoll/list?withXslt=citequery.xsl&coll=urn:cite:perseus:cattg&prop=textgroup&textgroup=#{@tg_urn}")
    #for some strange reason, can't use search method on a cite query page to pull out the tg_urn....
    noko_tg = tg_raw.search("reply")
    unless noko_tg.empty?
      tg_name = noko_tg.children.xpath("cite:citeProperty[@label='Groupname (English)']").inner_text
    else
      tg_name = nil
    end
    return tg_name
  end


  def find_author
    auth_raw = @agent.get("http://sosol.perseus.tufts.edu/testcoll/list?withXslt=citequery.xsl&coll=urn:cite:perseus:primauth&prop=textgroup&textgroup=#{@tg_urn}")
  end


  def find_mods(work, textgroup)
    #locates and returns mods records in process_pending list matching work
    #iterate through list
      #look for work and textgroup ids in file
  end


  def process_mods
    #does the mods record have a urn?
    #if yes, search the catalog_data for it

    #make processed tag, use mods:extension tag?
  end


  def update_git_dir(dir_name)
    start_time = Time.now
    data_dir = "#{ENV['HOME']}/#{dir_name}"
    unless File.directory?(data_dir)
      `git clone https://github.com/PerseusDL/#{dir_name}.git $HOME/#{dir_name}`
    end
    
    if File.mtime(data_dir) < start_time
      puts "Pulling the latest files from the #{dir_name} GitHub directory"
      `git --git-dir=#{data_dir}/.git --work-tree=#{data_dir} pull`
    end

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
      error_file = File.new("#{feed_directories}.errors.txt", 'w')
      #step through works      
      works_xml = find_works
      works_xml.children.each do |work_tag|       
        cite_urn = work_tag.inner_text
        unless cite_urn == "\n"
          raw_obj = @agent.get("#{cite_base}api?req=GetObject&urn=#{cite_urn}")
          #pull out the urn we really care about
          @work_urn = raw_obj.search("citeProperty[@label='CTS Work URN']").inner_text
          @work_title = raw_obj.search("citeProperty[@label='Uniform Title (English)']").inner_text
          puts "Saved work #{@work_urn}"         
        else
          next
        end
        #grab all of the work info
        @tg_urn = @work_urn[/urn:cts:(latinLit|greekLit):\D+\d{4}/]
        @lit_type = @tg_urn[/(latinLit|greekLit)/]      
        @tg_id = @tg_urn[/(tlg|phi|stoa)\d{4}/]
        @tg_name = find_textgroup
        @work_id = @work_urn[/(tlg|phi|stoa)\d{3}(x\d{2})?$/]

        tg_dir = "#{feed_directories}/#{@lit_type}/#{@tg_id}"
        unless File.directory?(tg_dir)
          #create the tg_feed and populate the header          
          make_dir_and_feed(tg_dir, "#{feed_directories}/#{@lit_type}", "textgroup")         
        end
        #open tg_feed for current state and make sure that the formatting will be nice
        tg_file = File.open("#{tg_dir}.atom.xml", 'r+')
        tg_xml = Nokogiri::XML::Document.parse(tg_file, &:noblanks)       
        tg_marker = find_node("//cts:textgroup", tg_xml)
        #add the work info to the tg_feed header
        tg_builder = add_work_node(tg_marker)

        #create the work_feed and open the file for proper formatting of info to be added
        work_dir = "#{tg_dir}/#{@work_id}"
        make_dir_and_feed(work_dir, feed_directories, "work")
        work_file = File.open("#{feed_directories}/#{@tg_id}.#{@work_id}.atom.xml", 'r+')
        work_xml = Nokogiri::XML::Document.parse(work_file, &:noblanks)
        work_marker = find_node("//cts:textgroup", work_xml)
        work_builder = add_work_node(work_marker)

        #open the perseus cts file
        perseus_file = File.open("#{catalog_dir}/perseus/perseuscts.xml")
        perseus_xml = Nokogiri::XML::Document.parse(perseus_file, &:noblanks)
        #have to remove the namespaces or it is impossible to find anything with xpath
        perseus_xml.remove_namespaces!

        #grab all mods files for the current work and iterate through
        work_mods_dir = "#{catalog_dir}/mods/#{@lit_type}/#{@tg_id}/#{@work_id}"
        if File.directory?(work_mods_dir)
          entries_arr = Dir.entries("#{work_mods_dir}")
          entries_arr.each do |sub_dir|
            unless sub_dir == "." or sub_dir ==".." or sub_dir == ".DS_Store"
              @ver_id = sub_dir
              @ver_urn = "#{@work_urn}.#{@ver_id}"
              orig_lang = lang_code_find
              ver_type = @ver_id =~ /#{orig_lang}/ ? "edition" : "translation"
              
              #create ver_feed head
              make_dir_and_feed(work_dir, work_dir, ver_type)
              ver_file = File.open("#{work_dir}/#{@tg_id}.#{@work_id}.#{@ver_id}.atom.xml", 'r')
              ver_xml = Nokogiri::XML::Document.parse(ver_file, &:noblanks)
              ver_marker = find_node("//cts:textgroup", ver_xml)
              #add the work info to the ver_feed header
              ver_builder = add_work_node(ver_marker)
              
              mods_arr = Dir.entries("#{work_mods_dir}/#{sub_dir}")
              mods_arr.each do |m_f|               
                unless m_f == "." or m_f ==".." or m_f == ".DS_Store"
                  #open the mods file once we have it
                  mods_file = File.open("#{work_mods_dir}/#{sub_dir}/#{m_f}", 'r+') if m_f =~ /\.xml/
             
                  mods_xml = Nokogiri::XML::Document.parse(mods_file, &:noblanks)
                  #if it is a perseus version, get the relevant info from the perseus_xml
                  if m_f =~ /perseus/ 
                    ed_node = perseus_xml.search("edition[@urn='#{@work_urn}.#{sub_dir}']")
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
                  
                  tg_builder, work_builder, ver_builder = add_ver_node(params)
                  
                  mods_head = build_mods_head(ver_type)
                  content = find_node("//atom:content", mods_head.doc)
                  mods_entry = content.add_child(mods_xml.root)
                  params['docs'].each do |b|
                  
                    b.doc.root.add_child(find_node("//atom:entry", mods_head.doc).clone)
                  end
                  
                  ver_file = File.open("#{work_dir}/#{@tg_id}.#{@work_id}.#{@ver_id}.atom.xml", 'w')
                  ver_file << ver_builder.to_xml
                  ver_file.close
                  puts "testing"
                end
              end
            end
          end

          debugger
          tg_file = File.open("#{feed_directories}/#{@lit_type}/#{@tg_id}.atom.xml", 'w')
          tg_file << tg_builder.to_xml
          tg_file.close
          work_file = File.open("#{feed_directories}/#{@tg_id}.#{@work_id}.atom.xml", 'w')
          work_file << work_builder.to_xml
          work_file.close
          
        end


        #Title Phrases
          #atom feed for CTS [work, textgroup, edition, translation] [ctsurn]
          #Text Inventory for CTS [work, textgroup] [ctsurn]
          #MODS file for CTS version [ctsurn]
          #Text Inventory excerpt for CTS [edition, translation] [ctsurn]
          #MADS file for author [of CTS work, in CTS textgroup] [ctsurn]

                  #save the various feeds in their proper files
        puts "testing testing"
        
      end
    rescue Exception => e
      puts "Something went wrong! #{$!}"
      error_file << "#{$!}/n#{e.backtrace}"
    end
  end
        
=begin      

                  #this is where individualization of the various types of feeds starts to really happen
                  #text inventory listing
                  a_feed['cts'].textgroup(:urn => "") { #textgroup urn
                    #lots of info needs to be parsed from records for this bit
                  }
                

            #iterate through associated mods files 
            a_feed['atom'].entry{
              a_feed['atom'].id_(ctsurn)#needs additional elements
              a_feed['atom'].author('Perseus Digital Library')
              a_feed['atom'].title("MODS file for CTS version #{ctsurn}")
              a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => "") #needs constructed url
              a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "") #needs constructed url
              a_feed['atom'].content(:type => 'text/xml') {
                #insert mods file content
                #might require grabbing the first node of the mods file then setting its parent to be this content node
                #other option might be to create a distinctly named empty node then replace with the mods nodeset
                #something different for textgroups happens here
              }
            }

            #iterate through associated mads 
            a_feed['atom'].entry{
              a_feed['atom'].id_(ctsurn)#needs additional elements
              a_feed['atom'].author('Perseus Digital Library')
              a_feed['atom'].title("MADS file for author (of CTS work, in CTS textgroup) #{ctsurn}")#needs different ctsurn elements
              a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => "") #needs constructed url
              a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "") #needs constructed url
              a_feed['atom'].content(:type => 'text/xml') {
                #insert mads file content
              }
            }
          }
=end      

  

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
    if mods_xml.search('/mods:mods/mods:titleInfo[not(@type)]')
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[not(@type)]')
    elsif mods_xml.search('/mods:mods/mods:titleInfo[@type="alternative"]')
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[@type="alternative"]')
    elsif mods_xml.search('/mods:mods/mods:titleInfo[@type="translated"]')
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[@type="translated"]')
    else
      raw_title = mods_xml.search('/mods:mods/mods:titleInfo[@type="uniform"]')                  
    end                

    
    label = xml_clean(raw_title, " ")

    #mods:name, mods:roleTerm.inner_text == "editor" or "translator"
    names = mods_xml.search('//mods:name')
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
    place = xml_clean(mods_xml.search('//mods:originInfo//mods:placeTerm[@type="text"]'), ",")
    pub = xml_clean(mods_xml.search('//mods:originInfo/mods:publisher'), ",")
    date = xml_clean(mods_xml.search('//mods:originInfo/mods:dateIssued'), ",")
    date_m = xml_clean(mods_xml.search('//mods:originInfo/mods:dateModified'), ",")
    edition = xml_clean(mods_xml.search('//mods:originInfo/mods:edition'))
    
    origin = "#{place} #{pub} #{date} #{date_m} #{edition}"
    origin.gsub!(/,\s{2, 5}|,\s+$/, " ").strip!
    
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
    
    return_xml = []
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
      return_xml << builder 
    end
    return return_xml
  end



  def build_feed_head(feed_type)
    atom_id = "http://data.perseus.org/catalog/#{@tg_urn}/atom"
    if feed_type =~ /textgroup/
      atom_urn = @tg_urn
    elsif feed_type =~ /work/
      atom_urn = @work_urn
    else
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
            a_feed.text( if feed_type =~ /textgroup/
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

  def build_mods_head(type)
    atom_id = "http://data.perseus.org/catalog/#{@ver_urn}/atom#mods"
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

  def feed_ti_ed

  end

end