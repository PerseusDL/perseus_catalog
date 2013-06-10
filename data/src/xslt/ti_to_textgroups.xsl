<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts/ti"
    xmlns:atom="http://www.w3.org/2005/Atom"
    exclude-result-prefixes="xs cts"
    version="2.0">
    
    <xsl:param name="e_outputDir"/>
    <xsl:param name="e_baseUriDir" select="'http://data.perseus.org/catalog/'"/>
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:template match="/">
        <xsl:variable name="author" select="atom:author"/>
        <xsl:variable name="updated" select="atom:updated"/>
        <xsl:variable name="rights" select="atom:rights"/>
        <xsl:for-each select="//cts:textgroup">
            <!-- create file path ns/textgroup.xml -->
            <xsl:variable name="file" select="concat($e_outputDir,'/',replace(substring-after(@urn,'urn:cts'),':','/'),'.atom.xml')"/>
            <xsl:variable name="baseUri" select="concat($e_baseUriDir,@urn)"/>
            <xsl:result-document href="{$file}">
                <atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
                    <atom:id><xsl:value-of select="concat($baseUri,'/atom')"/></atom:id>
                    <atom:title>The Perseus Catalog: atom feed for CTS textgroup <xsl:value-of select="@urn"/></atom:title>
                    <xsl:copy-of select="$updated"/>
                    <xsl:copy-of select="$author"/>
                    <xsl:copy-of select="$rights"/>
                    <atom:link href="{concat($baseUri,'/atom')}" type="application/atom+xml" rel="self"/>
                    <atom:entry>
                        <atom:id><xsl:value-of select="concat($baseUri,'/atom#ctsti')"/></atom:id>
                        <atom:title>The Perseus Catalog: Text Inventory for CTS textgroup <xsl:value-of select="@urn"/></atom:title>
                        <atom:link href="{concat($baseUri,'/atom#ctsti')}"
                            type="application/atom+xml" rel="self"/>
                        <atom:link href="{concat($baseUri,'/html')}"
                            type="text/html" rel="alternate"/>
                        <atom:content type="text/xml">
                            <TextInventory xmlns="http://chs.harvard.edu/xmlns/cts/ti">
                                <xsl:copy-of select="//cts:TextInventory/@*"/>
                                <xsl:copy-of select="//cts:TextInventory/*[not(local-name(.) = 'textgroup')]" copy-namespaces="yes"/>
                                <textgroup xmlns="http://chs.harvard.edu/xmlns/cts/ti">
                                    <xsl:copy-of select="@*"/>
                                    <xsl:copy-of select="*[not(local-name(.) = 'entry')]"  exclude-result-prefixes="#all" copy-namespaces="no"/>
                                </textgroup>
                            </TextInventory>
                        </atom:content>
                    </atom:entry>
                    <xsl:copy-of select="atom:entry" exclude-result-prefixes="cts" copy-namespaces="no"/>
                </atom:feed>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>