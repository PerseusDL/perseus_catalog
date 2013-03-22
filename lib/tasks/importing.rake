#Rake tasks

desc "Parse xml formatted records"
task :parse_records => :environment do

  #supply the directory or file to be imported and a file_type description
  #accepted tags are 'atom', 'mods', 'author', 'edtrans'
  file_type = ENV["file_type"]
  rec_file = ENV["rec_file"]
  importer = XmlImporter.new

  begin
    if File.directory?(rec_file)
      importer.multi_import(rec_file, file_type)
    else
      importer.import(rec_file, file_type)
    end
  rescue
    puts "File or directory supplied does not exist, check the path and try again: #{rec_file}"
  end

  puts "test done"
end

desc "Hathifiles import"
task :hathifiles_import => :environment do
  #pull the latest metadata files from the HathiTrust
  importer = HathiImporter.new

end