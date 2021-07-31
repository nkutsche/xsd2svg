<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:nk="http://www.nkutsche.com/" 
    xmlns:svg="http://www.w3.org/2000/svg" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns="http://www.w3.org/2000/svg"
    exclude-result-prefixes="#all"
    version="3.0"
    >
    
    
        
    <xsl:template match="svg:svg" mode="nk:xsd2svg-transform">
        <xsl:variable name="content">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="thisSize" select="nk:number(@width), nk:number(@height)" as="xs:double+"/>
        <xsl:variable name="contentSize" select="nk:number(max($content/svg:*/@nk:width)), nk:number(max($content/svg:*/@nk:height))" as="xs:double+"/>
        <xsl:variable name="corrSize" select="max(($thisSize[1], $contentSize[1])), max(($thisSize[2], $contentSize[2]))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="width" select="$corrSize[1]"/>
            <xsl:attribute name="height" select="$corrSize[2]"/>
            <xsl:attribute name="nk:width" select="$corrSize[1]"/>
            <xsl:attribute name="nk:height" select="$corrSize[2]"/>
            <xsl:copy-of select="$content"/>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="svg:g" mode="nk:xsd2svg-transform">
        <xsl:variable name="content">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="nk:width" select="nk:number(max($content/svg:*/@nk:width))"/>
            <xsl:attribute name="nk:height" select="nk:number(max($content/svg:*/@nk:height))"/>
            <xsl:sequence select="$content"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg:*[@transform]" mode="nk:xsd2svg-transform" priority="10">
        <xsl:variable name="content">
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="contentSize" select="nk:number(max($content/svg:*/@nk:width)), nk:number(max($content/svg:*/@nk:height))" as="xs:double+"/>
        <xsl:variable name="size" select="nk:translateSize(@transform, $contentSize)"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="nk:width" select="$size[1]"/>
            <xsl:attribute name="nk:height" select="$size[2]"/>
            <xsl:copy-of select="$content"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:function name="nk:translateSize" as="xs:double*">
        <xsl:param name="transform" as="xs:string"/>
        <xsl:param name="size" as="xs:double+"/>
        <xsl:variable name="regex" select="'translate\(([^\)]*)\)'"/>
        <xsl:choose>
            <xsl:when test="matches($transform, $regex)">
                <xsl:analyze-string select="$transform" regex="{$regex}">
                    <xsl:matching-substring>
                        <xsl:variable name="tanslateX" select="xs:double(tokenize(regex-group(1), ',')[1])"/>
                        <xsl:variable name="tanslateY" select="xs:double(tokenize(regex-group(1), ',')[2])"/>
                        <xsl:sequence select="$size[1] + $tanslateX, $size[2] + $tanslateY"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$size"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
</xsl:stylesheet>