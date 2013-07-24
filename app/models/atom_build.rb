class AtomBuild
  require 'nokogiri'

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
    #Fusion tables API, 
    works_arr = find_works
    #iterate through works
    works_arr.each do |work|
      #find out if textgroup is in textgroup_collection
      textgroup = find_textgroup(tg_id)
      if textgroup

        #look at list returned from process_pending, iterate through that, looking for mods files
        find_mods(work, textgroup)
    end

  end


  def find_works
    #for now using googlefusion table
    #result = https://www.googleapis.com/fusiontables/v1/tables/1PQY6nVHZV8Ng42-qrbiLKXwDz9XoNlStKi3xKfU?alt=csv
    #process resulting csv into an array of arrays
    
    #return array of arrays
  end


  def find_textgroup (tg_id)
    #locates and matches textgroup id input
    #https://www.googleapis.com/fusiontables/v1/query?sql=SELECT * FROM 1I0Zkm1mAfydn6TfFEWH2h0D3boAd4q7zC-4vuUY WHERE textgroup="#{tg_id}"?alt=csv
    #returns row or nothing
  end


  def find_mods(work, textgroup)
    #locates and returns mods records in process_pending list matching work
    #iterate through list
      #look for work and textgroup ids in file
  end


  def process_mods
    #does the mods record have a urn?
    #if yes, search
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