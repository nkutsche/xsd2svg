<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:es="http://www.escali.schematron-quickfix.com/" xmlns:svg="http://www.w3.org/2000/svg" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" exclude-result-prefixes="#all" version="3.0">
    
    <xsl:mode name="es:create-docs-tooltips"/>

    <xsl:template match="svg:svg[svg:foreignObject/xs:annotation]" mode="es:xsd2svg-docs">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        
        <xsl:variable name="annotation" select="svg:foreignObject/xs:annotation"/>
        <xsl:variable name="docs-id" select="(@id, generate-id(.))[1]"/>
        
        <xsl:variable name="rectW" select="@width"/>
        <xsl:variable name="rectH" select="@height"/>
        
        <xsl:variable name="cY" select="(svg:foreignObject/@es:cY, 15)[1]"/>
        <xsl:variable name="docs-colors" select="(svg:foreignObject/@es:color-scheme[. != 'null']/parse-json(.), es:getColors('#default', $schemaSetConfig))[1]"/>
        
        <xsl:variable name="docs" select="es:create-docs-tooltips($annotation, $docs-id, $docs-colors, $cY)"/>
        
        <xsl:variable name="docs-y" select="($rectH div 2 - $cY, 0) => max()"/>
        
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:attribute name="id" select="$docs-id"/>
            <xsl:apply-templates select="node() except svg:foreignObject" mode="#current"/>
        </xsl:copy>
        <g transform="translate({$rectW},{$rectH div 2 - $cY})" es:z-index="1000">
            <xsl:sequence select="$docs"/>
        </g>
    </xsl:template>
    
    <xsl:function name="es:create-docs-tooltips" as="element(svg:svg)?">
        <xsl:param name="annotation" as="element(xs:annotation)+"/>
        <xsl:param name="hover_id" as="xs:string"/>
        <xsl:param name="color" as="map(*)"/>
        <xsl:param name="cY" as="xs:double"/>
        <xsl:sequence select="es:create-docs-tooltips($annotation, $hover_id, $color, $cY, ())"/>
    </xsl:function>
    <xsl:function name="es:create-docs-tooltips" as="element(svg:svg)?">
        <xsl:param name="annotation" as="element(xs:annotation)+"/>
        <xsl:param name="hover_id" as="xs:string"/>
        <xsl:param name="color" as="map(*)"/>
        <xsl:param name="cY" as="xs:double"/>
        <xsl:param name="invisible_ids" as="xs:string*"/>
        
        <xsl:variable name="textContent" select="string-join($annotation/xs:documentation, '')"/>
        <xsl:variable name="textLength" select="es:renderedTextLength($textContent, 'Arial', 'plain', 11)"/>
        
        <xsl:variable name="content">
            <xsl:apply-templates select="$annotation/xs:documentation" mode="es:create-docs-tooltips">
                <xsl:with-param name="text-width" select="
                    if ($textLength lt 2000) then
                    (300)
                    else
                    (500)"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentWidth" select="max($content/@width)"/>
        <xsl:variable name="contentHeight" select="sum($content/@height)"/>
        
        <svg width="{$contentWidth + 32}" height="{$contentHeight + 17}" class="annotation">
            <g visibility="hidden" style="z-index:1000">
                <set attributeName="visibility" to="visible" begin="{$hover_id}.mouseover" end="{$hover_id}.mouseout" es:dokuViewer="{$hover_id}"/>
                <xsl:for-each select="$invisible_ids">
                    <set attributeName="visibility" to="hidden" begin="{.}.mouseover" end="{.}.mouseout"/>
                </xsl:for-each>
                <g transform="translate(1,1)">
                    <xsl:variable name="curve" select="min((10, $cY - 5))"/>
                    <path d="{es:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="white" opacity="1" stroke="{$color?main}" stroke-width="1"/>
                    <path d="{es:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="{$color?main}" opacity="0.1" stroke="{$color?main}" stroke-width="1"/>
                    <path d="{es:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="none" opacity="1" stroke="{$color?main}" stroke-width="1"/>
                    <xsl:for-each select="$content">
                        <xsl:variable name="precHeight" select="sum(preceding-sibling::*/@height)"/>
                        <g transform="translate(20,{$precHeight + 5})">
                            <xsl:sequence select="."/>
                        </g>
                    </xsl:for-each>
                </g>
                
            </g>
        </svg>
        
        
    </xsl:function>
    
    
    
    <xsl:template match="xs:documentation" mode="es:create-docs-tooltips">
        <xsl:param name="text-width" select="300"/>
        <xsl:variable name="fontSize" select="11"/>
        
        <xsl:if test="@source or not(preceding-sibling::xs:documentation)">
            <xsl:variable name="title">
                <xsl:call-template name="wrap">
                    <xsl:with-param name="text" select="
                        if (@source) then
                        (@source)
                        else
                        ('Documentation')"/>
                    <xsl:with-param name="fontSize" select="$fontSize"/>
                    <xsl:with-param name="font" select="'Arial'"/>
                    <xsl:with-param name="width" select="$text-width"/>
                    <xsl:with-param name="style" select="'bold'"/>
                    <xsl:with-param name="spaceAfter" select="2"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:sequence select="$title"/>
        </xsl:if>
        
        <xsl:variable name="wrap">
            <xsl:call-template name="wrap">
                <xsl:with-param name="text" select="."/>
                <xsl:with-param name="fontSize" select="$fontSize"/>
                <xsl:with-param name="font" select="'Arial'"/>
                <xsl:with-param name="width" select="$text-width"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:sequence select="$wrap"/>
    </xsl:template>
    
    




</xsl:stylesheet>
