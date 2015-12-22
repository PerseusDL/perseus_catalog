# Pseudo catalog update script
# needs to be made fully automatable

# Prerequisite: Setup via catalog-update.setup.sh

# 0. REFRESH LOCAL COPY OF THE CITE COLLECTIONS MYSQL DB!!!!
# TODO -- if we aren't running against the live cite collections db
# which isn't likely since it's behind a Tufts Firewall, then
# we need to dump the live db and lock it down for updates
# before doing the import.  this is a serious flaw in the process...

# 1. UPDATE LOCAL GIT REPOS

cd ~/catalog_pending
git checkout master
git pull

cd ~/catalog_data
git checkout master
git pull

# 2. IMPORT/UPDATE CITE_COLLECTION DATA FROM GIT REPOS
cd ~/cite_collections_rails

rake catalog_pending_import


# 3. BUILD ATOM FEEDS
# IF FULL LOAD OF DATA THEN
rake build_atom_feed type="all"
# THIS ONLY LOADS CHANGES FROM THE LAST WEEK
rake build_atom_feed type="latest"

# 4. IMPORT ATOM FEEDS
cd ~/perseus_catalog
# TODO - I believe we need to drop the data base and start from scratch
# otherwise things like redirected versions will remain in the db
bundle exec rake parse_records file_type='atom' rec_file='/home/ubuntu/FRBR.feeds.YYYYMMDD'


# 5. Load word counts??

bundle exec rake word_count 

# 5. IMPORT DATA TO SOLR
curl http://localhost:8080/solr-4.5.1/db/dataimport?command=full-import&clean=false

# 6. DEPLOY TO PRODUCTION
# dump mysql
# reload on catalog0.perseus.tufts.edu
# rerun solr import on catalog0.perseus.tufts.edu
# deploy atom feeds


