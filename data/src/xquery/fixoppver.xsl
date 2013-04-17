<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ti="http://chs.harvard.edu/xmlns/cts3/ti"
    xmlns:mods="http://www.loc.gov/mods/v3"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:param name="e_base"/>
    <xsl:param name="e_lang"/>
    <xsl:param name="e_ns"/>
    <xsl:param name="e_newVer"/>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="ti:edition|ti:translation">
        <xsl:variable name="testurn" select="concat($e_base,'.','opp-',$e_lang)"/>
        <xsl:variable name="newurn" select="concat($e_base,'.','opp-',$e_lang,$e_newVer)"/>
        <xsl:choose>
            <xsl:when test="starts-with(@urn,$testurn)">
                <xsl:copy>
                    <xsl:attribute name="urn"><xsl:value-of select="$newurn"/></xsl:attribute>
                    <xsl:attribute name="projid"><xsl:value-of select="concat($e_ns,':','opp-',$e_lang,$e_newVer)"/></xsl:attribute>
                    <xsl:apply-templates select="@*[not(local-name(.) = 'urn') and not(local-name(.) = 'projid')]"/>
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mods:identifier[@type='ctsurn']">
        <xsl:variable name="testurn" select="concat($e_base,'.','opp-',$e_lang)"/>
        <xsl:variable name="newurn" select="concat($e_base,'.','opp-',$e_lang,$e_newVer)"/>
        <xsl:choose>
            <xsl:when test="starts-with(.,$testurn)">
                <xsl:copy>
                   <xsl:apply-templates select="@*"/>
                   <xsl:value-of select="$newurn"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@*">
        <xsl:copy/>
    </xsl:template>
    
    <xsl:template match="node()">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>