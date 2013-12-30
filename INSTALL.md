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

### Solrconfig.xml

	sudo vim /usr/local/perseus/solr/example/solr/collection1/conf/solrconfig.xml;

Copy the following code and save it as */usr/local/perseus/solr/example/solr/collection1/conf/solrconfig.xml*
Why are you copying over a whole file?
Solr drastically changed their defaults of this configuration file in recent versions.
The text below is a working configuration file we use in production.
There are some configuration options that collectively make all the page facets work properly.
In the absence of them parts of the perseus_catalog break.
I haven't isolated this configuration options.
When they are isolated I'll update this.

	<?xml version="1.0" encoding="UTF-8" ?>
	<!--
	 Licensed to the Apache Software Foundation (ASF) under one or more
	 contributor license agreements.  See the NOTICE file distributed with
	 this work for additional information regarding copyright ownership.
	 The ASF licenses this file to You under the Apache License, Version 2.0
	 (the "License"); you may not use this file except in compliance with
	 the License.  You may obtain a copy of the License at
	
	     http://www.apache.org/licenses/LICENSE-2.0
	
	 Unless required by applicable law or agreed to in writing, software
	 distributed under the License is distributed on an "AS IS" BASIS,
	 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 See the License for the specific language governing permissions and
	 limitations under the License.
	-->
	
	<config>
	  
	  <!--
	    Controls what version of Lucene various components of Solr adhere to. Generally, you want
	    to use the latest version to get all bug fixes and improvements. It is highly recommended 
	    that you fully re-index after changing this setting as it can affect both how text is indexed
	    and queried.
	  -->
	  <luceneMatchVersion>LUCENE_40</luceneMatchVersion>
	
	  <jmx />
	
	  <lib dir="../../../contrib/extraction/lib" regex=".*\.jar" />
	  <lib dir="../../../dist/" regex="solr-cell-\d.*\.jar" />
	
	  <lib dir="../../../contrib/clustering/lib/" regex=".*\.jar" />
	  <lib dir="../../../dist/" regex="solr-clustering-\d.*\.jar" />
	
	  <lib dir="../../../contrib/langid/lib/" regex=".*\.jar" />
	  <lib dir="../../../dist/" regex="solr-langid-\d.*\.jar" />
	
	  <lib dir="../../../contrib/velocity/lib" regex=".*\.jar" />
	  <lib dir="../../../dist/" regex="solr-velocity-\d.*\.jar" />
	  <lib dir="../../../dist/" regex="solr-dataimporthandler-.*\.jar" />
	  <lib dir="/usr/share/java" regex="mysql-connector-java-.*\.jar" />
	
	  <!-- <indexConfig> section could go here, but we want the defaults -->
	
	  <!-- the default high-performance update handler -->
	  <updateHandler class="solr.DirectUpdateHandler2">
	
	    <!-- A prefix of "solr." for class names is an alias that
	         causes solr to search appropriate packages, including
	         org.apache.solr.(search|update|request|core|analysis)
	     -->
	
	    <!-- Limit the number of deletions Solr will buffer during doc updating.
	        
	        Setting this lower can help bound memory use during indexing.
	    -->
	    <maxPendingDeletes>100000</maxPendingDeletes>
	
	    <!-- Perform a <commit/> automatically under certain conditions:
	
	         maxDocs - number of updates since last commit is greater than this
	         maxTime - oldest uncommited update (in ms) is this long ago
	    <autoCommit> 
	      <maxDocs>10000</maxDocs>
	      <maxTime>1000</maxTime> 
	    </autoCommit>
	    -->
	
	    <!-- The RunExecutableListener executes an external command.
	         exe - the name of the executable to run
	         dir - dir to use as the current working directory. default="."
	         wait - the calling thread waits until the executable returns. default="true"
	         args - the arguments to pass to the program.  default=nothing
	         env - environment variables to set.  default=nothing
	      -->
	    <!-- A postCommit event is fired after every commit or optimize command
	    <listener event="postCommit" class="solr.RunExecutableListener">
	      <str name="exe">solr/bin/snapshooter</str>
	      <str name="dir">.</str>
	      <bool name="wait">true</bool>
	      <arr name="args"> <str>arg1</str> <str>arg2</str> </arr>
	      <arr name="env"> <str>MYVAR=val1</str> </arr>
	    </listener>
	    -->
	    <!-- A postOptimize event is fired only after every optimize command, useful
	         in conjunction with index distribution to only distribute optimized indicies 
	    <listener event="postOptimize" class="solr.RunExecutableListener">
	      <str name="exe">snapshooter</str>
	      <str name="dir">solr/bin</str>
	      <bool name="wait">true</bool>
	    </listener>
	    -->
	
	  </updateHandler>
	
	
	  <query>
	    <!-- Maximum number of clauses in a boolean query... can affect
	        range or prefix queries that expand to big boolean
	        queries.  An exception is thrown if exceeded.  -->
	    <maxBooleanClauses>1024</maxBooleanClauses>
	
	    
	    <!-- Cache used by SolrIndexSearcher for filters (DocSets),
	         unordered sets of *all* documents that match a query.
	         When a new searcher is opened, its caches may be prepopulated
	         or "autowarmed" using data from caches in the old searcher.
	         autowarmCount is the number of items to prepopulate.  For LRUCache,
	         the autowarmed items will be the most recently accessed items.
	       Parameters:
	         class - the SolrCache implementation (currently only LRUCache)
	         size - the maximum number of entries in the cache
	         initialSize - the initial capacity (number of entries) of
	           the cache.  (seel java.util.HashMap)
	         autowarmCount - the number of entries to prepopulate from
	           and old cache.
	         -->
	    <filterCache
	      class="solr.LRUCache"
	      size="173000"
	      initialSize="4000"
	      autowarmCount="4000"/>
	
	   <!-- queryResultCache caches results of searches - ordered lists of
	         document ids (DocList) based on a query, a sort, and the range
	         of documents requested.  -->
	    <queryResultCache
	      class="solr.LRUCache"
	      size="1042"
	      initialSize="1042"
	      autowarmCount="256"/>
	
	  <!-- documentCache caches Lucene Document objects (the stored fields for each document).
	       Since Lucene internal document ids are transient, this cache will not be autowarmed.  -->
	    <documentCache
	      class="solr.LRUCache"
	      size="1042"
	      initialSize="1042"
	      autowarmCount="0"/>
	
	    <!-- If true, stored fields that are not requested will be loaded lazily.
	
	    This can result in a significant speed improvement if the usual case is to
	    not load all stored fields, especially if the skipped fields are large compressed
	    text fields.
	    -->
	    <enableLazyFieldLoading>true</enableLazyFieldLoading>
	
	    <!-- Example of a generic cache.  These caches may be accessed by name
	         through SolrIndexSearcher.getCache(),cacheLookup(), and cacheInsert().
	         The purpose is to enable easy caching of user/application level data.
	         The regenerator argument should be specified as an implementation
	         of solr.search.CacheRegenerator if autowarming is desired.  -->
	    <!--
	    <cache name="myUserCache"
	      class="solr.LRUCache"
	      size="4096"
	      initialSize="1024"
	      autowarmCount="1024"
	      regenerator="org.mycompany.mypackage.MyRegenerator"
	      />
	    -->
	
	   <!-- An optimization that attempts to use a filter to satisfy a search.
	         If the requested sort does not include score, then the filterCache
	         will be checked for a filter matching the query. If found, the filter
	         will be used as the source of document ids, and then the sort will be
	         applied to that.
	    <useFilterForSortedQuery>true</useFilterForSortedQuery>
	   -->
	
	   <!-- An optimization for use with the queryResultCache.  When a search
	         is requested, a superset of the requested number of document ids
	         are collected.  For example, if a search for a particular query
	         requests matching documents 10 through 19, and queryWindowSize is 50,
	         then documents 0 through 49 will be collected and cached.  Any further
	         requests in that range can be satisfied via the cache.  -->
	    <queryResultWindowSize>50</queryResultWindowSize>
	    
	    <!-- Maximum number of documents to cache for any entry in the
	         queryResultCache. -->
	    <queryResultMaxDocsCached>200</queryResultMaxDocsCached>
	
	    <!-- This entry enables an int hash representation for filters (DocSets)
	         when the number of items in the set is less than maxSize.  For smaller
	         sets, this representation is more memory efficient, more efficient to
	         iterate over, and faster to take intersections.  -->
	    <HashDocSet maxSize="3000" loadFactor="0.75"/>
	
	    <!-- a newSearcher event is fired whenever a new searcher is being prepared
	         and there is a current searcher handling requests (aka registered). -->
	    <!-- QuerySenderListener takes an array of NamedList and executes a
	         local query request for each NamedList in sequence. -->
	    <listener event="newSearcher" class="solr.QuerySenderListener">
	      <arr name="queries">
	        <lst> <str name="q">*:*</str>
	          <str name="facet.field">tg_facet</str>
	        </lst>
	        <lst> <str name="q">*:*</str>
	          <str name="facet.field">work_facet</str>
	        </lst>
	      </arr>
	    </listener>
	
	    <!-- a firstSearcher event is fired whenever a new searcher is being
	         prepared but there is no current registered searcher to handle
	         requests or to gain autowarming data from. -->
	    <listener event="firstSearcher" class="solr.QuerySenderListener">
	      <arr name="queries">
	        <lst> <str name="q">*:*</str>
	              <str name="facet.field">tg_facet</str>
	        </lst>
	        <lst> <str name="q">*:*</str>
	              <str name="facet.field">work_facet</str>
	        </lst>
	      </arr>
	    </listener>
	
	    <!-- If a search request comes in and there is no current registered searcher,
	         then immediately register the still warming searcher and use it.  If
	         "false" then all requests will block until the first searcher is done
	         warming. -->
	    <useColdSearcher>false</useColdSearcher>
	
	    <!-- Maximum number of searchers that may be warming in the background
	      concurrently.  An error is returned if this limit is exceeded. Recommend
	      1-2 for read-only slaves, higher for masters w/o cache warming. -->
	    <maxWarmingSearchers>4</maxWarmingSearchers>
	
	  </query>
	
	  <!-- 
	    Let the dispatch filter handler /select?qt=XXX
	    handleSelect=true will use consistent error handling for /select and /update
	    handleSelect=false will use solr1.1 style error formatting
	    -->
	  <requestDispatcher handleSelect="true" >
	    <!--Make sure your system has some authentication before enabling remote streaming!  -->
	    <requestParsers enableRemoteStreaming="false" multipartUploadLimitInKB="2048" />
	        
	    <!-- Set HTTP caching related parameters (for proxy caches and clients).
	          
	         To get the behaviour of Solr 1.2 (ie: no caching related headers)
	         use the never304="true" option and do not specify a value for
	         <cacheControl>
	    -->
	    <httpCaching never304="true">
	    <!--httpCaching lastModifiedFrom="openTime"
	                 etagSeed="Solr"-->
	       <!-- lastModFrom="openTime" is the default, the Last-Modified value
	            (and validation against If-Modified-Since requests) will all be
	            relative to when the current Searcher was opened.
	            You can change it to lastModFrom="dirLastMod" if you want the
	            value to exactly corrispond to when the physical index was last
	            modified.
	               
	            etagSeed="..." is an option you can change to force the ETag
	            header (and validation against If-None-Match requests) to be
	            differnet even if the index has not changed (ie: when making
	            significant changes to your config file)
	
	            lastModifiedFrom and etagSeed are both ignored if you use the
	            never304="true" option.
	       -->
	       <!-- If you include a <cacheControl> directive, it will be used to
	            generate a Cache-Control header, as well as an Expires header
	            if the value contains "max-age="
	               
	            By default, no Cache-Control header is generated.
	
	            You can use the <cacheControl> option even if you have set
	            never304="true"
	       -->
	       <!-- <cacheControl>max-age=30, public</cacheControl> -->
	    </httpCaching>
	  </requestDispatcher>
	  
	      
	  <!-- requestHandler plugins... incoming queries will be dispatched to the
	     correct handler based on the path or the 'qt' param.
	     Names starting with a '/' are accessed with the a path equal to the 
	     registered name.  Names without a leading '/' are accessed with:
	      http://host/app/select?qt=name
	     If no qt is defined, the requestHandler that declares default="true"
	     will be used.
	  -->
	  <requestHandler name="standard" class="solr.StandardRequestHandler" default="true">
	    <!-- default values for query parameters -->
	     <lst name="defaults">
	       <str name="echoParams">explicit</str>
	       <!-- 
	       <int name="rows">10</int>
	       <str name="fl">*</str>
	       <str name="version">2.1</str>
	        -->
	     </lst>
	  </requestHandler>
	
	  <!-- SpellCheckerRequestHandler takes in a word (or several words) as the
	       value of the "q" parameter and returns a list of alternative spelling
	       suggestions.  If invoked with a ...&cmd=rebuild, it will rebuild the
	       spellchecker index.
	  -->
	  <requestHandler name="spellchecker" class="solr.SpellCheckerRequestHandler" startup="lazy">
	    <!-- default values for query parameters -->
	     <lst name="defaults">
	       <int name="suggestionCount">1</int>
	       <float name="accuracy">0.5</float>
	     </lst>
	     
	     <!-- Main init params for handler -->
	     
	     <!-- The directory where your SpellChecker Index should live.   -->
	     <!-- May be absolute, or relative to the Solr "dataDir" directory. -->
	     <!-- If this option is not specified, a RAM directory will be used -->
	     <str name="spellcheckerIndexDir">spell</str>
	     
	     <!-- the field in your schema that you want to be able to build -->
	     <!-- your spell index on. This should be a field that uses a very -->
	     <!-- simple FieldType without a lot of Analysis (ie: string) -->
	     <str name="termSourceField">word</str>
	     
	   </requestHandler>
	
	   <requestHandler name="/mlt" class="solr.MoreLikeThisHandler">
	     <lst name="defaults">
	       <str name="mlt.fl">manu,cat</str>
	       <int name="mlt.mindf">1</int>
	     </lst>
	   </requestHandler>
	
	   <requestHandler name="/dataimport" class="org.apache.solr.handler.dataimport.DataImportHandler">
	    <lst name="defaults">
	    	<str name="config">data-config.xml</str>
	    </lst>
	  </requestHandler>
	   
	  
	  
	  <!--
	   
	   Search components are registered to SolrCore and used by Search Handlers
	   
	   By default, the following components are avaliable:
	    
	   <searchComponent name="query"     class="org.apache.solr.handler.component.QueryComponent" />
	   <searchComponent name="facet"     class="org.apache.solr.handler.component.FacetComponent" />
	   <searchComponent name="mlt"       class="org.apache.solr.handler.component.MoreLikeThisComponent" />
	   <searchComponent name="highlight" class="org.apache.solr.handler.component.HighlightComponent" />
	   <searchComponent name="debug"     class="org.apache.solr.handler.component.DebugComponent" />
	  
	   If you register a searchComponent to one of the standard names, that will be used instead.
	  
	   -->
	 
	  <requestHandler name="/search" class="org.apache.solr.handler.component.SearchHandler">
	    <lst name="defaults">
	      <str name="echoParams">explicit</str>
	    </lst>
	    <!--
	    By default, this will register the following components:
	    
	    <arr name="components">
	      <str>query</str>
	      <str>facet</str>
	      <str>mlt</str>
	      <str>highlight</str>
	      <str>debug</str>
	    </arr>
	    
	    To insert handlers before or after the 'standard' components, use:
	    
	    <arr name="first-components">
	      <str>first</str>
	    </arr>
	    
	    <arr name="last-components">
	      <str>last</str>
	    </arr>
	    
	    -->
	  </requestHandler>
	  
	  <requestHandler name="search" class="org.apache.solr.handler.component.SearchHandler">
	    <lst name="defaults">
	      <str name="echoParams">explicit</str>
	      <str name="fl">*,score</str>
	      <str name="facet">on</str>
	      <str name="facet.mincount">1</str>
	      <str name="facet.limit">10</str>
	      <str name="facet.field">tg_facet</str>
	      <str name="facet.field">work_facet</str>
	      <str name="facet.field">work_lang</str>
	      <str name="facet.field">exp_series</str>
	      <str name="facet.field">year_facet</str>
	      <str name="facet.field">exp_language</str>
	      <str name="q.alt">*:*</str>
	    </lst>
	  </requestHandler>
	  
	  <requestHandler name="document" class="solr.SearchHandler">
	    <lst name="defaults">
	      <str name="echoParams">explicit</str>
	      <str name="fl">*</str>
	      <str name="rows">1</str>
	      <str name="q">{!raw f=id v=$id}</str>
	      <!-- use id=blah instead of q=id:blah -->
	    </lst>
	  </requestHandler>
	  
	  <searchComponent name="elevator" class="org.apache.solr.handler.component.QueryElevationComponent" >
	    <!-- pick a fieldType to analyze queries -->
	    <str name="queryFieldType">string</str>
	    <str name="config-file">elevate.xml</str>
	  </searchComponent>
	 
	  <requestHandler name="/elevate" class="org.apache.solr.handler.component.SearchHandler" startup="lazy">
	    <lst name="defaults">
	      <str name="echoParams">explicit</str>
	    </lst>
	    <arr name="last-components">
	      <str>elevator</str>
	    </arr>
	  </requestHandler>
	  
	
	  
	  <!-- Update request handler.  
	  
	       Note: Since solr1.1 requestHandlers requires a valid content type header if posted in 
	       the body. For example, curl now requires: -H 'Content-type:text/xml; charset=utf-8'
	       The response format differs from solr1.1 formatting and returns a standard error code.
	       
	       To enable solr1.1 behavior, remove the /update handler or change its path
	       
	       "update.processor.class" is the class name for the UpdateRequestProcessor.  It is initalized
	       only once.  This can not be changed for each request.
	    -->
	  <requestHandler name="/update" class="solr.UpdateRequestHandler"  />
	
	
	  <!-- 
	   Admin Handlers - This will register all the standard admin RequestHandlers.  Adding 
	   this single handler is equivolent to registering:
	   
	  <requestHandler name="/admin/luke"       class="org.apache.solr.handler.admin.LukeRequestHandler" />
	  <requestHandler name="/admin/system"     class="org.apache.solr.handler.admin.SystemInfoHandler" />
	  <requestHandler name="/admin/plugins"    class="org.apache.solr.handler.admin.PluginInfoHandler" />
	  <requestHandler name="/admin/threads"    class="org.apache.solr.handler.admin.ThreadDumpHandler" />
	  <requestHandler name="/admin/properties" class="org.apache.solr.handler.admin.PropertiesRequestHandler" />
	  <requestHandler name="/admin/file"       class="org.apache.solr.handler.admin.ShowFileRequestHandler" >
	  
	  If you wish to hide files under ${solr.home}/conf, explicitly register the ShowFileRequestHandler using:
	  <requestHandler name="/admin/file" class="org.apache.solr.handler.admin.ShowFileRequestHandler" >
	    <lst name="invariants">
	     <str name="hidden">synonyms.txt</str> 
	     <str name="hidden">anotherfile.txt</str> 
	    </lst>
	  </requestHandler>
	  -->
	  <requestHandler name="/admin/" class="org.apache.solr.handler.admin.AdminHandlers" />
	  
	  <!-- ping/healthcheck -->
	  <requestHandler name="/admin/ping" class="solr.PingRequestHandler">
	    <lst name="invariants">
	      <str name="q">solrpingquery</str>
	    </lst>
	    <lst name="defaults">
	      <str name="echoParams">all</str>
	    </lst>
	    <!-- An optional feature of the PingRequestHandler is to configure the 
	         handler with a "healthcheckFile" which can be used to enable/disable 
	         the PingRequestHandler.
	         relative paths are resolved against the data dir 
	      -->
	    <!-- <str name="healthcheckFile">server-enabled.txt</str> -->
	  </requestHandler>
	  
	  <!-- Echo the request contents back to the client -->
	  <requestHandler name="/debug/dump" class="solr.DumpRequestHandler" >
	    <lst name="defaults">
	     <str name="echoParams">explicit</str> <!-- for all params (including the default etc) use: 'all' -->
	     <str name="echoHandler">true</str>
	    </lst>
	  </requestHandler>
	  
	  <highlighting>
	   <!-- Configure the standard fragmenter -->
	   <!-- This could most likely be commented out in the "default" case -->
	   <fragmenter name="gap" class="org.apache.solr.highlight.GapFragmenter" default="true">
	    <lst name="defaults">
	     <int name="hl.fragsize">100</int>
	    </lst>
	   </fragmenter>
	
	   <!-- A regular-expression-based fragmenter (f.i., for sentence extraction) -->
	   <fragmenter name="regex" class="org.apache.solr.highlight.RegexFragmenter">
	    <lst name="defaults">
	      <!-- slightly smaller fragsizes work better because of slop -->
	      <int name="hl.fragsize">70</int>
	      <!-- allow 50% slop on fragment sizes -->
	      <float name="hl.regex.slop">0.5</float> 
	      <!-- a basic sentence pattern -->
	      <str name="hl.regex.pattern">[-\w ,/\n\"']{20,200}</str>
	    </lst>
	   </fragmenter>
	   
	   <!-- Configure the standard formatter -->
	   <formatter name="html" class="org.apache.solr.highlight.HtmlFormatter" default="true">
	    <lst name="defaults">
	     <str name="hl.simple.pre"><![CDATA[<em>]]></str>
	     <str name="hl.simple.post"><![CDATA[</em>]]></str>
	    </lst>
	   </formatter>
	  </highlighting>
	  
	  
	  <!-- queryResponseWriter plugins... query responses will be written using the
	    writer specified by the 'wt' request parameter matching the name of a registered
	    writer.
	    The "default" writer is the default and will be used if 'wt' is not specified 
	    in the request. XMLResponseWriter will be used if nothing is specified here.
	    The json, python, and ruby writers are also available by default.
	
	    <queryResponseWriter name="xml" class="solr.XMLResponseWriter" default="true"/>
	    <queryResponseWriter name="json" class="solr.JSONResponseWriter"/>
	    <queryResponseWriter name="python" class="solr.PythonResponseWriter"/>
	    <queryResponseWriter name="ruby" class="solr.RubyResponseWriter"/>
	    <queryResponseWriter name="php" class="solr.PHPResponseWriter"/>
	    <queryResponseWriter name="phps" class="solr.PHPSerializedResponseWriter"/>
	
	    <queryResponseWriter name="custom" class="com.example.MyResponseWriter"/>
	  -->
	
	  <!-- XSLT response writer transforms the XML output by any xslt file found
	       in Solr's conf/xslt directory.  Changes to xslt files are checked for
	       every xsltCacheLifetimeSeconds.  
	   -->
	  <queryResponseWriter name="xslt" class="solr.XSLTResponseWriter">
	    <int name="xsltCacheLifetimeSeconds">5</int>
	  </queryResponseWriter> 
	    
	  <!-- config for the admin interface --> 
	  <admin>
	    <defaultQuery>*:*</defaultQuery>
	  </admin>
	  
	  
	
	</config>

There are two important tags you created when you copied this big mess.  I just want to bring them to your attention.

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

## Move MySQL data directory
Do you need to move your MySQL data directory?
Y'know because of certain back-up system realities and such.
Here's how that's done.

Where are you moving it to?

	sudo mkdir -p /usr/local/perseus/mysql

Stop MySQL.

	sudo service mysql stop

Copy existing data.

	sudo cp -Rp /var/lib/mysql /usr/local/perseus/mysql
	sudo mv /usr/local/perseus/mysql/mysql /usr/local/perseus/mysql/data

Change the datadir config option.

	sudo vim /etc/mysql/my.cnf

	datadir         = /usr/local/perseus/mysql/data

If you're using Ubuntu 7 or greater you have to update its security software AppArmor

	sudo vim /etc/apparmor.d/usr.sbin.mysqld

Delete the lines starting with */var/lib/mysql*.
In their place paste the following...

	  /usr/local/perseus/mysql/data/ r,
	  /usr/local/perseus/mysql/data/** rwk,
	#  /var/lib/mysql/ r,
	#  /var/lib/mysql/** rwk,

Restart AppArmor

	sudo /etc/init.d/apparmor reload

Restart MySQL

	sudo service mysql restart

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

# Update catalog instance with another instance's database 
## ( AKA refresh Development with Production data )
## ( AKA how to use mysqldump )
For simplicities sake I'll call the source catalog instance "Production" and the destination catalog instance "Development".

SSH to production's host, dump the database, zip it up, and copy it to your workstation.

	ssh catalog
	mysqldump -u root -p perseus_blacklight > ~/perseus_blacklight.sql
	tar czvf perseus_blacklight.tar.gz perseus_blacklight.sql
	exit

From your workstation, copy the zipped database dump file to the destination's host.

	scp catalog:~/perseus_blacklight.tar.gz ~/Desktop/
	scp ~/Desktop/perseus_blacklight.tar.gz catalog1:~/
	exit

SSH to the destination's host, and decompress the database dump file.

	ssh catalog1
	tar xvzf perseus_blacklight.tar.gz	

Backup the existing data in case something goes horribly wrong, so restoring the data is possible.

	mkdir ~/bkup
	mysqldump -u root -p perseus_blacklight > ~/bkup/perseus_blacklight.bkup.sql	

Import the new data.

	mysql -u root -p perseus_blacklight < perseus_blacklight.sql

Update solr.

	curl http://localhost:8080/solr/db/update -H "Content-type: text/xml" \--data-binary '<delete><query>*:*</query></delete>';
	curl http://localhost:8080/solr/db/update -H "Content-type: text/xml" \--data-binary '<commit />';
	curl http://localhost:8080/solr/db/update -H  "Content-type: text/xml" \--data-binary '<optimize />';
	curl http://localhost:8080/solr/db/dataimport?command=full-import;
