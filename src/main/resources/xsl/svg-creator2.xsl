<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="xs sqf" xpath-default-namespace="http://www.w3.org/2000/svg" version="2.0">

    <xsl:output saxon:next-in-chain="svg-creator3.xsl"/>

    <xsl:include href="svg-paths.xsl"/>

    <!-- 
        copies all nodes:
    -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg:svg">
        <xsl:variable name="content">
            <xsl:apply-templates select="node()"/>
        </xsl:variable>
        <xsl:variable name="thisSize" select="sqf:number(@width), sqf:number(@height)" as="xs:double+"/>
        <xsl:variable name="contentSize" select="sqf:number(max($content/svg:*/@sqf:width)), sqf:number(max($content/svg:*/@sqf:height))" as="xs:double+"/>
        <xsl:variable name="corrSize" select="max(($thisSize[1], $contentSize[1])), max(($thisSize[2], $contentSize[2]))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="sqf:width" select="$corrSize[1]"/>
            <xsl:attribute name="sqf:height" select="$corrSize[2]"/>
            <xsl:copy-of select="$content"/>
        </xsl:copy>
        
    </xsl:template>
    
    <xsl:template match="svg:*[@transform]">
        <xsl:variable name="content">
            <xsl:apply-templates select="node()"/>
        </xsl:variable>
        <xsl:variable name="contentSize" select="sqf:number(max($content/svg:*/@sqf:width)), sqf:number(max($content/svg:*/@sqf:height))" as="xs:double+"/>
        <xsl:variable name="size" select="sqf:translateSize(@transform, $contentSize)"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="sqf:width" select="$size[1]"/>
            <xsl:attribute name="sqf:height" select="$size[2]"/>
            <xsl:copy-of select="$content"/>
        </xsl:copy>
    </xsl:template>

    <xsl:function name="sqf:translateSize" as="xs:double*">
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

    <!--<xsl:template match="svg">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="sqf:height" select="@height"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg">
        <xsl:variable name="content">
            <xsl:apply-templates select="node()"/>
        </xsl:variable>
        <xsl:variable name="nextSvgLevel" select="sqf:getNextLevel($content/*)"/>
        <xsl:variable name="maxDisplayWidth" select="sqf:number(max(($nextSvgLevel/@sqf:displayW, @sqf:displayW)))"/>
        <xsl:variable name="maxDisplayHeight" select="sqf:number(max(($nextSvgLevel/@sqf:displayH, @sqf:displayH)))"/>
        <xsl:copy>
            <xsl:apply-templates select="@*">
                <xsl:with-param name="displayWidth" select="$maxDisplayWidth"/>
                <xsl:with-param name="displayHeight" select="$maxDisplayHeight"/>
            </xsl:apply-templates>
            <xsl:copy-of select="$content"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg/@width[. castable as xs:decimal]">
        <xsl:param name="displayWidth" as="xs:decimal" select="0"/>
        <xsl:attribute name="width" select="xs:decimal(.) + $displayWidth"/>
        <xsl:attribute name="sqf:width" select="."/>
        <xsl:attribute name="sqf:displayW" select="$displayWidth"/>
    </xsl:template>
    
    <xsl:template match="svg/@height[. castable as xs:decimal]">
        <xsl:param name="displayHeight" as="xs:decimal" select="0"/>
        <xsl:attribute name="height" select="xs:decimal(.) + $displayHeight"/>
        <xsl:attribute name="sqf:height" select="."/>
        <xsl:attribute name="sqf:displayH" select="$displayHeight"/>
    </xsl:template>
    
    <xsl:function name="sqf:getNextLevel" as="element(svg)*">
        <xsl:param name="elements" as="element()*"/>
        <xsl:for-each select="$elements">
            <xsl:choose>
                <xsl:when test="self::svg">
                    <xsl:sequence select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="sqf:getNextLevel(./*)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:function>-->

</xsl:stylesheet>
