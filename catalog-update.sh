# Pseudo catalog update script
# needs to be made fully automatable

# Prerequisite: Setup via catalog-update.setup.sh

# 1. IMPORT DATA
cd ~/cite_collections_rails

# IF FIRST LOAD OF DATA THEN
rake catalog_pending_import type="all" 
# OTHERWISE IF UPDATE
rake catalog_pending_import type="latest" 


# 2. BUILD ATOM FEEDS
cd ~/perseus_catalog
bundle exec rake parse_records file_type='atom' rec_file='/home/ubuntu/FRBR.feeds.20150608'

# 3. TEST
curl http://localhost:8080/solr-4.5.1/db/dataimport?command=full-import&clean=false

# 4. DEPLOY
# dump mysql
# reload on catalog0.perseus.tufts.edu
# rerun solr import on catalog0.perseus.tufts.edu
# deploy atom feeds


