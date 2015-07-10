#Rake tasks

desc "Parse xml formatted records"
task :parse_records => :environment do

  #supply the directory or file to be imported and a file_type description
  #accepted tags are 'atom', 'error', 'author', 'edtrans'
  file_type = ENV["file_type"]
  rec_file = ENV["rec_file"]
  importer = XmlImporter.new
  begin
    importer.import(rec_file, file_type)
  rescue
    puts "File or directory supplied does not exist, check the path and try again: #{rec_file}"
  end

  puts "test done"
end

desc "Just author and textgroup import"
task :auth_tg_import => :environment do
  importer = XmlImporter.new
  importer.auth_and_tg
end

desc "Hathifiles import"
task :hathifiles_import => :environment do
  #pull the latest metadata files from the HathiTrust
  importer = HathiImporter.new

end

desc "quick Hathifiles import"
task :quick_hathifiles_import => :environment do
  #pull the latest metadata files from the HathiTrust
  importer = HathiCompare.new
  importer.hathi_quick
end

desc "Hathi collection building"
task :hathi_build => :environment do
  file = ENV["file"]
  importer = HathiCompare.new
  importer.hathi_build(file)
end

desc "Find oclc ids"
task :oclc_id_find => :environment do
  file = ENV['file']
  importer = HathiCompare.new
  importer.oclc_id_find(file)
end

desc "Word count import"
task :import_word_count => :environment do
  #use a csv of word counts to populate the word_counts table
  file = ENV["file"]
  file_type = ENV["type"]
  importer = WordCountImporter.new

  begin
    if File.exist?(file)
      importer.import_csv(file, file_type)
    end
  rescue
    puts "Something went wrong #{$!}" 
  end
end

desc "Word count calculate"
task :word_count => :environment do
  Browse.word_calc
  

end

desc "import records in catalog_pending"
task :catalog_pending_import => :environment do
  cpi = CatalogPendingImporter.new
  cpi.pending_mods_import
end

