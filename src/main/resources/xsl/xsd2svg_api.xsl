<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:es="http://www.escali.schematron-quickfix.com/" 
    xmlns:xsd2svg="http://www.xsd2svg.schematron-quickfix.com/"
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
    
    <xsl:import href="xsd2svg_model-pipe.xsl"/>
    
<!--    
    Parameter:
    -->
    
    <xsl:param name="config" select="()" as="document-node()?"/>
    <xsl:param name="link-provider-function" select="function($component){}" as="function(map(xs:string, item()*)) as xs:string?"/>
        
<!--    
    Global variables:
    -->
    
    
    <xsl:variable name="effConfig" select="($config, doc('../cfg/default-config.xml')) => es:config-as-map()" as="map(*)"/>
    
    
    
    
    
    
    
<!--    
    Functions:
    -->
    
<!--    
    
    SVG MODEL
    -->
    <xsl:function name="xsd2svg:svg-model">
        <xsl:param name="xsdnode" as="element()"/>
        <xsl:param name="standalone" as="xs:boolean"/>
        <xsl:variable name="rootDoc" select="root($xsdnode) treat as document-node()"/>
        <xsl:sequence select="xsd2svg:svg-model($xsdnode, xsd2svg:createSchemaSetConfig($rootDoc), $standalone)"/>
    </xsl:function>
    
    <xsl:function name="xsd2svg:svg-model">
        <xsl:param name="xsdnode" as="element()"/>
        <xsl:param name="config" as="map(xs:string, map(*))"/>
        <xsl:param name="standalone" as="xs:boolean"/>

        <xsl:sequence select="es:svg-model($xsdnode, $config, $standalone)"/>

    </xsl:function>
    
    
    
<!--    
    Schema Info
    -->
    
    <xsl:function name="xsd2svg:getSchemaInfo" as="map(*)">
        <xsl:param name="url" as="xs:anyURI"/>
        <xsl:sequence select="xsd2svg:getSchemaInfo($url, $effConfig)"/>
    </xsl:function>
    
    <xsl:function name="xsd2svg:getSchemaInfo" as="map(*)">
        <xsl:param name="url" as="xs:anyURI"/>
        <xsl:param name="config" as="map(*)"/>
        
        <xsl:variable name="schemaSetCfg" select="xsd2svg:createSchemaSetConfig(doc($url), $config)"/>
        
        <xsl:variable name="component-infos" select="es:getComponentInfos($schemaSetCfg)"/>
        
        <xsl:variable name="grouped-components" select="
            es:group-components($component-infos, $config?component-grouping?*)
            "/>
        
        <xsl:variable name="tempSchemaSet" select="map{
            'schema-namespace-map' : $schemaSetCfg?schema-map,
            'grouped-components' : $grouped-components,
            'namespaces' : $component-infos?namespace => distinct-values(),
            'types' : $component-infos?type => distinct-values(),
            'qnames' : $component-infos?qname => distinct-values()
            }"/>
        <xsl:sequence select="
            map{
                'schema-namespace-map' : $schemaSetCfg?schema-map,
                'grouped-components' : $grouped-components,
                'create-css' : function(){es:create-css($config?styles)},
                'namespaces' : $component-infos?namespace => distinct-values(),
                'types' : $component-infos?type => distinct-values(),
                'qnames' : $component-infos?qname => distinct-values(),
                'print-qname' : function($qname){es:printQName($qname, $schemaSetCfg)},
                'components-by-id' : ($component-infos ! map{.?id : .} ) => map:merge(),
                'find-reference' : function($attribute){es:getReferencInfo($attribute, $schemaSetCfg)}
            }
            "/>
    </xsl:function>
    
<!--    
    Master Files
    -->
    
    
    
    <xsl:function name="xsd2svg:getMasterFiles" as="xs:anyURI*" visibility="public">
        <xsl:param name="path" as="xs:string"/>
        <xsl:sequence select="xsd2svg:getMasterFiles($path, 'xsd')"/>
    </xsl:function>
    <xsl:function name="xsd2svg:getMasterFiles" as="xs:anyURI*" visibility="public">
        <xsl:param name="path" as="xs:string"/>
        <xsl:param name="extension" as="xs:string"/>
        <xsl:sequence select="xsd2svg:getMasterFiles($path, $extension, true())"/>
    </xsl:function>
    <xsl:function name="xsd2svg:getMasterFiles" as="xs:anyURI*" visibility="public">
        <xsl:param name="path" as="xs:string"/>
        <xsl:param name="extension" as="xs:string"/>
        <xsl:param name="recursive" as="xs:boolean"/>
        
        <xsl:variable name="hasPathQuery" select="$path => contains('?')"/>
        
        <xsl:variable name="query" select="
            ('select=*.' || $extension,
            ';recurse=yes'[$recursive])
            => string-join(';')
            "/>
        
        <xsl:sequence select="
            if ($hasPathQuery) then
            es:getMasterFiles(xs:anyURI($path))
            else
            xsd2svg:getMasterFiles($path || '?' || $query)
            "/>
        
    </xsl:function>
    
    
    
    <xsl:function name="xsd2svg:createSchemaSetConfig" as="map(xs:string, item()*)">
        <xsl:param name="schema" as="document-node(element(xs:schema))"/>
        <xsl:sequence select="xsd2svg:createSchemaSetConfig($schema, $effConfig)"/>
    </xsl:function>
    
    <xsl:function name="xsd2svg:createSchemaSetConfig" as="map(xs:string, item()*)">
        <xsl:param name="schema" as="document-node(element(xs:schema))"/>
        <xsl:param name="config" as="map(*)"/>
        
        
        <xsl:variable name="schema-namespace-map" select="es:getReferencedSchemas($schema)"/>
        
        <xsl:variable name="prefix-map" select="es:getPrefixes($schema-namespace-map)"/>
        
        <xsl:variable name="schemaSetCfg" select="map{
            'schema-map' : $schema-namespace-map,
            'prefix-map' : $prefix-map,
            'config' : $config
            }"/>
        
        <xsl:sequence select="$schemaSetCfg"/>
    </xsl:function>
    
    <xsl:function name="es:config-as-map" as="map(*)">
        <xsl:param name="configs" as="document-node()*"/>
        <xsl:sequence select="es:config-as-map($configs, map{'link-provider' : $link-provider-function})"/>
    </xsl:function>
    
    
</xsl:stylesheet>