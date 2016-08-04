#Installation Instructions

## Ubuntu 10.04

### install apache, ruby, gems, mysql, passenger phusion, git, tomcat

* sudo apt-get install apache2
* sudo apt-get install tomcat6
* sudo apt-get install mysql
* sudo apt-get install git
* sudo apt-get install ruby
* sudo apt-get install rubygems
* sudo gem installrubygems-update
* sudo export path=$PATH;/path/to/gem/install/bin
* sudo update_rubygems (need at least 1.3.6)
* sudo gem install passenger
* sudo apt-get install build-essential
* sudo apt-get install libcurl4-openssl-dev
* sudo apt-get install libssl-dev
* sudo apt-get install zlib1g-dev
* sudo apt-get install ruby-dev
* sudo apt-get install apache2-threaded-dev
* sudo apt-get install libapr1-dev
* sudo apt-get install libaprutil1-dev
* passenger-install-apache2-module

### install dependencies for application gemfiles
* apt-get install libxslt-dev libxml2-dev

### get perseus_catalog code from github to directory under Apache document root
* sudo git clone https://github.com/PerseusDL/perseus_catalog.git /var/www
* chown -R www-data /var/www/perseus_catalog

### create mysql database
* mysql create database perseus_blacklight
* mysql grant all on perseus_blacklight.* to 'user'@'%' identified by 'password'

### install solr
* get from TBD 
* make base directory for solr data at /usr/local/perseus/solr
* chown -R tomcat6:tomcat6 /usr/local/perseus/solr
* copy war to tomcat webapps directory
* copy dataimport jars from solr application directory to exploded solr war directory in solr/WEB-INF/lib

### configure tomcat
* add JAVA_OPTS="$JAVA_OPTS -Dsolr.solr.home=/usr/local/perseus/solr" to tomcat startup script /usr/share/tomcat6/bin/catalina.sh
* make sure connector for port 8080 in tomcat server.xml has URIEncoding="UTF-8"
 
### configure Apache

#### for deployment to catalog suburi
* ln -s /var/www/perseus_catalog/pubic /var/www/catalog
* add the following to the VirtualHost configuration
    RailsEnv production
    RailsBaseURI /catalog
    <Directory /var/www/catalog>
      Allow from all
      Options -MultiViews +Indexes FollowSymLinks +ExecCGI
      AllowOverride AuthConfig FileInfo
   </Directory>


### load data 

See https://github.com/PerseusDL/perseus_catalog/blob/master/catalog-update.setup.sh and https://github.com/PerseusDL/perseus_catalog/blob/master/catalog-update.sh

### configure catalog app
* cp /var/www/perseus_catalog/config/database.yml.sample /var/www/perseus_catalog/config/database.yml
* edit production settings for database for mysql user and password and sock
* to find location of mysql sock file mysqladmin variables -u root -p | grep sock

### restart apache and tomcat
* sudo service tomcat6 restart
* sudo service apache2 restart
