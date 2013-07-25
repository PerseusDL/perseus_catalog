#Atom build rake tasks

desc "Build Atom feed"
task :build_atom_feed => :environment do
  @agent = Mechanize.new
  builder = AtomBuild.new
  builder.process_works
end