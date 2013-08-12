#Atom build rake tasks

desc "Build Atom feed"
task :build_atom_feed => :environment do
  builder = AtomBuild.new
  builder.set_agent
  builder.build_feeds
  builder.process_pending
  builder.process_works
end