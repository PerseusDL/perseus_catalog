<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts3/ti"
    xmlns:atom="http://www.w3.org/2005/Atom"
    exclude-result-prefixes="xs cts"
    version="2.0">
    
    <xsl:param name="e_outputDir"/>
    <xsl:param name="e_baseUriDir" select="'http://data.perseus.org/catalog/'"/>
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:template match="/">
        <xsl:for-each select="//cts:textgroup">
            <!-- create file path ns/textgroup.xml -->
            <xsl:variable name="file" select="concat($e_outputDir,'/',replace(substring-after(@urn,'urn:cts'),':','/'),'.xml')"/>
            <xsl:variable name="baseUri" select="concat($e_baseUriDir,@urn)"/>
            <xsl:result-document href="{$file}">
                <atom:feed xmlns:atom="http://www.w3.org/2005/Atom">
                    <!-- TODO final id decision -->
                    <atom:id><xsl:value-of select="concat($baseUri,'/atom')"/></atom:id>
                    <atom:link href="{concat($baseUri,'/atom')}" type="application/atom+xml" rel="self"/>
                    <!-- TODO take from input -->
                    <atom:updated>2013-04-24T16:26:35.897-04:00</atom:updated>
                    <atom:entry>
                        <atom:id><xsl:value-of select="concat($baseUri,'/atom#ctsti')"/></atom:id>
                        <atom:link href="{concat($baseUri,'/atom#ctsti')}"
                            type="application/atom+xml" rel="self"/>
                        <atom:content type="text/xml">
                            <TextInventory xmlns="http://chs.harvard.edu/xmlns/cts3/ti">
                                <xsl:copy-of select="//cts:TextInventory/@*"/>
                                <xsl:copy-of select="//cts:TextInventory/*[not(local-name(.) = 'textgroup')]" copy-namespaces="yes"/>
                                <textgroup xmlns="http://chs.harvard.edu/xmlns/cts3/ti">
                                    <xsl:copy-of select="@*"/>
                                    <xsl:copy-of select="*[not(local-name(.) = 'entry')]"/>
                                </textgroup>
                            </TextInventory>
                        </atom:content>
                    </atom:entry>
                    <xsl:copy-of select="atom:entry"/>
                </atom:feed>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>