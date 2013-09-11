<!-- Copyright 2013 The Perseus Project, Tufts University, Medford MA
This free software: you can redistribute it and/or modify it under the terms of the GNU General Public License published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This software is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
See http://www.gnu.org/licenses/.-->

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cts="http://chs.harvard.edu/xmlns/cts/ti"
    xmlns:atom="http://www.w3.org/2005/Atom"
    exclude-result-prefixes="xs cts"
    version="2.0">
    <xsl:output indent="yes" method="text"/>
    
    <xsl:template match="/">
        <xsl:value-of select="string-join(('urn','textgroup','groupname_eng','has_mads','mads_possible','notes','urn_status','created_by','edited_by'),'|')"/>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:for-each select="//cts:textgroup">
            <xsl:variable name="id" select="concat('urn:cite:perseus:cattg.',xs:string(position()),'.1')"/>
            <xsl:variable name="urn" select="@urn"/>
            <xsl:variable name="groupname_eng" select="cts:groupname"/>
            <xsl:variable name="has_mads">
                <xsl:choose>
                    <xsl:when test="//atom:id[. = concat('http://data.perseus.org/catalog/', $urn, '/atom#mads-1')]">true</xsl:when>
                    <xsl:otherwise>false</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="mads_possible" select="'true'"/>
            <xsl:variable name="notes" select="''"/>
            <xsl:variable name="urn_status" select="'published'"/>
            <xsl:variable name="created_by" select="'feed_aggregator'"/>
            <xsl:variable name="edited_by" select="'feed_aggregator'"/>
            <xsl:value-of select="string-join(($id,$urn,$groupname_eng,$has_mads,$mads_possible,$notes,$urn_status,$created_by,$edited_by),'|')"/>
            <xsl:text>&#x0a;</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>