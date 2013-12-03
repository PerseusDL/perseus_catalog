# Perseus Catalog Installation & Administration
## Environment
The Perseus catalog has been built on top of Ubuntu 10.04.4 LTS.
Other Linux flavors will probably do the job just as well, 
but you'll want one that uses apt-get as its package manager.
Also some paths to config files may differ in other distros than what's documented here.

## Intended Audience
If you're not an experienced Unix user you will find this guide very frustrating.
Find a friend to help. That's the only advice I can give you.

If you are an experienced user you will still find this guide frustrating.
This is not an easy application to deploy.
Just take it slow.  
Take lots of breaks, and be patient.

I assume you have sudo privileges or some other kind of root access.  
You're going to need that.

# Overview

## 10,000 foot view ( for veterans of the game )
* Install compiler and build tools
* Install Git
* Install Java
* Install Ruby
* Install MySQL
* Install Tomcat
* Install Solr
* Install Phusion Passenger
* Install Apache2
* Install perseus\_catalog
* Import catalog data into MySQL and Solr
* Test
* Secure
* Done!

## 1000 foot view
Let me first give you some context.
It's best to understand what each component does 
and how they relate to one another 
before you kick open the door guns blazin'.

* You need a compiler and common Unix libraries like you need air and water.

* You need Git because a lot of dependencies are hosted in github repositories.

* You need Java because Solr is written in Java.

* Solr is the search engine used by the Perseus Catalog. When you use the catalog to search for everything written by Plutarch you're using Solr.

* You need Tomcat to deploy Solr.  Tomcat is a Java web application server.  There are others like JBoss and Jetty but for our production environment we went with Tomcat.  Solr can't run without one.

* You need MySQL because it's the main data-store for the catalog.

* You need Ruby because perseus\_catalog, aka "Perseus Catalog" aka "The Catalog" aka "this project" is written in Ruby.

* You need Apache2 and Phusion Passenger because together they constitute the Ruby web application server.  Apache2 is your tried and true web server and Phusion Passenger is a module that let's Apache2 run Ruby scripts, and in our specific case the catalog.

* So when you install the catalog you're installing this foundational software, along with some additional code libraries for very specific features, configuring everything so each separate piece of software knows where the other lives, and then finally stuffing it with content.

Easy right?
Don't get lost in the details.
Computers are machines that are simpler than people.
Never forget that.
You're the boss.
Well then let's go...

# Installation
Before we begin I just want to say.  
This guide assumes you're only using your server 
to host the Perseus Catalog.  
If your server needs to run other software concurrently 
you're going to have to be more careful with your configuration 
than what's documented here. 
If you manage to configure the Perseus Catalog 
in such a way that limits the Catalog's footprint, 
even better than what's documented here, 
then please contact us and share what you know!

## Update apt-get

	sudo apt-get update;

## Install Build Tools ( C compiler, common libraries )

	sudo apt-get install build-essential;
	sudo apt-get install zlibc;
	sudo apt-get install zlib1g;
	sudo apt-get install zlib1g-dev;
	sudo apt-get install libssl-dev;
	sudo apt-get install libcurl4-openssl-dev;

## Install Git

	sudo apt-get install git;

## Install Java Friends

	sudo apt-get install openjdk-6-jdk;

## Install Ruby & Friends
Others have just used apt-get to install Ruby 1.8 
but I ran into dependency issues with 1.8 
so I built Ruby 2 from source.
Make sure you didn't skip over any command in the "Install Build Tools" section,
otherwise you'll end up with a crippled version of ruby.

	cd  /usr/local;
	sudo curl -O http://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p247.tar.gz;
	sudo tar -xvzf ruby-2.0.0-p247.tar.gz;
	cd ruby-2.0.0-p247;
	sudo ./configure --prefix=/usr/local;
	sudo make;
	sudo make install;

Ruby-heads like to keep their code libraries very modular.  
These libraries should satisfy most of the catalog's dependencies.

	sudo apt-get install ruby-dev;
	sudo apt-get install libxslt-dev;
	sudo apt-get install libxml2-dev;
	sudo apt-get install rails;

You need the 'gem' command to download other Ruby dependencies.  
Here's how you get it.

	cd /usr/local;
	sudo curl -O http://production.cf.rubygems.org/rubygems/rubygems-2.1.7.tgz;
	sudo tar xvzf rubygems-2.1.7.tgz;
	cd rubygems-2.1.7;
	sudo ruby setup.rb;

