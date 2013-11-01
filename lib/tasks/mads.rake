

desc "MADS compile"
task :compile_mads => :environment do
  directories = ENV["dirs"].split(",")
  unless File.exists?("/Users/ada/mads_test/mads_sample.xml")
    dest_xml = Nokogiri::XML('<root></root>')
  else
    dest_xml = Nokogiri::XML::Document.parse(File.open("/Users/ada/mads_test/mads_sample.xml", 'r'), &:noblanks)
  end
  comp = MadsComp.new
  directories.each do |dir|
    comp.compile(dir, dest_xml)
  end
  dest_file = File.open("/Users/ada/mads_test/mads_sample.xml", 'w')
  dest_file << dest_xml.to_xml
  dest_file.close
end

task :add_cite_urns => :environment do
  if ENV["dirs"]
    directories = ENV["dirs"].split(",")
  end
  comp = MadsComp.new
  comp.multi_agents
  directories.each do |dir|
    comp.file_find(dir)
  end
end