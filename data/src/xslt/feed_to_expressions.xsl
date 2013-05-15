<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs atom"
    version="2.0"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti"
    xmlns:atom="http://www.w3.org/2005/Atom"
    >
    <xsl:param name="e_inputDir"/>
    <xsl:param name="e_outputDir"/>
    <xsl:template match="/">
      <xsl:apply-templates select="//cts:work"/>
    </xsl:template>
    <xsl:template match="cts:work">
        <xsl:variable name="filename" select="concat($e_inputDir,'/',substring-after(substring-after(@urn,'urn:cts:'),':'),'.xml')"/>
          <xsl:if test="doc-available($filename)">
            <xsl:variable name="feed" select="doc($filename)"/>
            <xsl:call-template name="outputmods">
              <xsl:with-param name="feed" select="$feed"></xsl:with-param>
              <xsl:with-param name="modsfiles" select="distinct-values($feed//atom:entry/atom:id[ends-with(.,'#mods')])"/>
              <xsl:with-param name="index" select="xs:int(1)"/>
            </xsl:call-template>   
          </xsl:if>  
        
    </xsl:template>
  
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