Now that you can run gem, install our friend bundler.

	sudo gem install rubygems-update;
	sudo gem install bundler;

## Install MySQL & Friends

	sudo apt-get install mysql-server;
	sudo apt-get install mysql-client;
	sudo apt-get install libmysql-ruby;
	sudo apt-get install libmysqlclient-dev;
	sudo apt-get install libmysql-java;

## Change MySQL Data Directory

	COMING SOON!


## Install Tomcat & Friends

	sudo apt-get install tomcat6;
	sudo apt-get install tomcat6-admin;

Now you'll want to create an admin user.

	sudo vim /etc/tomcat6/tomcat-users.xml

	<tomcat-users>
	  <role rolename="manager"/>
	  <role rolename="admin"/>
	  <user username="{%user%}" password="{%passwd%}" roles="manager,admin"/>
	</tomcat-users>

Start up tomcat and test your access.

	sudo service tomcat6 start

Visit url.

	http://{%host%}:8080/host-manager/html

If Tomcat starts up okay, and you can access the admin panel, move on to the next task.

## Install Solr

### Get Solr

	sudo mkdir /usr/local/perseus
	cd /usr/local/perseus
	sudo curl -O http://apache.tradebit.com/pub/lucene/solr/4.5.1/solr-4.5.1.tgz
	sudo tar xvzf solr-4.5.1.tgz
	sudo ln -s solr-4.5.1 solr

### Hook-up with Tomcat	

	sudo chown -R tomcat6:tomcat6 /usr/local/perseus/solr-4.5.1
	sudo mkdir -p /usr/share/tomcat6/webapps/solr
	sudo cp /usr/local/perseus/solr/dist/solr-4.5.1.war /usr/share/tomcat6/webapps/solr/
	cd /usr/share/tomcat6/webapps/solr
	sudo jar -xvf solr.war
	sudo chown -R tomcat6:tomcat6 /usr/share/tomcat6

### Tomcat says, "I'd love to know more about you, Solr."

	sudo touch /etc/tomcat6/Catalina/localhost/solr.xml
	sudo vim /etc/tomcat6/Catalina/localhost/solr.xml
	sudo chown tomcat6:tomcat6 /etc/tomcat6/Catalina/localhost/solr.xml

	<?xml version="1.0" encoding="utf-8"?>
	<Context docBase="/usr/share/tomcat6/webapps/solr" debug="0" crossContext="true" >
	   <Environment name="solr/home" type="java.lang.String" value="/usr/local/perseus/solr/example/solr" override="true" />
	</Context>

### Configure Solr to display example core.

	sudo vim /usr/share/tomcat6/webapps/solr/WEB-INF/web.xml

Uncomment the <env-entry> block and make it look like below

	<env-entry>
	    <env-entry-name>solr/home</env-entry-name>
	    <env-entry-value>/usr/local/perseus/solr/example/solr</env-entry-value>
	    <env-entry-type>java.lang.String</env-entry-type>
	</env-entry>

### Setup logging.  
To have a working Solr instance you must set up logging.
I was getting no response from my solr webapp until I did.
Don't believe the other guides out there on the Internet 
that tell you it's optional.

