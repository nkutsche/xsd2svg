<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:es="http://www.escali.schematron-quickfix.com/" 
    xmlns:svg="http://www.w3.org/2000/svg" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns="http://www.w3.org/2000/svg"
    exclude-result-prefixes="#all"
    version="3.0"
    >
    
<!--    
    Imports:
    -->
    
    <xsl:import href="functions.xsl"/>
    <xsl:import href="xsd2svg_1_main.xsl"/>
    <xsl:import href="xsd2svg_2_docs.xsl"/>
    <xsl:import href="xsd2svg_3_transform.xsl"/>
    <xsl:import href="xsd2svg_4_zindex.xsl"/>
    
    
    
<!--    
        Modes:
    -->
    
    <xsl:mode name="es:xsd2svg"/>

    <xsl:mode name="es:xsd2svg-docs" on-no-match="shallow-copy"/>
    <xsl:mode name="es:xsd2svg-transform" on-no-match="shallow-copy"/>
    <xsl:mode name="es:xsd2svg-zindex" on-no-match="shallow-copy"/>
    <xsl:mode name="es:xsd2svg-cleanup" on-no-match="shallow-copy"/>
    
    
    
<!--    
    Functions:
    -->
    
<!--    
    
    SVG MODEL
    -->
    
    <xsl:function name="es:svg-model">
        <xsl:param name="xsdnode" as="element()"/>
        <xsl:param name="config" as="map(xs:string, map(*))"/>
        
        <xsl:variable name="modelid" select="generate-id($xsdnode)"/>
        <xsl:variable name="raw-model">
            <xsl:apply-templates select="$xsdnode" mode="es:xsd2svg">
                <xsl:with-param name="schemaSetConfig" select="$config" tunnel="yes"/>
                <xsl:with-param name="schema-context" select="$config?schema-map" tunnel="yes"/>
                <xsl:with-param name="model-id" select="$modelid" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="handle-docs">
            <xsl:apply-templates select="$raw-model" mode="es:xsd2svg-docs">
                <xsl:with-param name="schemaSetConfig" select="$config" tunnel="yes"/>
                <xsl:with-param name="schema-context" select="$config?schema-map" tunnel="yes"/>
                <xsl:with-param name="model-id" select="$modelid" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="handle-transform">
            <xsl:apply-templates select="$handle-docs" mode="es:xsd2svg-transform"/>
        </xsl:variable>
        <xsl:variable name="handle-zindex">
            <xsl:apply-templates select="$handle-transform" mode="es:xsd2svg-zindex"/>
        </xsl:variable>
        
        <xsl:apply-templates select="$handle-zindex" mode="es:xsd2svg-cleanup"/>
    </xsl:function>
    
    <xsl:template match="@es:*" mode="es:xsd2svg-cleanup"/>
    
    
</xsl:stylesheet>