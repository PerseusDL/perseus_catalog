#download from HathiTrust

class HathiImporter
	require 'mechanize'

  def download_files
    agent = Mechanize.new
    page = agent.get "http://www.hathitrust.org/hathifiles"
  end

  def unzip_files

  end



end