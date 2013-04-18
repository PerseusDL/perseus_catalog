#compare items in Perseus to HathiTrust

class HathiCompare
  require 'hathi_importer.rb'
  require 'mysql2'

  def hathi_check
  #want to check how old the latest files we have are, import if more than a month old
    dir = "~/hathi"
    unless dir.exists?

    end
  end
  #run import rake task

  #process the hathifiles one at a time, building them into hashes

    #compare the expressions table against the hash

      #if in the hash, save the expression in the hathi collection by hathi id, do in batches of 50
      #also, check if we have the hathi url, if not, add it to the table
        #need hathi collection id, each expression's hathi id

      #if not in the hash, save expression cts_urn to a seperate "not there" list to be saved


#this is not the best way to do it, but it does a quick and dirty comparison to create a list of hathi ids
#that you can then feed into the 
  def hathi_quick
    ids_file = File.open('/Users/anna/Documents/workspace/oclc_ids.csv')
    ids = ids_file.read
    id_arr = ids.split("\n")
    
    #create hash of hathi file
    #file is tab separated
    #0hathi_id ... 7oclc_id

    hathi_hash = {}
    count = 0
    File.foreach('/Users/anna/hathi/hathi_full_20130201.txt').each do |line|
      arr = line.split("\t")
      oclc_id = arr[7]
      hathi_id = arr[0]
      hathi_hash[oclc_id] = hathi_id
      count += 1
      puts "adding record #{count}"
    end
    puts "#{count} files from hathi trust will be searched"
    found_ids = []
    missing_ids = File.new('/Users/anna/hathi/missing_ids', 'w')
    id_arr.each do |id|
      if hathi_hash.include?(id)
        puts "Got a match for #{id}"
        found_ids << "id=#{hathi_hash[id]}"
      else
        puts "Can't find #{id} in hathiTrust file"
        #more could potentially be done here to make it work
        missing_ids << "#{id}\n"
      end
    end
    missing_ids.close

    hathi_ids = File.new('/Users/anna/hathi/all_hathi_ids', 'w')
    hathi_ids << found_ids.join(";")
    hathi_ids.close

    #adding to the colletion editor in HathiTrust
    #This doesn't work correctly....
    agent = Mechanize.new
    found_ids.each_slice(50) do |arr_chunk|
      list = arr_chunk.join(";")

      page = agent.get("https://babel.hathitrust.org/shcgi/mb?page=ajax;#{list}a=addits;c2=392719119")
    end  

    #still need to add those urls to the db, might split the hathidata files into parts, make the overall hash smaller
    #from there add in a search that adds urls to the db
    #also, need to write it so it can import new hathi files, check for added volumes
    
  end
end