Copy over the log4j jars.

	sudo cp /usr/local/perseus/solr-4.5.1/example/lib/ext/* /usr/share/tomcat6/lib/;
	sudo chown -R tomcat6:tomcat6 /usr/share/tomcat6;

Copy over the log4j config file.

	sudo cp /usr/local/perseus/solr/example/resources/log4j.properties /usr/share/tomcat6/webapps/solr/WEB-INF/log4j.properties	

Create a location to store your solr logs.

	sudo touch /var/log/tomcat6/solr.log;
	sudo chmod 644 /var/log/tomcat6/solr.log;
	sudo chown tomcat6:tomcat6 /var/log/tomcat6/solr.log;

Modify the log4j.properties file to write to this log.

	sudo vim /usr/share/tomcat6/webapps/solr/WEB-INF/log4j.properties;

Change this line...

	solr.log=/var/log/tomcat6/solr.log

Add this line to the bottom of Tomcat's startup script.  
This sets some environment variables used by Tomcat. 
Although these could probably also be set in 
/etc/tomcat6/Catalina/localhost/solr.xml

	sudo vim /usr/share/tomcat6/bin/catalina.sh;

Add this line to the bottom of catalina.sh

	JAVA_OPTS="$JAVA_OPTS -Dsolr.solr.home=/usr/local/perseus/solr/example -Dlog4j.debug=true -Dlog4j.configuration=/usr/share/tomcat6/webapps/solr/WEB-INF/log4j.properties"

So at this point you can probably restart Tomcat and see Solr at work...

	sudo service tomcat6 restart

Visit http://{%host%}:8080/solr

Once you see the glorious Solr administration panel move on to the next section.
If you can't access that page something is wrong.
Check the Tomcat administration panel: http://{%host%}:8080/manager/html

And the error logs: /var/log/tomcat6
The most useful logs in that directory are the localhost.{%date%}.log variety,
because these give you a useful stack trace.

### Troubleshooting Solr installation

Solr installation is tricky.
Lot's of things can be overlooked.
Here's some info to help you troubleshoot.
These are the config files we tweaked in this section

	sudo vim /usr/share/tomcat6/webapps/solr/WEB-INF/web.xml
	sudo vim /usr/share/tomcat6/bin/catalina.sh
	sudo vim /usr/share/tomcat6/webapps/solr/WEB-INF/log4j.properties;

### Rename Solr's example core.
We've turned the Solr example application, aka the example "core", 
into our perseus\_catalog indexing "core".
In our documentation and configuration we refer to this "core" as db, 
so we have to rename the core from collection1, its default name, to db.

I did this through the Solr web-administration panel.

1. Go to *http://{%host%}:8080/solr*
2. Click *Core Admin* in the leftmost column
3. Click *collection1* under the *Add Core* button
4. Click *Rename* button
5. Enter *db* into input box
6. Click *Rename Core*
	
### Setup dataimport handler on Solr
The dataimport handler basically says, 
"Hey, Solr!  When I go to your dataimport url 
and issue you commands I want you to change the data 
in the location specified in my config file using this code."  

So you need to put the dataimport code in a place where Solr can get it easily...

	sudo cp /usr/local/perseus/solr/dist/solr-dataimporthandler-4.5.1.jar /usr/share/tomcat6/webapps/solr/WEB-INF/lib/;
	sudo cp /usr/local/perseus/solr/dist/solr-dataimporthandler-extras-4.5.1.jar /usr/share/tomcat6/webapps/solr/WEB-INF/lib/;

...and you need to add the following xml config chunks to solrconfig.xml to seal the deal.

	sudo vim /usr/local/perseus/solr/example/solr/collection1/conf/solrconfig.xml;

	<lib dir="../../../dist/" regex="solr-dataimporthandler-.*\.jar" />

	<requestHandler name="/dataimport" class="org.apache.solr.handler.dataimport.DataImportHandler">
	  <lst name="defaults">
	    <str name="config">data-config.xml</str>
	  </lst>
	</requestHandler>

Don't worry that the data-config.xml file doesn't exist yet.  
You will be creating it when you install perseus\_catalog.

## Install Apache2

	sudo apt-get install apache2;
	sudo apt-get install apache2-threaded-dev;

## Install Phusion Passenger

	sudo gem install passenger;
	sudo passenger-install-apache2-module;

Just follow the prompts.
The output is really chatty and looks like an error log.
Patience.
You need a lot of memory to run the passenger-install script.
I've gotten error messages saying my compiler ran out of memory.
If that happens do this...

	sudo dd if=/dev/zero of=/swap bs=1M count=1024;
	sudo mkswap /swap;
	sudo swapon /swap;

and then rerun...

	sudo passenger-install-apache2-module;

## Install perseus\_catalog
Okay. You have all of perseus\_catalog's dependencies in place.  
Great!
Now comes the final lap, the final boss battle, the final final.

### Get the catalog

	cd /var/www;
	sudo git clone https://github.com/PerseusDL/perseus_catalog;

### MySQL config
Now you'll want to create the MySQL user that will be used by the catalog catalog.
( This isn't following best practices, I'll improve this in the near future )

	mysql -u root -p

	mysql> SET PASSWORD FOR '{%user%}'@'localhost' = PASSWORD('{%passwd%}');
	mysql> GRANT ALL PRIVILEGES ON *.* TO '{%user%}'@'localhost' IDENTIFIED BY '{%passwd%}' WITH GRANT OPTION; 
	mysql> exit

So perseus\_catalog needs to know where the catalog data actually lives.
Well it lives in a MySQL database on the same host.
Let's make that explicit.

	sudo cp /var/www/perseus_catalog/config/database.yml.sample /var/www/perseus_catalog/config/database.yml;
	sudo vim /var/www/perseus_catalog/config/database.yml;

Add your MySQL connection credentials.  The MySQL socket path is...

	socket: /var/run/mysqld/mysqld.sock

Now the database schema can be built with included scripts.

	cd /var/www/perseus_catalog;
	sudo bundle install;
	sudo rake db:create:all;
	sudo rake db:migrate;	

### Solr config
Solr needs to know a few things about perseus\_catalog.  
Things like what does the database tables look like?
How do I connect to the database in the first place?
That's handled in two configuration files.

	sudo cp /var/www/perseus_catalog/config/solr/db-data-config.xml /usr/local/perseus/solr/example/solr/collection1/conf/data-config.xml;
	sudo cp /var/www/perseus_catalog/config/solr/schema.xml /usr/local/perseus/solr/example/solr/collection1/conf/;

You need to do a little configuration...

	sudo vim /usr/local/perseus/solr/example/solr/collection1/conf/schema.xml;

Add the following line to schema.xml

	<field name="_version_" type="long" indexed="true" stored="true" multiValued="false"/>

If you don't later on your data import will fail.

The catalog needs to know what url it needs to communicate with Solr.
Since Solr is on the the same host and is running on Tomcat that url is http://localhost:8080/solr/db.

	sudo vim /var/www/perseus_catalog/config/solr.yml;

### Apache2 config
So you need a config file that tells Apache 
where the catalog resides on the filesystem, 
how to run the catalog's code, 
and what urls map to it.  

	sudo touch /etc/apache2/conf.d/catalog.conf;
	sudo vim /etc/apache2/conf.d/catalog.conf;

Be sure to update the passenger {%version%} when you copy the text below!

	LoadModule passenger_module /usr/local/lib/ruby/gems/2.0.0/gems/passenger-{%version%}/buildout/apache2/mod_passenger.so
	PassengerRoot /usr/local/lib/ruby/gems/2.0.0/gems/passenger-{%version%}
	PassengerDefaultRuby /usr/local/bin/ruby
	PassengerLogLevel 3
	<VirtualHost *:80>
		PassengerEnabled On
		DocumentRoot /var/www/perseus_catalog/public
		RailsEnv production
		RailsBaseURI /
		<Directory /var/www/perseus_catalog/public>
			Allow from all
			Options -MultiViews
		</Directory>
	</VirtualHost>

## Loading catalog data
But before you can run the dataimport command you have to config the Solr core
which does the indexing.
So you have to update its data-config file.

	sudo vim /usr/local/perseus/solr/example/solr/collection1/conf/data-config.xml

Find this line and fill in the blanks...

	<dataSource type="JdbcDataSource" driver="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost/perseus_blacklight" user="{%mysql_user%}" password="{%mysql_password%}" />

Now let's gather our data.

### The official way.

	git clone https://github.com/PerseusDL/catalog_data;
	cd /var/www/perseus_catalog;

Okay you're in the right directory...
Now the next command takes a very long time to complete.
Hours...
I run it with nohup ( that's short for "no hang up" )
So if my ssh session ends this command will keep chugging along.
Try it.
You can logout grab a drink with friends.
Come back.
Login, and it'll still be working.

	sudo nohup rake build_atom_feed > tmp/build_atom_feed.out 2>&1&;

You can baby-sit it by running this command.

	sudo tail -f /var/www/perseus_catalog/tmp/tmp/build_atom_feed.out;

So the "rake build\_atom\_feed" command will create a bunch of xml files 
in atom-feed format in a directory in your user directory.
The name of that directory has a timestamp in it.
It looks like this

	# ~/FRBR.feeds.all.20131021

Now you need to import these xml files into your database.
Here's how you do it.  Notice you should use the full path name to your home directory

	cd /var/www/perseus_catalog;
	sudo RAILS_ENV='production' rake parse_records file_type="atom" rec_file="/home/{%you%}/FRBR.feeds.all.20131021";

### The actual way.
What I ended up doing is getting the atom-feed xml files in a folder that we store on Dropbox,
rather than building them with "rake build_atom_feed"

To import them the command is the same.

	cd /var/www/perseus_catalog;
	sudo RAILS_ENV='production' rake parse_records file_type="atom" rec_file="/home/{%you%}/FRBR.feeds.all.20131021";

## Create Solr index.
So Solr is a search engine, and in order for it to work properly it has to index your data.
You run dataimport commands by issuing SOAP requests.
Yes, that's how it's done... 
I know...

Restart Tomcat.

	sudo service tomcat6 restart

Now you can run those import commands.

	curl http://localhost:8080/solr/db/update -H "Content-type: text/xml" \--data-binary '<delete><query>*:*</query></delete>';
	curl http://localhost:8080/solr/db/update -H "Content-type: text/xml" \--data-binary '<commit />';
	curl http://localhost:8080/solr/db/update -H  "Content-type: text/xml" \--data-binary '<optimize />';
	curl http://localhost:8080/solr/db/dataimport?command=full-import;

## Quick fix.
So there's something else you gotta do.
Otherwise you'll get an error like this...

	/var/www/perseus_catalog/app/importers/hathi_compare.rb:63: syntax error, unexpected keyword_end

Here's the solution.

	sudo vim /var/www/perseus_catalog/app/importers/hathi_compare.rb

Comment out line 61.

	#ids =

## Start it up!

	sudo service tomcat6 restart;
	sudo service apache2 restart;

## Check it out
Go to http://{%host%}

Huzzah!
Unless it didn't work... in which case...

## Troubleshooting tips
Here is a list of all the files you had to tweak for proper configuration.

	view /etc/apache2/conf.d/catalog.conf 
	view /etc/tomcat6/tomcat-users.xml
	view /etc/tomcat6/Catalina/localhost/solr.xml
	view /etc/tomcat6/server.xml
	view /usr/share/tomcat6/bin/catalina.sh
	view /usr/lib/tomcat6/webapps/solr/WEB-INF/web.xml
	view /usr/local/perseus/solr/example/solr/collection1/conf/solrconfig.xml
	view /usr/local/perseus/solr/example/solr/collection1/conf/schema.xml	

And here is a list of log files you can inspect.

	view /var/log/tomcat6/localhost.{%date%}.log

## Secure Solr!
Oh hohoho!  
You thought that was it!  
Nay, friend.

So you may have noticed that Solr is not well secured out of the box.
You can issue commands to delete application data with a SOAP request.
Also it exposes database connection credentials in its admin interface.
So once the catalog is working properly we need to restrict access 
so Internet evildoers don't harm our perseus\_catalog instance.

I'm going to restrict access with iptables.

	sudo iptables -A INPUT -p tcp --dport 8080 -s 127.0.0.1 -j ACCEPT;
	sudo iptables -A INPUT -p tcp --dport 8080 -j DROP;

So this is a good way to do this if
*there are no outward facing applications running on port 8080 aka our Tomcat server.*
These two commands combined will restrict access to port 8080 to the host itself.
So in order for someone to communicate with Solr a user must be logged into the host.
If somebody can log into the host machine then we don't care about Solr's security holes.
They already have the keys to the castle.

So now when you point go to a url from like *http://{%host%}:8080/{%anything at all%}* 
from any other computer, nothing will be returned.
The tcp packets that initiate communication with Tomcat will be dropped completely.

If you need to see your iptables rules run this...

	sudo iptables --list;

If you ran the commands to restrict access properly you 
should see an output table that includes these lines.

	Chain INPUT (policy ACCEPT)
	target     prot opt source               destination         
	ACCEPT     tcp  --  localhost            anywhere            tcp dpt:http-alt 
	DROP       tcp  --  anywhere             anywhere            tcp dpt:http-alt 

So now you have to save these iptables rules and restore them on boot.

	sudo mkdir /etc/iptables;
	sudo touch /etc/iptables/startup.rules;
	sudo chmod 777 /etc/iptables/startup.rules;
	sudo iptables-save > /etc/iptables/startup.rules;
	sudo chmod 644 /etc/iptables/startup.rules;
	sudo touch /etc/init/iptables.conf;
	
	sudo vim /etc/init/iptables.conf;

Add this line...

	iptables-restore < /etc/iptables/startup.rules

If you ever need to flush your iptables rules run these commands.

	sudo iptables -F;
	sudo iptables -X;
	sudo iptables -t nat -F;
	sudo iptables -t nat -X;
	sudo iptables -t mangle -F;
	sudo iptables -t mangle -X;
	sudo iptables -P INPUT ACCEPT;
	sudo iptables -P FORWARD ACCEPT;
	sudo iptables -P OUTPUT ACCEPT;