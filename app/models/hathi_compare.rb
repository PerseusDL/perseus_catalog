#compare items in Perseus to HathiTrust

class HathiCompare
	require 'hathi_importer.rb'
	require 'mysql2'

  def hathi_check
	#want to check how old the latest files we have are, import if more than a month old
    dir = "~/hathi"
    unless dir.exists?
         

  end
  #run import rake task

  #process the hathifiles one at a time, building them into hashes

    #compare the expressions table against the hash

      #if in the hash, save the expression in the hathi collection by hathi id, do in batches of 100

        #need hathi collection id, each expression's hathi id

      #if not in the hash, save expression cts_urn to a seperate "not there" list to be saved

end