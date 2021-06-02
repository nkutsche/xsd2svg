<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:svg="http://www.w3.org/2000/svg" xmlns:html="http://www.w3.org/1999/xhtml" xmlns="http://www.w3.org/2000/svg" xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="xs sqf" xpath-default-namespace="http://www.w3.org/2000/svg" version="2.0">

    <xsl:output saxon:next-in-chain="svg-creator4.xsl"/>
    <xsl:include href="functions.xsl"/>

    <!-- 
        copies all nodes:
    -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg[@sqf:width]/@width[. castable as xs:decimal]">
        <xsl:attribute name="width" select="../@sqf:width"/>
    </xsl:template>
    <xsl:template match="svg[@sqf:height]/@height[. castable as xs:decimal]">
        <xsl:attribute name="height" select="../@sqf:height"/>
    </xsl:template>
    


    <xsl:template match="*[namespace-uri()='']/svg" priority="15">
        <xsl:copy>
            <xsl:attribute name="sqf:msg" select="'hallo'"/>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each select="*">
                <xsl:variable name="this" select="."/>
                <xsl:variable name="ZLevels" select="sqf:getZLevels($this)"/>
                <xsl:for-each select="$ZLevels">
                    <xsl:sort select="." data-type="number"/>
                    <xsl:variable name="level" select="."/>
                    <xsl:apply-templates select="$this">
                        <xsl:with-param name="z-index" select="$level"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="svg:*" priority="10">
        <xsl:param name="z-index" select="0"/>
        <xsl:variable name="thisLevels" select="sqf:getZLevels(.)"/>

        <xsl:if test="$z-index = $thisLevels">
            <xsl:copy>
                <xsl:apply-templates select="@*"/>
                <xsl:attribute name="sqf:z-index" select="sqf:getInhertZ(.)"/>
                <xsl:attribute name="sqf:z-levels" select="$thisLevels"/>
                <xsl:attribute name="sqf:z-filter" select="$z-index"/>
                <xsl:apply-templates select="node()">
                    <xsl:with-param name="z-index" select="$z-index"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:function name="sqf:getZLevels" as="xs:double*">
        <xsl:param name="element" as="element()*"/>
        <xsl:variable name="selfLevel" select="for $e in $element return sqf:getInhertZ($e)"/>
        <xsl:variable name="childLevels" select=" if ($element/*) then (sqf:getZLevels($element/*)) else ()"/>
        <xsl:variable name="distLev" select="distinct-values(($selfLevel, $childLevels))"/>
        <xsl:sequence select="for $dl in $distLev return xs:double($dl)"/>
    </xsl:function>

    <xsl:key name="zLevelById" match="@sqf:z-index" use="for $e in ..//* return generate-id($e)"/>
    <xsl:function name="sqf:getInhertZ" as="xs:double">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="root" select="root($element)"/>
        <xsl:value-of select="sqf:number(key('zLevelById', generate-id($element), $root))"/>
    </xsl:function>

</xsl:stylesheet>
