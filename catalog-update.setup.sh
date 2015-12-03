# Pseudo install script for Catalog Build Environment
# should be turned into a vagrant or docker file

# Prerequisite: Ubuntu 14.04

# 1. INSTALL DEPENDENCIES
apt-get update
apt-get install git

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source /home/ubuntu/.rvm/scripts/rvm
rvm install ruby-2.0
apt-get install tomcat6
apt-get install mysql-server
gem install rails
gem install bundler
gem install extelib
gem install extlib
gem install autoparse
gem install byebug -v 2.3.1
gem install multipart-post -v 1.2.0
gem install faraday -v 0.8.8
gem install faraday -v 0.8.8
gem install jwt -v 0.1.8
gem install launchy -v 2.4.2
gem install signet -v 0.4.5
gem install uuidtools -v 2.1.4
gem install google-api-client -v 0.6.4
gem install mysql
gem install ruby-mysql

# 2. CLONE REPOS
git clone https://github.com/PerseusDL/cite_collection_rails
git clone https://github.com/PerseusDL/cite_collections_rails
git clone https://github.com/PerseusDL/catalog_pending
git clone https://github.com/PerseusDL/catalog_data

# 3. CONFIGURE CITE COLLECTIONS APP
cd ~/cite_collections_rails
bundle install
cd config
cp database.yml.sample database.yml
# INTERACTIVE: configure database.yml
cp config.yml.sample config.yml
# INTERACTIVE: configure config.yml


# 4. MAKE LOG DIR
mkdir ~/catalog_errors

# 5. update procedure

cd cite_collections_rails
rake catalog_pending_import type="all" [ first load ]
rake catalog_pending_import type="latest" [ subsequent ]


cd perseus_catalog
bundle exec rake parse_records file_type='atom' rec_file='/home/ubuntu/FRBR.feeds.20150608'

#TO TEST
curl http://localhost:8080/solr-4.5.1/db/dataimport?command=full-import&clean=false

# dump mysql
# reload on catalog0.perseus.tufts.edu
# rerun solr import on catalog0.perseus.tufts.edu
# atom feeds


