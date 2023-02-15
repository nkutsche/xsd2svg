<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:nk="http://www.nkutsche.com/" 
    xmlns:svg="http://www.w3.org/2000/svg" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xpath-default-namespace="http://www.w3.org/2000/svg"
    xmlns="http://www.w3.org/2000/svg"
    exclude-result-prefixes="#all"
    version="3.0"
    >
    
    
        
    <xsl:template match="svg[@nk:width]/@width[. castable as xs:decimal]" mode="nk:xsd2svg-zindex">
        <xsl:attribute name="width" select="../@nk:width"/>
    </xsl:template>
    <xsl:template match="svg[@nk:height]/@height[. castable as xs:decimal]" mode="nk:xsd2svg-zindex">
        <xsl:attribute name="height" select="../@nk:height"/>
    </xsl:template>
    
    
    
    <xsl:template match="svg[not(parent::svg:*)]" priority="15" mode="nk:xsd2svg-zindex">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:variable name="this" select="."/>
            <xsl:variable name="ZLevels" select="nk:getZLevels($this/*)"/>
            <xsl:for-each select="$ZLevels">
                <xsl:sort select="." data-type="number"/>
                
                <xsl:variable name="level" select="."/>
                <xsl:apply-templates select="$this/*" mode="#current">
                    <xsl:with-param name="z-index" select="$level"/>
                </xsl:apply-templates>
            </xsl:for-each>
            
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg:*" priority="10" mode="nk:xsd2svg-zindex">
        <xsl:param name="z-index" select="0"/>
        <xsl:variable name="thisLevels" select="nk:getZLevels(.)"/>
        
        <xsl:variable name="copyId" select="min($thisLevels) = $z-index"/>
        
        <xsl:if test="$z-index = $thisLevels">
            <xsl:copy>
                <xsl:apply-templates select="
                      if ($copyId) 
                    then (@*) 
                    else (@* except @id)
                    " mode="#current"/>
                <xsl:attribute name="nk:z-index" select="nk:getInhertZ(.)"/>
                <xsl:attribute name="nk:z-levels" select="$thisLevels"/>
                <xsl:attribute name="nk:z-filter" select="$z-index"/>
                <xsl:apply-templates select="node()" mode="#current">
                    <xsl:with-param name="z-index" select="$z-index"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="nk:getZLevels" as="xs:double*">
        <xsl:param name="element" as="element()*"/>
        <xsl:variable name="selfLevel" select="for $e in $element return nk:getInhertZ($e)"/>
        <xsl:variable name="childLevels" select=" if ($element/*) then (nk:getZLevels($element/*)) else ()"/>
        <xsl:variable name="distLev" select="distinct-values(($selfLevel, $childLevels))"/>
        <xsl:sequence select="for $dl in $distLev return xs:double($dl)"/>
    </xsl:function>
    
    <xsl:function name="nk:getInhertZ" as="xs:double">
        <xsl:param name="e" as="element()"/>
        <xsl:variable name="root" select="root($e)"/>
        <xsl:variable name="parent" select="$e/parent::*"/>
        <xsl:variable name="z-index" select="$e/@nk:z-index"/>
        <xsl:value-of select="nk:number( 
            if ($z-index) 
            then ($z-index) 
            else $parent/nk:getInhertZ(.)
            )"/>
    </xsl:function>
    
    
</xsl:stylesheet>