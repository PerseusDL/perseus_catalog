<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti"
    xmlns:atom="http://www.w3.org/2005/Atom"
    >
    <xsl:param name="e_inputDir"/>
    <xsl:param name="e_outputDir"/>
    <xsl:param name="e_feedOutputDir"/>
    <xsl:template match="/">
      <xsl:apply-templates select="//cts:work"/>
    </xsl:template>
  
    <xsl:template match="cts:work">
        <xsl:variable name="filename" select="concat($e_inputDir,'/',substring-after(substring-after(@urn,'urn:cts:'),':'),'.xml')"/>
          <xsl:if test="doc-available($filename)">
            <xsl:message>Found <xsl:value-of select="$filename"/></xsl:message>
            <xsl:variable name="feed" select="doc($filename)"/>
            <xsl:call-template name="outputmods">
              <xsl:with-param name="feed" select="$feed"></xsl:with-param>
              <xsl:with-param name="modsfiles" select="distinct-values($feed//atom:entry/atom:id[ends-with(.,'#mods')])"/>
              <xsl:with-param name="index" select="xs:int(1)"/>
            </xsl:call-template>
            
            <xsl:for-each select="$feed//cts:edition|$feed//cts:translation">
              <xsl:variable name="urn" select="@urn"/>
              <xsl:variable name="feedfile">
                <!-- file name will be /ns/tg/work/tg.work.ed.atom.xml -->
                <xsl:analyze-string select="$urn" regex="urn:cts:(.*?):((.*?)\.(.*?)\.(.*?))$">
                  <xsl:matching-substring>
                    <xsl:value-of select="concat($e_feedOutputDir,'/',
                      string-join((regex-group(1),regex-group(3),regex-group(4)),'/'),'/',regex-group(2),'.atom.xml')"></xsl:value-of></xsl:matching-substring>
                </xsl:analyze-string>
              </xsl:variable> 
              <xsl:result-document href="{$feedfile}" indent="yes" method="xml"  media-type="text/xml" xml:space="default">
                  <xsl:apply-templates select="."></xsl:apply-templates>  
              </xsl:result-document>    
            </xsl:for-each>
          </xsl:if>  
    </xsl:template>
  
    <!-- create a feed for just the expression 
         which contains the expression MODS file, the expression MADS file, and the TI structure for the expression itself
    -->
    <xsl:template match="cts:edition|cts:translation">
      <xsl:variable name="parentfeed" select="ancestor::atom:feed"/>
      <xsl:variable name="parententry" select="ancestor::cts:TextInventory/parent::atom:content/parent::atom:entry"/>
      <xsl:variable name="workurn" select="../@urn"/>
      <xsl:variable name="versionurn" select="@urn"/>
      <xsl:variable name="baseUri" select="substring-before($parententry/atom:id,$workurn)"/>
      <atom:feed>
          <atom:id><xsl:value-of select="concat($baseUri,$versionurn,'/atom')"/></atom:id>
          <atom:title>Perseus Catalog: atom feed for CTS <xsl:value-of select="local-name(.)"/><xsl:text> </xsl:text><xsl:value-of select="@urn"/></atom:title>
        <atom:link rel="self" type="application/atom+xml" href="{concat($baseUri,$versionurn,'/atom')}"/>
          <atom:link rel="alternate" type="text/html" href="{concat($baseUri,'/html')}"/>
          <xsl:copy-of select="$parententry/atom:author"/>
          <xsl:copy-of select="$parententry/atom:updated"/>
          <!-- this is the CTS Text Inventory entry -->
          <atom:entry>
            <atom:id><xsl:value-of select="concat($baseUri,@urn,'/atom')"/></atom:id>
            <atom:title>Perseus Catalog: Text Inventory excerpt for CTS <xsl:value-of select="local-name(.)"/><xsl:text> </xsl:text><xsl:value-of select="@urn"/></atom:title>
            <atom:link rel="self" type="application/atom+xml" href="{concat($baseUri,$versionurn,'/atom#ctsti')}"/>
            <atom:link rel="alternate" type="text/html" href="{replace($parententry/atom:link[@type='text/html']/@href,$workurn,@urn)}"/>
            <xsl:copy-of select="$parententry/atom:author"/>
            <xsl:copy-of select="$parententry/atom:updated"/>
            <atom:content type="text/xml">
              <TextInventory xmlns="http://chs.harvard.edu/xmlns/cts3/ti">
                <xsl:copy-of select="$parententry/atom:content/cts:TextInventory/@*" exclude-result-prefixes="cts" copy-namespaces="no"/>
                <xsl:copy-of select="$parententry/atom:content/cts:TextInventory/*[local-name(.) != 'textgroup']" exclude-result-prefixes="cts" copy-namespaces="no"/>
                <textgroup xmlns="http://chs.harvard.edu/xmlns/cts3/ti">
                  <xsl:copy-of select="$parententry/atom:content/cts:TextInventory/cts:textgroup/@*" exclude-result-prefixes="cts" copy-namespaces="no"/>
                  <work xmlns="http://chs.harvard.edu/xmlns/cts3/ti">
                    <xsl:copy-of select="../@*" exclude-result-prefixes="cts" copy-namespaces="no"/>
                    <xsl:copy-of select="." exclude-result-prefixes="cts" copy-namespaces="no"/>
                  </work>
                </textgroup>                
              </TextInventory>
            </atom:content>
          </atom:entry>
          <!--these are the MODS file entries -->
          <xsl:copy-of select="$parentfeed/atom:entry[atom:id[matches(.,concat('.*',$versionurn,'/atom#mods'))]]"/>
          <!-- these are the MADS file entries we need to change the id to match the version -->
          <!-- TODO remove hack sfor urn:cts: after 20130513 feed -->
          <xsl:for-each select="$parentfeed/atom:entry[atom:id[matches(.,concat('.*',substring-after($workurn,'urn:cts:'),'/atom#mads'))]]">
            <atom:entry>
                <atom:id><xsl:value-of select="replace(atom:id,substring-after($workurn,'urn:cts:'),$versionurn)"/></atom:id>
              <atom:link rel="self" type="application/atom+xml" href="{replace(atom:link[@rel='self']/@href,substring-after($workurn,'urn:cts:'),$versionurn)}"/>
                <xsl:copy-of select="atom:link[@rel='alternate']" exclude-result-prefixes="#all" copy-namespaces="no"/>
                <xsl:copy-of select="atom:author" exclude-result-prefixes="#all" copy-namespaces="no"/>
                <xsl:copy-of select="atom:title" exclude-result-prefixes="#all" copy-namespaces="no"/>
                <xsl:copy-of select="atom:content" exclude-result-prefixes="#all" copy-namespaces="no"/>
            </atom:entry>  
          </xsl:for-each>
      </atom:feed>
    </xsl:template>

    <xsl:template match="*"/>
    <xsl:template name="outputmods">
        <xsl:param name="feed" as="node()"/>
        <xsl:param name="modsfiles"/>
        <xsl:param name="index"/>
        <xsl:choose>
          <xsl:when test="$modsfiles[$index]">
            <!-- HACK to avoid dupes which shouldn't be in the feeds in the first place see Manis 1205 -->
            <xsl:variable name="entry" select="($feed//atom:entry[atom:id[text() = $modsfiles[$index]]])[1]"/>
            <xsl:variable name="filename">
              <!-- file name will be /ns/tg/work/ed/tg.work.ed.modsN.xml -->
              <xsl:analyze-string select="$entry/atom:id" regex=".*/urn:cts:(.*?):((.*?)\.(.*?)\.(.*?))/atom#mods$">
                <xsl:matching-substring>
                  <xsl:value-of select="concat($e_outputDir,'/',
                    string-join((regex-group(1),regex-group(3),regex-group(4),regex-group(5)),'/'),'/',regex-group(2),'.mods',$index,'.xml')"></xsl:value-of></xsl:matching-substring>
              </xsl:analyze-string>
            </xsl:variable> 
            <xsl:result-document href="{$filename}" indent="yes" method="xml"  media-type="text/xml" xml:space="default">
              <xsl:copy-of select="$entry//mods:mods"/>
            </xsl:result-document>    
            <xsl:call-template name="outputmods">
              <xsl:with-param name="feed" select="$feed"/>
              <xsl:with-param name="modsfiles" select="$modsfiles[position() > $index]"/>
              <xsl:with-param name="index" select="$index+1"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise/>
        </xsl:choose>
        
    </xsl:template>
</xsl:stylesheet>