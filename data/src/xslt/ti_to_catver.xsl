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
    <xsl:output indent="yes" method="text" />
    <xsl:variable name="quotechar" select="'&#x22;'"/>
    <xsl:variable name="esc" select="$quotechar"/>
    <xsl:template match="/">
        <xsl:value-of select="string-join(('urn','version','label_eng','desc_eng','type','has_mods','urn_status','redirect_to','member_of','created_by','edited_by'),'|')"/>
        <xsl:text>&#x0a;</xsl:text>
        <xsl:for-each select="//(cts:edition|cts:translation)">
            <xsl:variable name="id" select="concat('urn:cite:perseus:catver.',xs:string(position()),'.1')"/>
            <xsl:variable name="urn" select="@urn"/>
            <xsl:variable name="label_eng">
                <xsl:choose>
                    <xsl:when test="cts:label">"<xsl:value-of select="replace(cts:label[1],$quotechar,concat($esc,$quotechar))"/>"</xsl:when>
                    <xsl:otherwise>"<xsl:value-of select="replace(../*:title,$quotechar,concat($esc,$quotechar))"/>"</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="desc_eng" select="concat('&quot;',replace(cts:description,$quotechar,concat($esc,$quotechar)),'&quot;')"/>
            <xsl:variable name="type" select="local-name(.)"/>
            <xsl:variable name="has_mods">
                <xsl:choose>
                    <xsl:when test="//atom:id[ends-with(.,concat($urn,'/atom#mods'))]">
                        <xsl:text>true</xsl:text>
                    </xsl:when> 
                    <xsl:otherwise><xsl:text>false</xsl:text></xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="urn_status" select="'published'"/>
            <xsl:variable name="redirect_to" select="''"/>
            <xsl:variable name="member_of">
                <xsl:choose>
                    <xsl:when test="cts:memberof"><xsl:value-of select="cts:memberof/@collection"/></xsl:when>
                    <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="created_by" select="'feed_aggregator'"/>
            <xsl:variable name="edited_by" select="'feed_aggregator'"/>
            <xsl:value-of select="string-join(($id,$urn,$label_eng,$desc_eng,$type,$has_mods,$urn_status,$redirect_to,$member_of,$created_by,$edited_by),'|')"/>
            <xsl:text>&#x0a;</xsl:text>
        </xsl:for-each>
    </xsl:template>
    
</xsl:stylesheet>