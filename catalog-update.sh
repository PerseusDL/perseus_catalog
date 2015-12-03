# Pseudo catalog update script
# needs to be made fully automatable

# Prerequisite: Setup via catalog-update.setup.sh

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
# IF FIRST LOAD OF DATA THEN
rake build_atom_feed type="all"
# OTHERWISE IF UPDATE
rake build_atom_feed type="latest"

# 4. IMPORT ATOM FEEDS
cd ~/perseus_catalog
bundle exec rake parse_records file_type='atom' rec_file='/home/ubuntu/FRBR.feeds.YYYYMMDD'

# 5. IMPORT DATA TO SOLR
curl http://localhost:8080/solr-4.5.1/db/dataimport?command=full-import&clean=false

# 6. DEPLOY TO PRODUCTION
# dump mysql
# reload on catalog0.perseus.tufts.edu
# rerun solr import on catalog0.perseus.tufts.edu
# deploy atom feeds


