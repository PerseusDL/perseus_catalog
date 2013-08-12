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
    start_time = Time.now
    pending_dir = "#{ENV['HOME']}/catalog_pending"
    #go through both mads and mods directories in catalog_pending
    #need a chron job to update catalog_pending from github?
    #what are we going to save the info in these as?
    unless File.directory?(pending_dir)
      `git clone https://github.com/PerseusDL/catalog_pending.git $HOME/catalog_pending`
    end

    if File.mtime(pending_dir) < start_time
      puts "Pulling the latest files from the catalog_pending GitHub directory"
      `git --git-dir=#{pending_dir}/.git pull`
    end
    
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


  def find_textgroup (tg_id)
    #locates and matches textgroup id input
    tg_raw = @agent.get("http://sosol.perseus.tufts.edu/testcoll/list?withXslt=citequery.xsl&coll=urn:cite:perseus:cattg&prop=textgroup&textgroup=#{tg_id}")
    #for some strange reason, can't use search method on a cite query page to pull out the tg_urn....
    noko_tg = tg_raw.search("reply")
    unless noko_tg.empty?
      tg_name = noko_tg.children.xpath("cite:citeProperty[@label='Groupname (English)']").inner_text
    else
      tg_name = nil
    end
    return tg_name
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


  def build_feeds
    
    st = Time.now
    today_date = st.strftime("%Y%m%d")
    feed_directories = "#{ENV['HOME']}/FRBR.feeds.all.#{today_date}"

    unless File.directory?(feed_directories)
      Dir.mkdir(feed_directories)
      Dir.mkdir("#{feed_directories}/greekLit")
      Dir.mkdir("#{feed_directories}/latinLit")
    end

    #step through works
    
    works_xml = find_works
    #iterate through urn list
    works_xml.children.each do |work_tag|
      
      work_info = []
      cite_urn = work_tag.inner_text
      unless cite_urn == "\n"
        raw_obj = @agent.get("#{cite_base}api?req=GetObject&urn=#{cite_urn}")
        #pull out the urn we really care about
        work_urn = raw_obj.search("citeProperty[@label='CTS Work URN']").inner_text
        work_title = raw_obj.search("citeProperty[@label='Uniform Title (English)']").inner_text
        puts "Saved work #{work_urn}"
        work_info << work_urn
      else
        next
      end

      work_id = work_urn[/(tlg|phi|stoa)\d{3}(x\d{2})?$/]
      tg_urn = work_urn[/urn:cts:(latinLit|greekLit):\D+\d{4}/]
      lit_type = tg_urn[/(latinLit|greekLit)/]
      tg_id = tg_urn[/(tlg|phi|stoa)\d{4}/]
      tg_name = find_textgroup(tg_urn)
      
      tg_dir = "#{feed_directories}/#{lit_type}/#{tg_id}"
        
      Dir.mkdir(tg_dir) unless File.directory?(tg_dir)
     
    #might want to create an args [], feed in the work_id and such and get rid of the XML merge here
      unless File.exists?("#{tg_dir}/#{tg_id}.atom.xml")  
        tg_feed = feed_head('textgroup', tg_urn)
        ns = tg_feed.doc.collect_namespaces
        node = tg_feed.doc.xpath('//cts:TextInventory', ns).first
        addition = Nokogiri::XML::Builder.with(node) do |xml|
          xml.textgroup(:urn => tg_urn){
            xml.groupname('xmlns:cts' => "http://chs.harvard.edu/xmlns/cts/ti", 'xml:lang' => "eng"){
              xml.parent.namespace = xml.parent.namespace_definitions.find{|ns|ns.prefix=="cts"}
              xml.text(tg_name)
            }
          }
        end
        
        tg_feed = addition.to_xml
        tg_file = File.new("#{tg_dir}/#{tg_id}.atom.xml", 'w')
        tg_file << tg_feed
        tg_file.close
      end
      #from here need to go into the work info and iterate through the mods files
      #create a work feed file
      #create mods feed files
      #create info for mads files
      #add info from each mods file to the work feed
      #add info from work feed file to the textgroup feed 
      tg_file = File.open("#{tg_dir}/#{tg_id}.atom.xml", 'r+')
      tg_xml = Nokogiri::XML::Document.parse(tg_xml)

      work_dir = "#{tg_dir}/#{work_id}"
      Dir.mkdir(work_dir) unless File.directory?(work_dir)




      #Does the TG directory exist in the atom feed file system? and is there a TG feed file?
        #if no, create TG labeled directory and create TG feed file

      #does the work level directory exist?
        #if no, create directory
      #find and iterate through mods files in catalog_source

      #Title Phrases
        #atom feed for CTS [work, textgroup, edition, translation] [ctsurn]
        #Text Inventory for CTS [work, textgroup] [ctsurn]
        #MODS file for CTS version [ctsurn]
        #Text Inventory excerpt for CTS [edition, translation] [ctsurn]
        #MADS file for author [of CTS work, in CTS textgroup] [ctsurn]
      
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
      #save the various feeds in their proper files
      puts "testing testing"
      
    end
  end


  def feed_head(feed_type, urn)
    atom_id = "http://data.perseus.org/catalog/#{urn}/atom"
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |a_feed|

      #the first section, before the actual text inventory begins is the same for all feed levels
      #only items that change are variables for ids/urls and basic text in the titles
      a_feed.feed('xmlns:atom' => 'http://www.w3.org/2005/Atom'){
        a_feed.parent.namespace = a_feed.parent.namespace_definitions.find{|ns|ns.prefix=="atom"}        
        a_feed['atom'].id_(atom_id)
        a_feed['atom'].author('Perseus Digital Library')
        a_feed['atom'].rights('This data is licensed under a Creative Commons Attribution-ShareAlike 3.0 United States License')
        a_feed['atom'].title("The Perseus Catalog: atom feed for CTS #{feed_type} #{urn}") 
        a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => atom_id) 
        a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "http://catalog.perseus.org/catalog/#{urn}")
        a_feed['atom'].updated(Time.now)
        a_feed['atom'].entry {
          a_feed['atom'].id_("#{atom_id}#ctsti")
          a_feed['atom'].author('Perseus Digital Library')
          a_feed['atom'].link(:type => 'application/atom+xml', :rel => 'self', :href => "#{atom_id}#ctsti")
          a_feed['atom'].link(:type => 'text/html', :rel => 'alternate', :href => "http://catalog.perseus.org/catalog/#{urn}")
          a_feed['atom'].title {
            a_feed.text( if feed_type =~ /work|textgroup/
              "The Perseus Catalog: Text Inventory for CTS #{feed_type} #{urn}"
            else
              "The Perseus Catalog: Text Inventory excerpt for CTS #{feed_type} #{urn}"
            end)
          }
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
            }
          }
        }
      }
      
    end
    return builder
    
  end

end