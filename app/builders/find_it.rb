class FindIt
  require 'find'
  def process_csv
    vers_csv = File.read("/Users/ada/test_csv.csv").split("\n")
    @final_arr = []
    vers_csv.each do |row|
      #byebug if row[/urn:cts:greekLit:tlg0003\.tlg001\.opp-grc40/]
        row_arr = row.split(/","/)
        cite = row_arr[0].gsub('"', '')

        version = row_arr[1]
        desc = row_arr[3]
        compare(vers_csv, cite, version, desc)
      
    end
    found = File.new("/Users/ada/test_found.csv", 'w')
    found << @final_arr.join("\n")
    found.close
  end

  def compare(vers_csv, cite, ver, des)
    vers_csv.each do |row|
      unless ver == "version"        
        row_arr = row.split(/","/)
        version = row_arr[1]
        desc = row_arr[3]
        if ver == version
          next
        else
          if des == desc
            if ver.match(/(^.+?)\d{1,3}$/)[1] == version.match(/(^.+?)\d{1,3}$/)[1]
              @final_arr << row unless @final_arr.include?(row)
            end
          end
        end
      end
    end
  end

  def compare_db_mods
    missing_mods = File.open("#{ENV['HOME']}/missing_mods.txt", "w")
    mods_dir = "#{ENV['HOME']}/catalog_data/mods"
    Find.find(mods_dir) do |path|
      if path =~ /\.xml/
        urn = path[/\w+\.\w+\.\w+-\w+/]
        res = Expression.find(:all, :conditions => ["cts_urn rlike ?", urn])
        unless res
          missing_mods << "Missing urn in db, #{urn}\n\n"
        else
          if res.length > 1
            missing_mods << "Urn #{urn} appears more than once in db?"
          end
        end
      end
    end 
    missing_mods.close    
  end
end

