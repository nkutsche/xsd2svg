<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:es="http://www.escali.schematron-quickfix.com/" 
    xmlns:svg="http://www.w3.org/2000/svg" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xpath-default-namespace="http://www.w3.org/2000/svg"
    xmlns="http://www.w3.org/2000/svg"
    exclude-result-prefixes="#all"
    version="3.0"
    >
    
    
        
    <xsl:template match="svg[@es:width]/@width[. castable as xs:decimal]" mode="es:xsd2svg-zindex">
        <xsl:attribute name="width" select="../@es:width"/>
    </xsl:template>
    <xsl:template match="svg[@es:height]/@height[. castable as xs:decimal]" mode="es:xsd2svg-zindex">
        <xsl:attribute name="height" select="../@es:height"/>
    </xsl:template>
    
    
    
    <xsl:template match="*[namespace-uri()='']/svg" priority="15" mode="es:xsd2svg-zindex">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:for-each select="*">
                <xsl:variable name="this" select="."/>
                <xsl:variable name="ZLevels" select="es:getZLevels($this)"/>
                <xsl:for-each select="$ZLevels">
                    <xsl:sort select="." data-type="number"/>
                    <xsl:variable name="level" select="."/>
                    <xsl:apply-templates select="$this" mode="#current">
                        <xsl:with-param name="z-index" select="$level"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="svg:*" priority="10" mode="es:xsd2svg-zindex">
        <xsl:param name="z-index" select="0"/>
        <xsl:variable name="thisLevels" select="es:getZLevels(.)"/>
        
        <xsl:if test="$z-index = $thisLevels">
            <xsl:copy>
                <xsl:apply-templates select="@*" mode="#current"/>
                <xsl:attribute name="es:z-index" select="es:getInhertZ(.)"/>
                <xsl:attribute name="es:z-levels" select="$thisLevels"/>
                <xsl:attribute name="es:z-filter" select="$z-index"/>
                <xsl:apply-templates select="node()" mode="#current">
                    <xsl:with-param name="z-index" select="$z-index"/>
                </xsl:apply-templates>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="es:getZLevels" as="xs:double*">
        <xsl:param name="element" as="element()*"/>
        <xsl:variable name="selfLevel" select="for $e in $element return es:getInhertZ($e)"/>
        <xsl:variable name="childLevels" select=" if ($element/*) then (es:getZLevels($element/*)) else ()"/>
        <xsl:variable name="distLev" select="distinct-values(($selfLevel, $childLevels))"/>
        <xsl:sequence select="for $dl in $distLev return xs:double($dl)"/>
    </xsl:function>
    
    <xsl:key name="zLevelById" match="@es:z-index" use="for $e in ..//* return generate-id($e)"/>
    <xsl:function name="es:getInhertZ" as="xs:double">
        <xsl:param name="element" as="element()"/>
        <xsl:variable name="root" select="root($element)"/>
        <xsl:value-of select="es:number(key('zLevelById', generate-id($element), $root))"/>
    </xsl:function>
    
    
</xsl:stylesheet>