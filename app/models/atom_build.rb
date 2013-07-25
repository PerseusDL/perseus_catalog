class AtomBuild
  require 'nokogiri'
  require 'mechanize'

  def cite_base
    cite_url = "http://sosol.perseus.tufts.edu/testcoll/"
    return cite_url
  end

  def process_pending
    #go through both mads and mods directories in catalog_pending
    #need a chron job to update catalog_pending from github?
    #what are we going to save the info in these as?

    #git fetch --dry-run, if anything other than nothing, pull, if nothing quit process, nothing to add to the feeds
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
    works_xml.children.each do |work_tag|
      cite_urn = work_tag.inner_text
      raw_obj = @agent.get("#{cite_base}api?req=GetObject&urn=#{cite_urn}")
      #pull out the urn we really care about
      work_urn = raw_obj.search("citeProperty[@label='CTS Work URN']").inner_text
      #cut off the end to get the textgroup id
      tg_id = work_urn[/urn:cts:(latinLit|greekLit):\D+\d{4}/]
      #find out if textgroup is in textgroup_collection
      textgroup = find_textgroup(tg_id)
      if textgroup

        #look at list returned from process_pending, iterate through that, looking for mods files
        find_mods(work, textgroup)
      end
    end

  end


  def find_works
    #CITE collection
    debugger
    
    result = @agent.get("#{cite_base}api?req=GetValidReff&urn=urn:cite:perseus:catwk")
    #'result' will be a Mechanize::XML document which is based upon Nokogiri::XML::Document
    #before returning we have to dig to get to the level we want, namely the result, get a nokogiri NodeSet
    works_list = result.search("result")
    
    return works_list
  end


  def find_textgroup (tg_id)
    #locates and matches textgroup id input
    tg = @agent.get("http://sosol.perseus.tufts.edu/testcoll/list?withXslt=citequery.xsl&coll=urn:cite:perseus:cattg&prop=textgroup&textgroup=#{tg_id}")
    #for some strange reason, can't use search method on a cite query page to pull out the tg_urn....
    #going to have to navigate via children 
    
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
    #can use atom_feed do |feed|


    #mods files just need to be wrapped in the appropriate atom:element tag
    #same for mads

    #need to build the text inventory lists, maybe that info is what can get pulled out of the process_mods?
    #also need textgroup info for that 

    #atom feed for author mads files?

  end

end