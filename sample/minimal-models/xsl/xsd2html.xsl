<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:es="http://www.escali.schematron-quickfix.com/" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" exclude-result-prefixes="xs math" version="3.0" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xsd2svg="http://www.xsd2svg.schematron-quickfix.com/">

    <xsl:use-package name="http://www.escali.schematron-quickfix.com/xsd2svg" package-version="*">
        <xsl:override>
            <xsl:param name="link-provider-function" select="function($comp){'#card_' || $comp?id}" as="function(map(xs:string, item()*)) as xs:string?"/>
            <xsl:param name="config" select="doc('cfg/xsd2svg.xml')" as="document-node()?"/>
        </xsl:override>
    </xsl:use-package>
    
    

    <xsl:output method="html" html-version="5.0" indent="yes"/>

    <xsl:template match="/">


        <xsl:variable name="dir" select="resolve-uri(*, base-uri(/))"/>

        <xsl:variable name="masterFiles" select="xsd2svg:getMasterFiles($dir, 'xsd', true())"/>

        <xsl:for-each select="$masterFiles">
            <xsl:variable name="outUrl" select="replace(., '/xsd/', '/html/')"/>
            <xsl:variable name="outUrl" select="replace($outUrl, '\.xsd$', '.html')"/>

            <xsl:result-document href="{$outUrl}">

                <xsl:variable name="schemaInfo" select="xsd2svg:getSchemaInfo(.)"/>
                <xsl:variable name="namespaces" select="$schemaInfo?namespaces"/>
                <xsl:variable name="types" select="$schemaInfo?types"/>
                <xsl:variable name="grouped-components" select="$schemaInfo?get-grouped-components(('namespace', 'type', 'scope'))"/>

                <html>
                    <head>
                        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous"/>
                        <style type="text/css">
                            h1, h2, h3 {margin-top: 1em;}

                            h4, h5, h6 {margin-top: .5em;}
                            
                            .row {margin-top: 2em;}
                            
                            <xsl:sequence select="$schemaInfo?create-css()"/>
                        </style>
                    </head>
                    <body>

                        <div class="container">
                            <div class="row">
                                <div class="col">

                                    <h1>
                                        <xsl:value-of select="($outUrl => tokenize('/'))[last()]"/>
                                    </h1>
                                    <p>
                                        <xsl:value-of select="$outUrl"/>
                                    </p>
                                    <xsl:for-each select="$namespaces">
                                        <xsl:variable name="namespace" select="."/>

                                        <h2>
                                            <xsl:text>Namespace </xsl:text>
                                            <xsl:value-of select="$namespace"/>
                                        </h2>

                                        <xsl:for-each select="$types">
                                            <xsl:variable name="type" select="."/>
                                            
                                            
                                            <xsl:variable name="globalComponents" select="$grouped-components($namespace) ! .($type) ! .('global')"/>

                                            <xsl:if test="exists($globalComponents)">
                                                <h3>
                                                    <xsl:value-of select="
                                                        map{'element' : 'Elements', 'attribute' : 'Attributes', 'complexType' : 'Complex Types', 'simpleType' : 'Simple Types', 'attributeGroup' : 'Attribute Groups', 'group' : 'Element Groups'} ! .($type)"/>
                                                </h3>


                                                <xsl:variable name="divs" as="element()*">

                                                    <xsl:for-each select="$globalComponents">
                                                        <xsl:call-template name="comp2html">
                                                            <xsl:with-param name="comp" select="."/>
                                                            <xsl:with-param name="schemaInfo" select="$schemaInfo" tunnel="yes"/>
                                                        </xsl:call-template>
                                                    </xsl:for-each>

                                                </xsl:variable>

                                                <xsl:sequence select="es:createBootstrapRows(array{$divs}, 3)"/>

                                            </xsl:if>
                                        </xsl:for-each>

                                    </xsl:for-each>
                                </div>
                            </div>
                        </div>

                        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-MrcW6ZMFYlzcLA8Nl+NtUVF0sA7MsXsP1UyJoMp4YLEuNSfAP+JcXn/tWtIaxVXM" crossorigin="anonymous"/>
                    </body>
                </html>
            </xsl:result-document>

        </xsl:for-each>

    </xsl:template>

    <xsl:template name="comp2html">
        <xsl:param name="comp" as="map(*)"/>
        <xsl:param name="schemaInfo" as="map(*)" tunnel="yes"/>

        <div class="card" id="card_{$comp?id}">
            <div class="card-header">
                <xsl:value-of select="es:createCompTitle($comp, $schemaInfo)"/>
            </div>

            <div class="card-body">
                <div>
                    <xsl:sequence select="$comp?get-svg-model(false())"/>
                </div>

                <xsl:apply-templates select="$comp?component/xs:annotation"/>


                <xsl:if test="exists(($comp?used-by, $comp?uses))">
                    <div class="container">
                        <div class="row justify-content-start">
                            <xsl:where-populated>
                                <div class="col">
                                    <xsl:sequence select="es:componentList('Parents', $comp?used-by, $schemaInfo)"/>
                                </div>
                            </xsl:where-populated>
                            <xsl:where-populated>
                                <div class="col">
                                    <xsl:sequence select="es:componentList('Uses', $comp?uses, $schemaInfo)"/>
                                </div>
                            </xsl:where-populated>
                        </div>
                    </div>
                </xsl:if>
            </div>
        </div>

        <xsl:for-each select="$comp?nested">
            <xsl:call-template name="comp2html">
                <xsl:with-param name="comp" select="$schemaInfo?components-by-id(.?id)"/>
            </xsl:call-template>
        </xsl:for-each>


    </xsl:template>

    <xsl:function name="es:createCompTitle">
        <xsl:param name="comp" as="map(*)"/>
        <xsl:param name="schemaInfo" as="map(*)"/>
        <xsl:sequence select="es:createCompTitle($comp, $schemaInfo, ' / ')"/>
    </xsl:function>

    <xsl:function name="es:createCompTitle">
        <xsl:param name="comp" as="map(*)"/>
        <xsl:param name="schemaInfo" as="map(*)"/>
        <xsl:param name="separator" as="xs:string"/>

        <xsl:variable name="nested-by" select="$comp?nested-by"/>
        <xsl:variable name="nested-by-comp" select="$schemaInfo?components-by-id($nested-by?id)"/>
        <xsl:variable name="compName" select="$schemaInfo?print-qname($comp?qname)"/>
        
        <xsl:variable name="compName" select="('@'[$comp?type = 'attribute'], $compName) => string-join()"/>
        
        <xsl:variable name="ancTitle" select="
                if (empty($nested-by)) then
                    ()
                else
                    (es:createCompTitle($nested-by-comp, $schemaInfo))"/>

        <xsl:sequence select="string-join(($ancTitle, $compName), $separator)"/>
    </xsl:function>

    <xsl:function name="es:componentList">
        <xsl:param name="title"/>
        <xsl:param name="components" as="map(*)*"/>
        <xsl:param name="schemaInfo"/>

        <xsl:if test="count($components) gt 0">

            <div class="card">
                <div class="card-header">
                    <xsl:value-of select="$title"/>
                </div>
                <ul class="list-group list-group-flush">
                    <xsl:for-each select="$components">
                        <li class="list-group-item">
                            <a href="#{.?id}">
                                <xsl:value-of select="$schemaInfo?print-qname(.?qname)"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>

        </xsl:if>

    </xsl:function>

    <xsl:function name="es:createBootstrapRows">
        <xsl:param name="cells" as="array(*)"/>
        <xsl:param name="cols" as="xs:integer"/>

        <xsl:variable name="size" select="array:size($cells)"/>

        <xsl:for-each select="1 to ($size idiv $cols + 1)">
            <xsl:variable name="idx" select="(. - 1) * $cols"/>
            <div class="row justify-content-start">
                <xsl:for-each select="1 to $cols">
                    <xsl:variable name="idx" select="$idx + ."/>
                    <xsl:if test="$idx le $size">
                        <div class="col-{12 idiv $cols}">
                            <xsl:sequence select="$cells($idx)"/>
                        </div>
                    </xsl:if>
                </xsl:for-each>
            </div>
        </xsl:for-each>

    </xsl:function>


    <xsl:template match="xs:annotation">
        <div>
            <xsl:for-each-group select="xs:documentation" group-starting-with="xs:documentation[@source]">
                <xsl:variable name="content">
                    <xsl:for-each select="current-group()">
                        <p>
                            <xsl:value-of select="."/>
                        </p>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="@source">
                        <dl class="row">
                            <dt class="col-sm-3">
                                <xsl:value-of select="@source"/>
                            </dt>
                            <dd class="col-sm-9">
                                <xsl:sequence select="$content"/>
                            </dd>
                        </dl>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$content"/>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each-group>
        </div>
    </xsl:template>

</xsl:stylesheet>
