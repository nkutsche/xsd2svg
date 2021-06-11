<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2000/svg" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:es="http://www.escali.schematron-quickfix.com/" xmlns:java="java:java.lang.Math" exclude-result-prefixes="xs" version="3.0">

    <xsl:variable name="XSDNS" select="'http://www.w3.org/2001/XMLSchema'"/>

    <xsl:param name="defaultColor" select="
            map {
                'main': '#007',
                'secondary': '#88f',
                'text': 'white'
            }"/>
    <xsl:param name="colorScheme" select="
            map {
                '#default': $defaultColor,
                'element': $defaultColor,
                'attribute': map {
                    'main': '#770',
                    'secondary': '#ee8',
                    'text': 'black'
                },
                'simpleType': map {
                    'main': '#070',
                    'secondary': '#8f8',
                    'text': 'black'
                },
                'complexType': map {
                    'main': '#077',
                    'secondary': '#8ee',
                    'text': 'black'
                },
                'group': map {
                    'main': '#707',
                    'secondary': '#e8e',
                    'text': 'black'
                },
                'attributeGroup': map {
                    'main': '#700',
                    'secondary': '#f88',
                    'text': 'white'
                },
                'any': map {
                    'main': '#777',
                    'secondary': '#fff',
                    'text': 'black'
                }
            }" as="map(xs:string, map(xs:string, xs:string))"/>

    <xsl:key name="elementByQName" match="xs:schema/xs:*[@name]" use="es:getName(.)"/>

    <xsl:key name="parentByElementRef" match="xs:element[@name] | xs:group[@name]" use="
            (.//xs:element[@ref] except .//xs:element[@name]//*)/es:getName(.)
            "/>
    <xsl:key name="parentByGroupRef" match="xs:element[@name] | xs:group[@name]" use="
            (.//xs:group[@ref] except .//xs:element[@name]//*)/es:getName(.)
            "/>

    <xsl:key name="elementByAttributename" match="xs:element[@name] | xs:attributeGroup[@name] | xs:complexType[@name]" use="
            ((.//xs:attribute[@ref] | .//xs:attributeGroup) except .//xs:element[@name]//*) ! es:getName(.)
            "/>
    
    <xsl:key name="parentByType" match="xs:element[@type] | xs:attribute[@type]" use="
        es:getQName(@type)
        "/>

    <xsl:key name="globalAttributesByName" match="xs:schema/xs:attribute" use="es:getName(@name)"/>



    <xsl:function name="es:printQName" as="xs:string">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>

        <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>
        <xsl:variable name="local-name" select="local-name-from-QName($qname)"/>
        <xsl:variable name="schemas" select="
                if ($namespace = $XSDNS) then
                    (map:keys($schema-context) ! $schema-context(.))
                else
                    $schema-context($namespace)"/>
        <xsl:variable name="prefix" select="($schemas//namespace::*[. = $namespace]/name())[1]" as="xs:string?"/>
        
        <xsl:variable name="prefix" select=" if ($prefix) then ($prefix || ':') else ('')"/>

        <xsl:sequence select="$prefix || $local-name"/>

    </xsl:function>

    <xsl:function name="es:error">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="message"/>
        <xsl:sequence select="error(QName('http://www.escali.schematron-quickfix.com/', $id), $message)"/>
    </xsl:function>

    <xsl:function name="es:getQName" as="xs:QName">
        <xsl:param name="node" as="attribute()"/>
        <xsl:variable name="prefix" select="
                if (contains($node, ':')) then
                    replace($node, '([^:]+):.*', '$1')
                else
                    ''
                "/>
        <xsl:variable name="local-name" select="replace($node, '[^:]+:', '')"/>
        <xsl:variable name="namespace" select="$node/../namespace::*[name() = $prefix]"/>
        <xsl:sequence select="
                if ($prefix != '' and not($namespace)) then
                    es:error('unbound-prefix', 'Unbound prefix ' || $prefix || ' at ' || path($node))
                else
                    QName(string($namespace), $node)"/>
    </xsl:function>


    <xsl:function name="es:getName" as="xs:QName">
        <xsl:param name="node" as="node()"/>

        <xsl:choose>
            <xsl:when test="$node/@ref">
                <xsl:sequence select="es:getQName($node/@ref)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="local-name" select="$node/@name"/>
                <xsl:variable name="schema" select="root($node)/xs:schema"/>
                <xsl:variable name="isTopLevel" select="exists($node/parent::xs:schema)"/>

                <xsl:variable name="trg_namespace" select="$schema/@targetNamespace"/>
                <xsl:variable name="defaultForm" select="
                        if ($node/self::xs:element) then
                            ($schema/@elementFormDefault)
                        else
                            if ($node/self::xs:attribute) then
                                ($schema/@attributeFormDefault)
                            else
                                ('qualified')
                        "/>
                <xsl:variable name="form" select="
                        (
                        'qualified'[$isTopLevel],
                        $node/@form,
                        $defaultForm,
                        'unqualified'
                        )[1]
                        "/>

                <xsl:variable name="namespace" select="
                        if ($form = 'qualified') then
                            $trg_namespace
                        else
                            ''" as="xs:string"/>

                <xsl:sequence select="QName($namespace, $local-name)"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>
    <xsl:function name="es:getName">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="attrName"/>
        <xsl:variable name="nameRef" select="$node/@*[name() = $attrName]"/>
        <xsl:variable name="localName" select="replace($nameRef, '^sqf:|^sch:', '')"/>
        <xsl:value-of select="$localName"/>
    </xsl:function>

    <xsl:function name="es:getReference" as="node()?">
        <xsl:param name="attr" as="attribute()"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>

        <xsl:variable name="attrName" select="$attr/local-name()"/>
        <xsl:variable name="element" select="
                if ($attrName = ('type', 'base')) then
                    ('simpleType', 'complexType')
                else
                    if ($attrName = 'itemType') then
                        'simpleType'
                    else
                        ($attr/parent::*/local-name())
                "/>

        <xsl:choose>
            <xsl:when test="$attr/self::attribute(namespace)">
                <xsl:variable name="ns" select="
                        if ($attr = '##targetNamespace') then
                            root($attr)/xs:schema/@targetNamespace
                        else
                            if ($attr = '##local') then
                                ('')
                            else
                                ($attr)"/>
                <xsl:sequence select="$schema-context($ns)[1]/xs:schema"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="qnameRef" select="es:getQName($attr)"/>
                <xsl:variable name="namespace" select="namespace-uri-from-QName($qnameRef)"/>
                <xsl:sequence select="
                        if ($namespace = $XSDNS) then
                            ()
                        else
                            es:getReferenceByQName($qnameRef, $schema-context, $element)"/>
            </xsl:otherwise>
        </xsl:choose>


    </xsl:function>

    <xsl:function name="es:getReferenceByQName" as="node()*">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>
        <xsl:param name="refKind" as="xs:string*"/>
        <xsl:sequence select="es:getReferenceByQName($qname, $schema-context, $refKind, true())"/>
    </xsl:function>

    <xsl:function name="es:getReferenceByQName" as="node()*">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>
        <xsl:param name="refKind" as="xs:string*"/>
        <xsl:param name="exactlyOneRef" as="xs:boolean"/>


        <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>

        <xsl:variable name="target" select="
                $schema-context($namespace)/key('elementByQName', $qname)
                [local-name() = $refKind]"/>


        <xsl:variable name="qnamePrint" select="es:printQName($qname, $schema-context)"/>
        <xsl:sequence select="
                if (count($target) eq 1 or not($exactlyOneRef)) then
                    ($target)
                else
                    if (count($target) lt 1) then
                        es:error('missing-ref-target', 'There is no defintion for the reference target ' || $qnamePrint)
                    else
                        es:error('duplicate-ref-target', 'There is more than one defintion for the reference target ' || $qnamePrint)
                "/>


    </xsl:function>

    <xsl:function name="es:convertId" as="xs:string">
        <xsl:param name="id" as="xs:string"/>
        <xsl:value-of select="replace($id, ':', '_')"/>
    </xsl:function>

    <xsl:function name="es:createRoundBox">
        <xsl:param name="width" as="xs:double"/>
        <xsl:param name="height" as="xs:double"/>
        <xsl:value-of select="es:createRoundBox($width, $height, 0.25)"/>
    </xsl:function>
    <xsl:function name="es:createRoundBox">
        <xsl:param name="width" as="xs:double"/>
        <xsl:param name="height" as="xs:double"/>
        <xsl:param name="edgesRel" as="xs:double"/>
        <xsl:value-of select="es:createRoundBox($width, $height, $edgesRel, false())"/>
    </xsl:function>
    <xsl:function name="es:createRoundBox">
        <xsl:param name="width" as="xs:double"/>
        <xsl:param name="height" as="xs:double"/>
        <xsl:param name="edgesRel" as="xs:double"/>
        <xsl:param name="edgesAbs" as="xs:boolean"/>
        <xsl:variable name="edgesHeight" select="
                (if (not($edgesAbs)) then
                    (min(($height, $width)) * $edgesRel)
                else
                    ($edgesRel))"/>
        <xsl:variable name="edgesWidth" select="
                (if (not($edgesAbs)) then
                    (min(($height, $width)) * $edgesRel)
                else
                    ($edgesRel))"/>
        <xsl:variable name="point1" select="$edgesWidth, 0"/>
        <xsl:variable name="qPoint12" select="0, 0"/>
        <xsl:variable name="point2" select="0, $edgesHeight"/>
        <xsl:variable name="point3" select="0, $height - $edgesHeight"/>
        <xsl:variable name="qPoint34" select="0, $height"/>
        <xsl:variable name="point4" select="$edgesWidth, $height"/>
        <xsl:variable name="point5" select="$width - $edgesWidth, $height"/>
        <xsl:variable name="qPoint56" select="$width, $height"/>
        <xsl:variable name="point6" select="$width, $height - $edgesHeight"/>
        <xsl:variable name="point7" select="$width, $edgesHeight"/>
        <xsl:variable name="qPoint78" select="$width, 0"/>
        <xsl:variable name="point8" select="$width - $edgesWidth, 0"/>
        <xsl:variable name="seq" select="
                ('M', $point1,
                'Q', $qPoint12, $point2,
                'L', $point3,
                'Q', $qPoint34, $point4,
                'L', $point5,
                'Q', $qPoint56, $point6,
                'L', $point7,
                'Q', $qPoint78, $point8,
                'Z')"/>
        <xsl:value-of select="$seq" separator=" "/>
    </xsl:function>



    <xsl:function name="es:createBalloon" as="xs:string">
        <xsl:param name="width" as="xs:double"/>
        <xsl:param name="height" as="xs:double"/>
        <xsl:param name="rx" as="xs:double"/>
        <xsl:param name="ry" as="xs:double"/>
        <xsl:param name="cy" as="xs:double"/>
        <xsl:sequence select="es:createBalloon($width, $height, $rx, $ry, $cy, 5.0)"/>
    </xsl:function>
    <xsl:function name="es:createBalloon" as="xs:string">
        <xsl:param name="width" as="xs:double"/>
        <xsl:param name="height" as="xs:double"/>
        <xsl:param name="rx" as="xs:double"/>
        <xsl:param name="ry" as="xs:double"/>
        <xsl:param name="cy" as="xs:double"/>
        <!--    Size of the speaking arrow    -->
        <xsl:param name="sps" as="xs:double"/>


        <xsl:variable name="point1" select="$rx + $sps, 0"/>
        <xsl:variable name="qPoint12" select="$sps, 0"/>
        <xsl:variable name="point2" select="$sps, $ry"/>
        <xsl:variable name="pointS1" select="$sps, $cy - ($sps div 2)"/>
        <xsl:variable name="pointS2" select="0, $cy"/>
        <xsl:variable name="pointS3" select="$sps, $cy + ($sps div 2)"/>
        <xsl:variable name="point3" select="$sps, $height - $ry"/>
        <xsl:variable name="qPoint34" select="$sps, $height"/>
        <xsl:variable name="point4" select="$rx + $sps, $height"/>
        <xsl:variable name="point5" select="$width - $rx + $sps, $height"/>
        <xsl:variable name="qPoint56" select="$width + $sps, $height"/>
        <xsl:variable name="point6" select="$width + $sps, $height - $ry"/>
        <xsl:variable name="point7" select="$width + $sps, $ry"/>
        <xsl:variable name="qPoint78" select="$width + $sps, 0"/>
        <xsl:variable name="point8" select="$width - $rx + $sps, 0"/>
        <xsl:variable name="seq" select="
                ('M', $point1,
                'Q', $qPoint12, $point2,
                'L', $pointS1,
                'L', $pointS2,
                'L', $pointS3,
                'L', $point3,
                'Q', $qPoint34, $point4,
                'L', $point5,
                'Q', $qPoint56, $point6,
                'L', $point7,
                'Q', $qPoint78, $point8, 'Z')"/>
        <xsl:value-of select="$seq" separator=" "/>
    </xsl:function>

    <xsl:function name="es:multiValuesMerge" as="xs:string">
        <xsl:param name="funcMultiValues" as="element(svg:svg)*"/>

        <xsl:variable name="oneOrMores" select="$funcMultiValues[@es:multiValue = $MultiValues[4]]"/>
        <xsl:variable name="zeroOrMores" select="$funcMultiValues[@es:multiValue = $MultiValues[3]]"/>
        <xsl:variable name="ones" select="$funcMultiValues[@es:multiValue = $MultiValues[2]] | $funcMultiValues[not(@es:multiValue)]"/>
        <xsl:variable name="zeroOrOnes" select="$funcMultiValues[@es:multiValue = $MultiValues[1]]"/>
        <xsl:choose>
            <xsl:when test="$ones or ($oneOrMores and $zeroOrOnes)">
                <xsl:sequence select="$MultiValues[2]"/>
            </xsl:when>
            <xsl:when test="$oneOrMores">
                <xsl:sequence select="$MultiValues[4]"/>
            </xsl:when>
            <xsl:when test="$zeroOrOnes">
                <xsl:sequence select="$MultiValues[1]"/>
            </xsl:when>
            <xsl:when test="$zeroOrMores">
                <xsl:sequence select="$MultiValues[3]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$MultiValues[2]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="sequenceSymbol">
        <xsl:param name="colors" select="$colorScheme('#default')"/>
        <xsl:param name="multiValue" select="$MultiValues[2]" as="xs:string"/>

        <xsl:variable name="colorStroke" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cY="10">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="23.5"/>
            </xsl:if>
            <g>
                <xsl:variable name="circle">
                    <circle r="9.5" stroke="{$colorStroke}" stroke-width="1" cx="10" cy="10" fill="white">
                        <xsl:if test="$multiValue = ($MultiValues[1], $MultiValues[3])">
                            <xsl:attribute name="stroke-dashoffset" select="2"/>
                            <xsl:attribute name="stroke-dasharray" select="2"/>
                        </xsl:if>
                    </circle>
                </xsl:variable>
                <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                    <circle>
                        <xsl:copy-of select="$circle/svg:circle/@*"/>
                        <xsl:attribute name="cy" select="13.5"/>
                        <xsl:attribute name="stroke-width" select="0.33"/>
                    </circle>
                    <circle>
                        <xsl:copy-of select="$circle/svg:circle/@*"/>
                        <xsl:attribute name="cy" select="12"/>
                        <xsl:attribute name="stroke-width" select="0.66"/>
                    </circle>
                </xsl:if>
                <xsl:copy-of select="$circle"/>
                <g>
                    <path d="M 0 10 
                        L 3 10
                        M 8.5 10
                        L 11.5 10
                        M 17 10
                        L 20 10" stroke="{$colorStroke}" fill="none" stroke-width="0.75"/>
                    <g transform="translate(3, 8)">
                        <rect width="5.5" height="4" fill="{$colorFill}" stroke-width="1" stroke="{$colorStroke}"/>
                    </g>
                    <g transform="translate(11.5, 8)">
                        <rect width="5.5" height="4" fill="{$colorFill}" stroke-width="1" stroke="{$colorStroke}"/>
                    </g>
                </g>
            </g>
        </svg>
    </xsl:template>
    <xsl:template name="choiceSymbol">
        <xsl:param name="colors" select="$colorScheme('#default')"/>
        <xsl:param name="multiValue" select="$MultiValues[2]" as="xs:string"/>
        <xsl:param name="connectCount" select="3"/>

        <xsl:variable name="colorStroke" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="es:cY" select="10"/>
                <xsl:attribute name="height" select="23.5"/>
            </xsl:if>
            <g>
                <xsl:variable name="circle">
                    <circle r="9.5" stroke="{$colorStroke}" stroke-width="1" cx="10" cy="10" fill="white">
                        <xsl:if test="$multiValue = ($MultiValues[1], $MultiValues[3])">
                            <xsl:attribute name="stroke-dashoffset" select="2"/>
                            <xsl:attribute name="stroke-dasharray" select="2"/>
                        </xsl:if>
                    </circle>
                </xsl:variable>
                <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                    <circle>
                        <xsl:copy-of select="$circle/svg:circle/@*"/>
                        <xsl:attribute name="cy" select="13.5"/>
                        <xsl:attribute name="stroke-width" select="0.33"/>
                    </circle>
                    <circle>
                        <xsl:copy-of select="$circle/svg:circle/@*"/>
                        <xsl:attribute name="cy" select="12"/>
                        <xsl:attribute name="stroke-width" select="0.66"/>
                    </circle>
                </xsl:if>
                <xsl:copy-of select="$circle"/>
                <g>
                    <path d="M 0 10 
                        L 3 10 
                        L 3 6 
                        L 6 6
                        M 3 10
                        L 3 14
                        L 6 14" stroke="{$colorStroke}" fill="none" stroke-width="0.75"/>
                    <g transform="translate(6, 4)">
                        <rect width="8" height="4" fill="{$colorFill}" stroke-width="1" stroke="{$colorStroke}"/>
                    </g>
                    <g transform="translate(6, 12)">
                        <rect width="8" height="4" fill="{$colorFill}" stroke-width="1" stroke="{$colorStroke}"/>
                    </g>
                    <xsl:if test="$connectCount = (1, 3)">
                        <path d="M 20 10 
                                L 17 10 
                                L 17 6 
                                L 14 6
                                M 17 10
                                L 17 14
                                L 14 14" stroke="{$colorStroke}" fill="none" stroke-width="0.75"/>
                    </xsl:if>
                    <xsl:if test="$connectCount gt 1">
                        <path d="M 10 0
                                 L 10 4" stroke="{$colorStroke}" fill="none" stroke-width="0.75"/>
                        <path d="M 10 16
                                 L 10 20" stroke="{$colorStroke}" fill="none" stroke-width="0.75"/>
                    </xsl:if>
                </g>
            </g>
        </svg>
    </xsl:template>

    <xsl:template name="groupTitle">
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="color" select="'#007'"/>
        <xsl:param name="font-color" select="'black'"/>
        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="width" select="es:renderedTextLength($title, 'Arial', 'plain', $fontSize) + 29"/>
        <svg width="{$width + 6}" height="25">
            <g transform="translate(3,3)">
                <rect width="5" height="5" x="6" y="3" fill="{$color}" opacity="0.5"/>
                <rect width="5" height="5" x="6" y="11" fill="{$color}" opacity="0.5"/>
                <rect width="5" height="5" x="14" y="11" fill="{$color}" opacity="0.5"/>
                <rect width="5" height="5" x="6" y="3" fill="none" stroke="{$color}" stroke-width="0.75" opacity="1"/>
                <rect width="5" height="5" x="6" y="11" fill="none" stroke="{$color}" stroke-width="0.75" opacity="1"/>
                <rect width="5" height="5" x="14" y="11" fill="none" stroke="{$color}" stroke-width="0.75" opacity="1"/>
                <text x="26" y="13" fill="{$font-color}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$title"/>
                </text>
            </g>
        </svg>
    </xsl:template>


    <xsl:template name="drawObjectPaths">
        <xsl:param name="content" as="element(svg:svg)*"/>
        <xsl:param name="strokeColor" as="xs:string" select="$colorScheme('#default')?main"/>
        <xsl:param name="x0" select="0"/>
        <xsl:param name="x1" select="25"/>
        <xsl:param name="x2" select="50"/>
        <xsl:param name="minX1" select="15"/>
        <xsl:param name="curve" select="7"/>
        <xsl:param name="rightPathPosition" select="false()" as="xs:boolean"/>

        <xsl:variable name="contentHeight" select="sum($content/@height)"/>
        <xsl:variable name="contentWidth" select="
                if ($content/@width[. = ''])
                then
                    (1000000)
                else
                    (max($content/@width[. != '']))"/>

        <xsl:variable name="x0" select="
                if ($rightPathPosition) then
                    ($contentWidth + $x2 - $x0)
                else
                    ($x0)"/>
        <xsl:variable name="x1" select="
                if ($rightPathPosition) then
                    ($contentWidth + $x2 - $x1)
                else
                    ($x1)"/>
        <xsl:variable name="minX1" select="
                if ($rightPathPosition) then
                    ($contentWidth + $x2 - $minX1)
                else
                    ($minX1)"/>
        <xsl:variable name="x2" select="
                if ($rightPathPosition) then
                    ($contentWidth)
                else
                    ($x2)"/>

        <xsl:if test="$content">
            <xsl:variable name="firstContentConnect" select="($content[1]/@es:cY, $content[1]/@height div 2)[1]"/>
            <xsl:variable name="lastContentConnect" select="($content[last()]/@es:cY, $content[last()]/@height div 2)[1]"/>
            <xsl:variable name="lastContentConnect" select="$contentHeight - ($content[last()]/@height - $lastContentConnect)"/>

            <xsl:variable name="moreThenOne" select="count($content) gt 1" as="xs:boolean"/>

            <xsl:variable name="cY" select="
                    if ($moreThenOne)
                    then
                        (((es:number($lastContentConnect) - es:number($firstContentConnect)) div 2) + es:number($firstContentConnect))
                    else
                        ($content/@es:cY)"/>
            <xsl:variable name="x1ForOne" select="
                    if ($rightPathPosition and not($moreThenOne))
                    then
                        ($x2)
                    else
                        if ($moreThenOne)
                        then
                            ($x1)
                        else
                            (max(($x1, $minX1)))"/>
            <xsl:variable name="x0" select="
                    if ($rightPathPosition and not($moreThenOne))
                    then
                        ($x0 - min(($x1, $minX1)) + $x2)
                    else
                        ($x0)"/>
            <xsl:variable name="svgWidth" select="
                    if ($rightPathPosition)
                    then
                        ($x0)
                    else
                        ($contentWidth + (if ($moreThenOne) then
                            ($x2)
                        else
                            ($x1ForOne)))"/>

            <xsl:variable name="contentMultiValue" select="es:multiValuesMerge($content)"/>
            <svg width="{$svgWidth}" height="{$contentHeight}" es:cY="{$cY}" class="objectPaths" es:multiValue="{$contentMultiValue}">
                <xsl:variable name="contentReq" select="not(matches($contentMultiValue, 'zero'))" as="xs:boolean"/>
                <xsl:variable name="contentMore" select="matches($contentMultiValue, 'More')" as="xs:boolean"/>
                <xsl:variable name="gap" select="
                        if ($contentMore) then
                            (1.5)
                        else
                            (0)" as="xs:double"/>
                <xsl:variable name="dash" select="
                        if ($x1ForOne - $x0 gt 20) then
                            (5)
                        else
                            (3)"/>
                <path stroke="{$strokeColor}" stroke-width="1" fill="none">
                    <xsl:attribute name="d" select="'M', $x0, $cY - $gap, 'L', $x1ForOne, $cY - $gap" separator=" "/>
                    <xsl:if test="not($contentReq)">
                        <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                    </xsl:if>
                </path>
                <xsl:if test="$contentMore">
                    <path stroke="{$strokeColor}" stroke-width="1" fill="none">
                        <xsl:attribute name="d" select="'M', $x0, $cY + $gap, 'L', $x1ForOne, $cY + $gap" separator=" "/>
                        <xsl:if test="not($contentReq)">
                            <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                        </xsl:if>
                    </path>
                </xsl:if>
                <xsl:variable name="dash" select="5"/>
                <xsl:for-each select="reverse($content)">
                    <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height)"/>
                    <xsl:variable name="thisWidth" select="@width"/>
                    <xsl:variable name="y" select="$precHeight + @es:cY"/>
                    <xsl:variable name="pos" select="position()"/>

                    <xsl:variable name="followY" select="$precHeight + @height + following-sibling::svg:svg[1]/@es:cY"/>
                    <xsl:variable name="precY" select="$precHeight - preceding-sibling::svg:svg[1]/@height + preceding-sibling::svg:svg[1]/@es:cY"/>

                    <xsl:variable name="pathToY" select="
                            if ($y gt $cY)
                            then
                                (if ($precY lt $cY) then
                                    ($cY)
                                else
                                    ($precY))
                            else
                                if ($y lt $cY)
                                then
                                    (if ($followY gt $cY) then
                                        ($cY)
                                    else
                                        ($followY))
                                else
                                    ($y)"/>

                    <xsl:variable name="strokeRespContent" select="
                            if ($y lt $cY)
                            then
                                (preceding-sibling::svg:svg | self::svg:svg)
                            else
                                if ($y gt $cY)
                                then
                                    (following-sibling::svg:svg | self::svg:svg)
                                else
                                    (self::svg:svg)"/>
                    <xsl:choose>
                        <xsl:when test="not($pos = (1, last()))">
                            <xsl:variable name="gap" select="
                                    if (matches(@es:multiValue, 'More')) then
                                        (1.5)
                                    else
                                        (0)" as="xs:double"/>
                            <path stroke="{if (@es:stroke) then (@es:stroke) else ($strokeColor)}" stroke-width="1" fill="none">
                                <xsl:attribute name="d" select="
                                        'M', $x1, $y - $gap,
                                        'L', $x2, $y - $gap" separator=" "/>
                                <xsl:if test="matches(@es:multiValue, 'zero')">
                                    <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                                </xsl:if>
                            </path>
                            <xsl:if test="$gap gt 0">
                                <path stroke="{if (@es:stroke) then (@es:stroke) else ($strokeColor)}" stroke-width="1" fill="none">
                                    <xsl:attribute name="d" select="
                                            'M', $x1, $y + $gap,
                                            'L', $x2, $y + $gap" separator=" "/>
                                    <xsl:if test="matches(@es:multiValue, 'zero')">
                                        <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                                    </xsl:if>
                                </path>
                            </xsl:if>
                            <xsl:variable name="mergedMultiValue" select="es:multiValuesMerge($strokeRespContent)"/>
                            <xsl:variable name="gap" select="
                                    if (matches($mergedMultiValue, 'More')) then
                                        (1.5)
                                    else
                                        (0)" as="xs:double"/>
                            <path stroke="{$strokeColor}" stroke-width="1" fill="none">
                                <xsl:attribute name="d" select="
                                        'M', $x1 - $gap, $y,
                                        'L', $x1 - $gap, $pathToY"/>
                                <xsl:if test="matches($mergedMultiValue, 'zero')">
                                    <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                                </xsl:if>
                            </path>
                            <xsl:if test="$gap gt 0">
                                <path stroke="{$strokeColor}" stroke-width="1" fill="none">
                                    <xsl:attribute name="d" select="
                                            'M', $x1 + $gap, $y,
                                            'L', $x1 + $gap, $pathToY"/>
                                    <xsl:if test="matches($mergedMultiValue, 'zero')">
                                        <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                                    </xsl:if>
                                </path>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test="$moreThenOne">
                            <xsl:variable name="xCurve" select="
                                    if ($rightPathPosition) then
                                        ($x1 - $curve)
                                    else
                                        ($x1 + $curve)"/>
                            <xsl:variable name="yCurve" select="
                                    if ($pos = 1) then
                                        ($y - $curve)
                                    else
                                        ($y + $curve)"/>

                            <xsl:variable name="gap" select="
                                    if (matches(@es:multiValue, 'More')) then
                                        (1.5)
                                    else
                                        (0)" as="xs:double"/>
                            <path stroke="{if (@es:stroke) then (@es:stroke) else ($strokeColor)}" stroke-width="1" fill="none">
                                <xsl:attribute name="d" select="
                                        'M', $x2, $y - $gap,
                                        'L', $xCurve, $y - $gap,
                                        'Q', $x1 + $gap, $y - $gap, $x1 + $gap, $yCurve,
                                        'L', $x1 + $gap, $pathToY"/>
                                <xsl:if test="matches(@es:multiValue, 'zero')">
                                    <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                                </xsl:if>
                            </path>
                            <xsl:if test="matches(@es:multiValue, 'More')">
                                <path stroke="{if (@es:stroke) then (@es:stroke) else ($strokeColor)}" stroke-width="1" fill="none">
                                    <xsl:attribute name="d" select="
                                            'M', $x2, $y + $gap,
                                            'L', $xCurve, $y + $gap,
                                            'Q', $x1 - $gap, $y + $gap, $x1 - $gap, $yCurve,
                                            'L', $x1 - $gap, $pathToY"/>
                                    <xsl:if test="matches(@es:multiValue, 'zero')">
                                        <xsl:attribute name="stroke-dasharray" select="$dash, $dash" separator=","/>
                                    </xsl:if>
                                </path>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <g transform="translate({
                                        if ($rightPathPosition) 
                                        then ($contentWidth - $thisWidth) 
                                        else (if ($moreThenOne) then ($x2) else ($x1ForOne)
                                        )
                                        },
                                        {$precHeight})">
                        <xsl:copy-of select="."/>
                    </g>
                </xsl:for-each>
            </svg>
        </xsl:if>
    </xsl:template>

    <xsl:variable name="piHalf" select="java:acos(-1) div 2"/>


    <xsl:template name="drawPath">
        <xsl:param name="from" required="yes" as="xs:double+"/>
        <xsl:param name="to" required="yes" as="xs:double+"/>
        <xsl:param name="style" select="'solid'" as="xs:string"/>
        <xsl:param name="doubleGap" select="3" as="xs:double"/>
        <xsl:param name="inheritPath" as="element(svg:path)"/>

        <xsl:choose>
            <xsl:when test="$style = 'double'">
                <xsl:variable name="xDiv" select="$from[1] - $to[1]"/>
                <xsl:variable name="yDiv" select="$from[2] - $to[2]"/>

                <xsl:variable name="angle" select="
                        if ($xDiv != 0)
                        then
                            ($piHalf - java:atan($yDiv div $xDiv))
                        else
                            (0)"/>
                <xsl:variable name="gabXdiv" select="java:cos($angle) * $doubleGap div 2"/>
                <xsl:variable name="gabYdiv" select="java:sin($angle) * $doubleGap div 2"/>
                <xsl:variable name="from1" select="$from[1] - $gabXdiv, $from[2] - $gabYdiv"/>
                <xsl:variable name="to1" select="$to[1] - $gabXdiv, $to[2] - $gabYdiv"/>
                <xsl:variable name="from2" select="$from[1] + $gabXdiv, $from[2] + $gabYdiv"/>
                <xsl:variable name="to2" select="$to[1] + $gabXdiv, $to[2] + $gabYdiv"/>
                <path class="double">
                    <xsl:copy-of select="$inheritPath/@*"/>
                    <xsl:attribute name="d" select="'M', $from1, 'L', $to1"/>
                </path>
                <path class="double">
                    <xsl:copy-of select="$inheritPath/@*"/>
                    <xsl:attribute name="d" select="'M', $from2, 'L', $to2"/>
                </path>
            </xsl:when>
            <xsl:otherwise>
                <path>
                    <xsl:copy-of select="$inheritPath/@*"/>
                    <xsl:attribute name="d" select="'M', $from, 'L', $to"/>
                </path>
            </xsl:otherwise>
        </xsl:choose>



    </xsl:template>

    <xsl:function name="es:number" as="xs:decimal">
        <xsl:param name="value"/>
        <xsl:sequence select="es:number($value, 0)"/>
    </xsl:function>
    <xsl:function name="es:number" as="xs:decimal">
        <xsl:param name="value"/>
        <xsl:param name="default" as="xs:decimal"/>
        <xsl:sequence select="
                if ($value castable as xs:decimal) then
                    (xs:decimal($value))
                else
                    ($default)"/>
    </xsl:function>

    <xsl:variable name="MultiValues" select="('zeroOrOne', 'one', 'zeroOrMore', 'oneOrMore')"/>
    <xsl:function name="es:getMultiValue" as="xs:string">
        <xsl:param name="node" as="element()"/>
        <xsl:choose>
            <xsl:when test="$node/self::xs:attribute">
                <xsl:variable name="use" select="
                        if ($node/@use) then
                            ($node/@use)
                        else
                            ('optional')"/>
                <xsl:variable name="uses" select="('optional', 'required')"/>
                <xsl:value-of select="$MultiValues[index-of($uses, $use)]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="min" select="es:number($node/@minOccurs, 1)"/>
                <xsl:variable name="min" select="
                        if ($min = 0)
                        then
                            ('zero')
                        else
                            ('one')"/>
                <xsl:variable name="max" select="
                        if ($node/@maxOccurs = 'unbounded')
                        then
                            (-1)
                        else
                            (es:number($node/@maxOccurs, 1))"/>
                <xsl:variable name="max" select="
                        if ($max = 1)
                        then
                            ('One')
                        else
                            ('More')"/>
                <xsl:value-of select="replace(concat($min, 'Or', $max), 'oneOrOne', 'one')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="wrap">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="font" select="'Arial'"/>
        <xsl:param name="fontSize" select="11" as="xs:double"/>
        <xsl:param name="lineHeight" select="16" as="xs:double"/>
        <xsl:param name="spaceAfter" select="8" as="xs:double"/>
        <xsl:param name="style" select="'plain'" as="xs:string"/>
        <xsl:param name="width"/>
        <xsl:variable name="subwoerter">
            <xsl:analyze-string select="$text" regex="[^\s-]+([\s-]+|$)">
                <xsl:matching-substring>
                    <tspan>
                        <xsl:value-of select="."/>
                    </tspan>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:variable name="tspans">
            <xsl:for-each select="$subwoerter/svg:tspan">
                <xsl:variable name="length" select="
                        es:renderedTextLength(.,
                        $font,
                        $style,
                        $fontSize)"/>
                <tspan>
                    <xsl:attribute name="es:length" select="$length"/>
                    <xsl:value-of select="."/>
                </tspan>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="lines">
            <xsl:call-template name="lineWrap">
                <xsl:with-param name="tspans" select="$tspans/svg:tspan"/>
                <xsl:with-param name="x" select="0"/>
                <xsl:with-param name="y" select="0"/>
                <xsl:with-param name="lineHeight" select="$lineHeight"/>
                <xsl:with-param name="lineWidth" select="$width"/>
            </xsl:call-template>
        </xsl:variable>
        <svg width="{$width}" height="{(count($lines/es:line) * $lineHeight) + $spaceAfter}" class="text_box">
            <text fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                <xsl:if test="$style = 'bold'">
                    <xsl:attribute name="font-weight">bold</xsl:attribute>
                </xsl:if>
                <xsl:copy-of select="$lines/es:line/*"/>
            </text>
        </svg>
    </xsl:template>

    <xsl:template name="lineWrap">
        <xsl:param name="tspans" as="element(svg:tspan)*"/>
        <xsl:param name="x" select="0" as="xs:double"/>
        <xsl:param name="y" select="0" as="xs:double"/>
        <xsl:param name="lineHeight" select="16" as="xs:double"/>
        <xsl:param name="lineWidth"/>

        <xsl:variable name="firstLine" select="$tspans[sum(preceding-sibling::*/@es:length) + @es:length lt $lineWidth]"/>
        <xsl:variable name="nextLines">
            <xsl:copy-of select="$tspans except $firstLine"/>
        </xsl:variable>

        <xsl:if test="$firstLine">
            <es:line>
                <xsl:for-each select="$firstLine">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:attribute name="y" select="$y + $lineHeight"/>
                        <xsl:if test="position() = 1">
                            <xsl:attribute name="x" select="$x"/>
                        </xsl:if>
                        <xsl:copy-of select="node()"/>
                    </xsl:copy>
                </xsl:for-each>
            </es:line>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$nextLines and $firstLine">
                <xsl:call-template name="lineWrap">
                    <xsl:with-param name="tspans" select="$nextLines/svg:tspan"/>
                    <xsl:with-param name="x" select="$x"/>
                    <xsl:with-param name="y" select="$y + $lineHeight"/>
                    <xsl:with-param name="lineHeight" select="$lineHeight"/>
                    <xsl:with-param name="lineWidth" select="$lineWidth"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>


    </xsl:template>

    <xsl:function name="es:renderedTextLength" xmlns:font="java:java.awt.Font" xmlns:frc="java:java.awt.font.FontRenderContext" xmlns:at="java:java.awt.geom.AffineTransform" xmlns:r2d="java:java.awt.geom.Rectangle2D">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="fontStyle" as="map(*)"/>
        <xsl:sequence select="es:renderedTextLength($text, $fontStyle?font, $fontStyle?style, $fontStyle?font-size)"/>
    </xsl:function>
    
    <xsl:function name="es:renderedTextLength" xmlns:font="java:java.awt.Font" xmlns:frc="java:java.awt.font.FontRenderContext" xmlns:at="java:java.awt.geom.AffineTransform" xmlns:r2d="java:java.awt.geom.Rectangle2D">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="font" as="xs:string"/>
        <xsl:param name="style" as="xs:string"/>
        <xsl:param name="font-size" as="xs:double"/>

        <!--        
        AffineTransform affinetransform = new AffineTransform();     
        FontRenderContext frc = new FontRenderContext(affinetransform,true,true);     
        Font font = new Font("Tahoma", Font.PLAIN, 12);
        int textwidth = (int)(font.getStringBounds(text, frc).getWidth());
        -->
        <xsl:variable name="affinetransform" select="at:new()"/>
        <xsl:variable name="frc" select="frc:new($affinetransform, true(), true())"/>
        <xsl:variable name="jfont" select="font:new($font, 0, xs:integer($font-size))"/>
        <xsl:variable name="r2d" select="font:getStringBounds($jfont, $text, $frc)"/>
        <xsl:sequence select="r2d:getWidth($r2d)"/>
    </xsl:function>

    <xsl:function name="es:getReferencedSchemas" as="map(xs:string, document-node(element(xs:schema))*)">
        <xsl:param name="schema" as="document-node()"/>
        <xsl:sequence select="es:getReferencedSchemas($schema, ())"/>
    </xsl:function>

    <xsl:function name="es:getReferencedSchemas" as="map(xs:string, document-node(element(xs:schema))*)">
        <xsl:param name="schema" as="document-node()"/>
        <xsl:param name="knownURIs" as="xs:string*"/>

        <xsl:variable name="imports" select="$schema/xs:schema/xs:import"/>
        <xsl:variable name="includes" select="$schema/xs:schema/xs:include"/>

        <xsl:variable name="schemaUri" select="base-uri($schema)"/>

        <xsl:variable name="importURIs" select="$imports/resolve-uri(@schemaLocation, base-uri(.))"/>
        <xsl:variable name="includeURIs" select="$includes/resolve-uri(@schemaLocation, base-uri(.))"/>

        <xsl:variable name="namespaceuri" select="($schema/xs:schema/@targetNamespace, '')[1]" as="xs:string"/>
        <xsl:variable name="schema-map" select="map{$namespaceuri : $schema}"/>

        <xsl:variable name="importSchemas" select="
                for $iu
                in ($importURIs, $includeURIs)[not(. = $knownURIs)]
                return
                    es:getReferencedSchemas(doc($iu),
                    ($knownURIs, $schemaUri, $importURIs, $includeURIs))" as="map(xs:string, document-node(element(xs:schema))*)*"/>

        <xsl:variable name="includeSchemas" select="
                for $iu
                in ($includeURIs)[not(. = ($knownURIs, $schemaUri))]
                return
                    es:getReferencedSchemas(doc($iu),
                    ($knownURIs, $schemaUri, $importURIs, $includeURIs))" as="map(xs:string, document-node(element(xs:schema))*)*"/>



        <xsl:variable name="maps" select="map:entry($namespaceuri, $schema), $importSchemas, $includeSchemas"/>
        <xsl:sequence select="
            map:merge($maps, map{'duplicates' : 'combine'})"/>
    </xsl:function>

    <xsl:function name="es:getParents" as="element()*">
        <xsl:param name="this" as="element()"/>
        <xsl:sequence select="es:getParents($this, es:getReferencedSchemas(root($this)))"/>
    </xsl:function>

    <xsl:function name="es:getParents" as="element()*">
        <xsl:param name="this" as="element()"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>


        <xsl:variable name="key-map" select="
                map {
                    'element': 'parentByElementRef',
                    'group': 'parentByGroupRef',
                    'attribute': 'elementByAttributename',
                    'simpleType': 'parentByType',
                    'complexType': 'parentByType'
                }
                "/>
        <xsl:variable name="key" select="$key-map($this/local-name())"/>

        <xsl:variable name="schemas" select="map:keys($schema-context) ! $schema-context(.)"/>

        <xsl:variable name="parents" select="$schemas/key($key, es:getName($this))"/>

        <xsl:sequence select="$parents"/>
    </xsl:function>

</xsl:stylesheet>
