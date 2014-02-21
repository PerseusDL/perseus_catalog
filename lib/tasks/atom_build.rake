#Copyright 2013 The Perseus Project, Tufts University, Medford MA
#This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
#published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#See http://www.gnu.org/licenses/.
#=============================================================================================


#Atom build rake tasks

desc "Build Atom feed"
task :build_atom_feed => :environment do
  builder = AtomBuild.new
  builder.multi_agents
  builder.build_feeds
  #builder.process_pending
  #builder.process_works
end


#Lexicon processing rake tasks

desc "Process a lexicon"
task :process_lex => :environment do
  file = ENV['lex_xml']
  processor = LexProcessor.new

  processor.lex_process(file)
end

desc "Screen scrape abbreviations"
task :scrape_abbr => :environment do
  processor = LexProcessor.new
  processor.scrape_abbr
end


desc "run_findit"
task :findit => :environment do 
  finder = FindIt.new
  finder.process_csv
end