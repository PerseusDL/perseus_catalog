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
    ids_file = File.open('/Users/anna/hathi/new_ids')
    ids = ids_file.read
    id_arr = ids.split(",") #DOUBLE CHECK THIS IF GIVING NEW INPUT FILE!
    
    #create hash of hathi file
    #file is tab separated
    #0hathi_id ... 7oclc_id

    hathi_hash = {}
    count = 0
    File.foreach('/Users/anna/Downloads/viaf-20130417-links.txt').each do |line|
      debugger
      arr = line.split("\t")
      oclc_id = arr[7]
      hathi_id = arr[0]
      hathi_hash[oclc_id] = hathi_id
      count += 1
      puts "adding record #{count}"
    end
    puts "#{count} files from hathi trust will be searched"
   
    found_ids = []
    missing_ids = File.new('/Users/anna/hathi/still_missing_ids', 'w+')
    id_arr.each do |id|
      id_match = id.match(/\d+$/)
      if id_match
        clean_id = id_match[0]
        if hathi_hash.include?(clean_id)
          puts "Got a match for #{clean_id}"
          found_ids << "id=#{hathi_hash[clean_id]}"
        else
          puts "Can't find #{clean_id} in hathiTrust file"
          #more could potentially be done here to make it work
          missing_ids << "#{id}\n"
        end
      end
    end
    missing_ids.close

    hathi_ids = File.open('/Users/anna/hathi/new_hathi_ids', 'w')
    hathi_ids << found_ids.join(";")
    hathi_ids.close
    hathi_build('/Users/anna/hathi/new_hathi_ids')

    #still need to add those urls to the db
    #also, need to write it so it can import new hathi files, check for added volumes
    
  end



  def hathi_build(file)
    
    ids_file = File.open(file, 'r')
    found_ids = ids_file.read
    agent = Mechanize.new
    
    shib_page = agent.get('https://babel.hathitrust.org/Shibboleth.sso/tufts?target=http%3A%2F%2Fbabel.hathitrust.org')
    shib_form = shib_page.form_with(:name => 'login')
    shib_form['j_username']='supply'
    shib_form['j_password']='when using'
    log_step = shib_form.submit
    finally = log_step.forms.first.submit

    count = 0
    id_list = found_ids.split(';')
    id_list.each do |one|
      page = agent.get("https://babel.hathitrust.org/shcgi/mb?page=ajax;#{one};a=addits;c2=1465668663")
      puts page
      count += 1
      if count % 50 == 0
        sleep(120)
      end
    end
  end

  def oclc_id_find(file)
    #file is a \n separated list of the oclc urls of ids that weren't found in the Hathi quick method
    new_found = File.open("/Users/anna/hathi/new_ids", 'w')
    missing = File.open(file, 'r')
    missing_ids = missing.read
    agent = Mechanize.new
    
    missing_ids.each do |url|
      begin

        url = url.strip
        tufts_url = url.gsub(/\/www\.world|\/world/, "/tufts.world")
        page = agent.get(tufts_url).parser
        oclc_node = page.xpath("//tr[@id='details-oclcno']")
        num = oclc_node.children[2].inner_text.strip
        puts "found #{num}"
        new_found << "id=#{num};"
      rescue
        puts "Something went wrong for #{url}"
      end
    end
    
  end
end