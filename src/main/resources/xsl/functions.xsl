<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2000/svg" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:es="http://www.escali.schematron-quickfix.com/" exclude-result-prefixes="xs" version="3.0" xmlns:math="http://www.w3.org/2005/xpath-functions/math">

    <xsl:variable name="XSDNS" select="'http://www.w3.org/2001/XMLSchema'"/>

    <!--<xsl:param name="defaultColor" select="
            map {
                'main': '#007',
                'secondary': '#88f',
                'text': 'white'
            }"/>-->
    <!--<xsl:param name="colorScheme" select="
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
            }" as="map(xs:string, map(xs:string, xs:string))"/>-->

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



    <xsl:function name="es:getPrefixes" as="map(xs:string, xs:string)">
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>
        <xsl:sequence select="es:getPrefixes((map:keys($schema-context), $XSDNS), $schema-context)"/>
    </xsl:function>

    <xsl:function name="es:getPrefixes" as="map(xs:string, xs:string)">
        <xsl:param name="namespaces" as="xs:string*"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)"/>


        <xsl:variable name="head" select="head($namespaces)"/>
        <xsl:variable name="others" select="
            if (count($namespaces) gt 1) then es:getPrefixes(tail($namespaces), $schema-context) else map{}
            "/>

        <xsl:variable name="schema" select="$schema-context($head), $schema-context?*"/>

        <xsl:variable name="possiblePrefixes" select="$schema ! .//namespace::*[. = $head]/name()[. != '']"/>

        <xsl:variable name="unusedPrefixes" select="$possiblePrefixes[not(. = $others?*)]"/>

        <xsl:variable name="suffixedPrefix" select="
                if (empty($unusedPrefixes)) then
                    let $p := ($possiblePrefixes[1] ! (. || '_'), 'ns')[1]
                    return
                        ((1 to count($others?*) + 1) ! ($p || .)[not(. = $others?*)], 'ns1')
                else
                    ($unusedPrefixes)" as="xs:string*"/>

        <xsl:variable name="suffixedPrefix" select="$suffixedPrefix[1]" as="xs:string"/>

        <xsl:sequence select="map:put($others, $head, $suffixedPrefix)"/>

    </xsl:function>

    <xsl:function name="es:printQName" as="xs:string">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>

        <xsl:variable name="prefix-map" select="($schemaSetConfig?prefix-map, map{})[1]"/>

        <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>
        <xsl:variable name="local-name" select="local-name-from-QName($qname)"/>

        <xsl:variable name="prefix" select="
                if (map:contains($prefix-map, $namespace)) then
                    ($prefix-map($namespace))
                else
                    ()"/>

        <xsl:variable name="prefix" select="
                if ($prefix = '' or $namespace = '') then
                    ''
                else
                    if ($prefix) then
                        ($prefix || ':')
                    else
                        ('Q{' || $namespace || '}')"/>

        <xsl:sequence select="$prefix || $local-name"/>

    </xsl:function>

    <xsl:function name="es:error">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="message"/>
        <xsl:sequence select="error(QName('http://www.escali.schematron-quickfix.com/', $id), $message)"/>
    </xsl:function>

    <xsl:function name="es:exactly-one" as="item()">
        <xsl:param name="item" as="item()*"/>
        <xsl:param name="message"/>
        <xsl:sequence select="
                if (count($item) eq 1) then
                    ($item)
                else
                    es:error('exactly-one', $message)
                "/>
    </xsl:function>

    <xsl:function name="es:getQName" as="xs:QName">
        <xsl:param name="attr" as="attribute()"/>
        <xsl:sequence select="es:getQName(string($attr), $attr/parent::*)"/>
    </xsl:function>

    <xsl:function name="es:getQName" as="xs:QName">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="namespace-context" as="element()"/>
        <xsl:variable name="prefix" select="
                if (contains($name, ':')) then
                    replace($name, '([^:]+):.*', '$1')
                else
                    ''
                "/>
        <xsl:variable name="local-name" select="replace($name, '[^:]+:', '')"/>
        <xsl:variable name="namespace" select="$namespace-context/namespace::*[name() = $prefix]"/>
        <xsl:sequence select="
                if ($prefix != '' and not($namespace)) then
                    es:error('unbound-prefix', 'Unbound prefix ' || $prefix || ' at ' || path($namespace-context))
                else
                    QName(string($namespace), $name)"/>
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

                <xsl:if test="not($local-name castable as xs:NCName)">
                    <xsl:sequence select="es:error('bad-qname', 'Can not create QName for ' || name($node) || '. ''' || $local-name || ''' is not a valid NCName.')"/>
                </xsl:if>

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
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>

        <xsl:variable name="schema-context" select="$schemaSetConfig?schema-map" as="map(xs:string, document-node(element(xs:schema))*)"/>

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
                            es:getReferenceByQName($qnameRef, $schemaSetConfig, $element)"/>
            </xsl:otherwise>
        </xsl:choose>


    </xsl:function>

    <xsl:function name="es:getReferenceByQName" as="node()*">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <xsl:param name="refKind" as="xs:string*"/>

        <xsl:sequence select="es:getReferenceByQName($qname, $schemaSetConfig, $refKind, true())"/>
    </xsl:function>

    <xsl:function name="es:getReferenceByQName" as="node()*">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <xsl:param name="refKind" as="xs:string*"/>
        <xsl:param name="exactlyOneRef" as="xs:boolean"/>

        <xsl:variable name="schema-context" select="$schemaSetConfig?schema-map" as="map(xs:string, document-node(element(xs:schema))*)"/>


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
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('#default', $schemaSetConfig)"/>
        <xsl:param name="multiValue" select="$MultiValues[2]" as="xs:string"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:sequence</title>
        </xsl:param>

        <xsl:variable name="colorStroke" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cY="10">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="23.5"/>
            </xsl:if>
            <xsl:sequence select="$title"/>
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
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('#default', $schemaSetConfig)"/>
        <xsl:param name="multiValue" select="$MultiValues[2]" as="xs:string"/>
        <xsl:param name="connectCount" select="3"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:choice</title>
        </xsl:param>

        <xsl:variable name="colorStroke" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="es:cY" select="10"/>
                <xsl:attribute name="height" select="23.5"/>
            </xsl:if>
            <xsl:sequence select="$title"/>
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
    <xsl:template name="st_unionSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('#default', $schemaSetConfig)"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:union</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>
            <g>
                <rect width="19" height="19" x="0.5" y="0.5" rx="2.5" ry="2.5" fill="white" stroke="{$color}" stroke-width="1"/>
                <g>
                    <svg width="20" height="20" class="core">
                        <xsl:sequence select="$title"/>
                        <g transform="rotate(45, 10, 10)">
                            <circle r="6" stroke="{$color}" stroke-width="1" cx="10" cy="10" fill="white"/>
                            <circle r="2" fill="{$color}" cx="10" cy="4"/>
                            <circle r="2" fill="{$color}" cx="15.2" cy="13"/>
                            <circle r="2" fill="{$color}" cx="4.8" cy="13"/>
                        </g>
                    </svg>
                </g>
            </g>
        </svg>
    </xsl:template>
    <xsl:template name="st_listSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('simpleType', $schemaSetConfig)"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:list</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>
            <g>
                <rect width="19" height="19" x="0.5" y="0.5" rx="2.5" ry="2.5" fill="white" stroke="{$color}" stroke-width="1"/>
                <g transform="translate(4, 4)">
                    <svg width="13" height="13" class="core">
                        <g>
                            <rect width="2" height="2" x="1" y="2" fill="{$color}"/>
                            <rect width="2" height="2" x="1" y="5" fill="{$color}"/>
                            <rect width="2" height="2" x="1" y="8" fill="{$color}"/>
                            <rect width="6" height="2" x="4" y="2" fill="{$color}"/>
                            <rect width="6" height="2" x="4" y="5" fill="{$color}"/>
                            <rect width="6" height="2" x="4" y="8" fill="{$color}"/>
                        </g>
                    </svg>
                </g>
            </g>
        </svg>
    </xsl:template>
    <xsl:template name="extensionSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('#default', $schemaSetConfig)"/>
        <xsl:param name="connectCount" select="3"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:extension</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>
            <g>
                <rect width="19" height="19" x="0.5" y="0.5" rx="2.5" ry="2.5" fill="white" stroke="{$color}" stroke-width="1"/>
                <g transform="translate(4.5, 2.5)">
                    <svg width="13" height="13" class="core">
                        <xsl:sequence select="$title"/>
                        <g>
                            <rect width="4" height="4" x="1" y="3" fill="{$color}"/>
                            <rect width="4" height="4" x="1" y="8" fill="{$color}"/>
                            <rect width="4" height="4" x="6" y="8" fill="{$color}"/>
                            <rect width="4" height="4" x="7" y="2" fill="{$color}" transform="rotate(45, 9, 4)"/>
                        </g>
                    </svg>
                </g>
            </g>
        </svg>
    </xsl:template>
    <xsl:template name="restrictionSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('#default', $schemaSetConfig)"/>
        <xsl:param name="connectCount" select="3"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:restriction</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>
            <g>
                <rect width="19" height="19" x="0.5" y="0.5" rx="2.5" ry="2.5" fill="white" stroke="{$color}" stroke-width="1"/>
                <g transform="translate(4,4)">
                    <xsl:sequence select="$title"/>
                    <svg class="core" width="12" height="12">
                        <g>
                            <rect width="10" height="2" x="1" y="1.5" fill="{$color}"/>
                            <path d="M1 4 L 11 4 L 8 8 L 4 8z" fill="{$color}"/>
                            <rect width="4" height="2" x="4" y="8.5" fill="{$color}"/>
                        </g>
                    </svg>
                </g>
            </g>
        </svg>
    </xsl:template>

    <xsl:template name="anySymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('any', $schemaSetConfig)"/>
        <xsl:param name="connectCount" select="3"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:any</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>



        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>
            <g transform="translate(5, 9)">
                <rect width="10" height="2" fill="{$color}"/>
                <g transform="rotate(90, 5, 1)">
                    <rect width="10" height="2" fill="{$color}"/>
                </g>
                <g transform="rotate(45, 5, 1)">
                    <rect width="10" height="2" fill="{$color}"/>
                </g>
                <g transform="rotate(135, 5, 1)">
                    <rect width="10" height="2" fill="{$color}"/>
                </g>
            </g>
        </svg>
    </xsl:template>

    <xsl:template name="complexTypeSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('complexType', $schemaSetConfig)"/>
        <xsl:param name="connectCount" select="3"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:complexType</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>



        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>

            <g>
                <rect x="8" y="4" width="4" height="4" fill="{$colorFill}" stroke="{$color}" stroke-width="0.5"/>

                <rect x="8" y="12" width="4" height="4" fill="{$colorFill}" stroke="{$color}" stroke-width="0.5"/>
                <rect x="2" y="12" width="4" height="4" fill="{$colorFill}" stroke="{$color}" stroke-width="0.5"/>
                <rect x="14" y="12" width="4" height="4" fill="{$colorFill}" stroke="{$color}" stroke-width="0.5"/>

                <path d="M 10 8 L 10 12" stroke="{$color}" stroke-width="1"/>
                <path d="M 6 14 L 8 14" stroke="{$color}" stroke-width="1"/>
                <path d="M 12 14 L 14 14" stroke="{$color}" stroke-width="1"/>

            </g>

        </svg>
    </xsl:template>
    <xsl:template name="simpleTypeSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('simpleType', $schemaSetConfig)"/>
        <xsl:param name="connectCount" select="3"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:simpleType</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>

            <g>
                <path d="M 2 10 L 10 5 L 18 10 L 10 15Z" stroke="{$color}" fill="{$colorFill}" stroke-width="0.5"/>
            </g>

        </svg>
    </xsl:template>

    <xsl:template name="attributeSymbol">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="colors" select="es:getColors('attribute', $schemaSetConfig)"/>
        <xsl:param name="title" as="element(svg:title)">
            <title>xs:attribute</title>
        </xsl:param>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="colorFill" select="$colors?secondary"/>

        <svg width="20" height="20" es:cYTop="0" es:cXTop="10" es:cYRight="10" es:cXRight="20" es:cYBottom="20" es:cXBottom="10">
            <xsl:sequence select="$title"/>

            <g transform="translate(-19.5, -4)">
                <path stroke="{$color}" stroke-width="0.5" fill="{$colorFill}" d="
                    M26 18.966 
                    c -0.859 -0.472 -1.533 -1.136 -2.021 -1.992 
                    s -0.732 -1.832 -0.732 -2.928 
                    c 0 -1.112 0.246 -2.12 0.738 -3.024
                    c 0.492 -0.904 1.176 -1.614 2.052 -2.13
                    c 0.876 -0.516 1.874 -0.774 2.994-0.774
                    c 1.072 0 2.038 0.244 2.898 0.732
                    c 0.859 0.488 1.531 1.164 2.016 2.028 
                    c 0.484 0.864 0.727 1.84 0.727 2.928  
                    c 0 0.76 -0.12 1.448 -0.36 2.064
                    c -0.24 0.616 -0.588 1.104 -1.044 1.464 
                    c -0.456 0.36 -0.988 0.54 -1.596 0.54 
                    c -0.48 0 -0.851 -0.146 -1.11 -0.438
                    c -0.26 -0.292 -0.426 -0.762 -0.498 -1.41 
                    c -0.008 -0.056 -0.024 -0.088 -0.048 -0.096 
                    c -0.024 -0.008 -0.048 0.012 -0.072 0.06
                    c -0.232 0.392 -0.504 0.68 -0.815 0.864 
                    c -0.313 0.184 -0.673 0.276 -1.08 0.276 
                    c -0.648 0 -1.173 -0.22 -1.572 -0.66
                    c -0.4 -0.44 -0.601 -1.052 -0.601 -1.836 
                    c 0 -0.672 0.143 -1.324 0.427 -1.956 
                    c 0.283 -0.632 0.682 -1.148 1.193 -1.548
                    
                    c 0.513 -0.4 1.088 -0.6 1.729 -0.6 
                    c 0.344 0 0.636 0.068 0.876 0.204
                    s 0.456 0.364 0.647 0.684 
                    c 0.024 0.048 0.053 0.072 0.084 0.072
                    
                    c 0.04 0 0.064 -0.028 0.072 -0.084
                    l 0.084 -0.432 
                    c 0.016 -0.072 0.061 -0.108 0.132 -0.108
                    h 0.648 
                    c 0.088 0 0.124 0.044 0.107 0.132
                    
                    c -0.304 1.424 -0.527 2.512 -0.672 3.264 
                    c -0.144 0.752 -0.216 1.328 -0.216 1.728 
                    c 0 0.336 0.068 0.59 0.204 0.762
                    
                    c 0.136 0.172 0.336 0.258 0.6 0.258 
                    c 0.393 0 0.738 -0.14 1.038 -0.42 
                    c 0.301 -0.28 0.532 -0.662 0.696 -1.146
                    s 0.246 -1.022 0.246 -1.614
                    
                    c 0 -0.936 -0.2 -1.768 -0.6 -2.496 
                    c -0.4 -0.728 -0.959 -1.294 -1.675 -1.698
                    C 30.78 9.232 29.967 9.03 29.055 9.03
                    
                    c -0.952 0 -1.803 0.218 -2.55 0.654 
                    c -0.748 0.437 -1.328 1.034 -1.74 1.794 
                    c -0.412 0.76 -0.618 1.616 -0.618 2.568
                    
                    c 0 0.936 0.202 1.762 0.606 2.478 
                    c 0.403 0.716 0.966 1.268 1.686 1.656
                    s 1.544 0.582 2.472 0.582 
                    c 0.521 0 1.021 -0.076 1.5 -0.228
                    
                    l 0.048 -0.012 
                    c 0.057 0 0.085 0.036 0.085 0.108v0.696 
                    c 0 0.072 -0.036 0.12 -0.108 0.144 
                    c -0.448 0.136 -0.96 0.204 -1.536 0.204
                    
                    C 27.826 19.674 26.86 19.438 26 18.966z 
                    
                    M29.313 15.744 
                    c 0.372 -0.324 0.662 -0.74 0.87 -1.248 
                    c 0.208 -0.508 0.312 -1.018 0.312 -1.53
                    
                    c 0 -0.52 -0.109 -0.904 -0.33 -1.152 
                    c -0.22 -0.248 -0.525 -0.372 -0.918 -0.372 
                    c -0.479 0 -0.907 0.156 -1.283 0.468
                    c -0.377 0.312 -0.669 0.716 -0.876 1.212 
                    c -0.209 0.496 -0.313 1.004 -0.313 1.524 
                    c 0 0.536 0.112 0.934 0.336 1.194
                    
                    s 0.536 0.39 0.937 0.39
                    C 28.519 16.23 28.94 16.068 29.313 15.744z
                    "/>
            </g>

        </svg>
    </xsl:template>

    <xsl:function name="es:getSymbol" as="element(svg:svg)?">
        <xsl:param name="type"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <xsl:choose>
            <xsl:when test="$type = 'attribute'">
                <xsl:call-template name="attributeSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'simpleType'">
                <xsl:call-template name="simpleTypeSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'complexType'">
                <xsl:call-template name="complexTypeSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'extension'">
                <xsl:call-template name="extensionSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'restriction'">
                <xsl:call-template name="restrictionSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = ('any', 'schema')">
                <xsl:call-template name="anySymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'choice'">
                <xsl:call-template name="choiceSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'sequence'">
                <xsl:call-template name="sequenceSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'list'">
                <xsl:call-template name="st_listSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = 'union'">
                <xsl:call-template name="st_unionSymbol">
                    <xsl:with-param name="schemaSetConfig" select="$schemaSetConfig" tunnel="yes"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$type = ('element', 'schema')"/>
            <xsl:otherwise>
                <xsl:sequence select="es:error('bad-symbol-type-request', 'No symbol for type ' || $type || ' available.')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template name="groupTitle">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="colors" select="es:getColors('#default', $schemaSetConfig)"/>
        <xsl:param name="color" select="$colors?main"/>
        <xsl:param name="font-color" select="$colors?text"/>

        <xsl:call-template name="boxTitle">
            <xsl:with-param name="title" select="$title"/>
            <xsl:with-param name="font-color" select="$font-color"/>
            <xsl:with-param name="symbol">
                <svg width="15" height="15">
                    <rect width="5" height="5" x="1" y="1" fill="{$color}" opacity="0.5"/>
                    <rect width="5" height="5" x="1" y="9" fill="{$color}" opacity="0.5"/>
                    <rect width="5" height="5" x="9" y="9" fill="{$color}" opacity="0.5"/>
                    <rect width="5" height="5" x="1" y="1" fill="none" stroke="{$color}" stroke-width="0.75" opacity="1"/>
                    <rect width="5" height="5" x="1" y="9" fill="none" stroke="{$color}" stroke-width="0.75" opacity="1"/>
                    <rect width="5" height="5" x="9" y="9" fill="none" stroke="{$color}" stroke-width="0.75" opacity="1"/>
                </svg>
            </xsl:with-param>
        </xsl:call-template>

    </xsl:template>

    <xsl:template name="boxTitle">
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="font-color" select="'black'"/>
        <xsl:param name="symbol" as="node()?"/>
        <xsl:param name="bold" select="false()" as="xs:boolean" tunnel="yes"/>
        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="weight" select="
                if ($bold) then
                    ('bold')
                else
                    ('normal')"/>
        <xsl:variable name="symbol" select="$symbol/(self::svg:svg, svg:svg)[1]"/>
        <xsl:variable name="symbolWidth" select="es:number($symbol/@width)"/>
        <xsl:variable name="space" select="6"/>
        <xsl:variable name="width" select="es:renderedTextLength($title, 'Arial', $weight, $fontSize) + $symbolWidth + 4 * $space + 3"/>

        <svg width="{max(($width, 0))}" height="25">
            <g transform="translate(3,3)">
                <g transform="translate({$space}, {$space div 2})">
                    <xsl:sequence select="$symbol"/>
                </g>
                <text x="{$symbolWidth + 2 * $space}" y="13" fill="{$font-color}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}" font-weight="{$weight}">
                    <xsl:value-of select="$title"/>
                </text>
            </g>
        </svg>
    </xsl:template>


    <xsl:template name="drawObjectPaths">
        <xsl:param name="content" as="element(svg:svg)*"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="strokeColor" as="xs:string" select="es:getColors('#default', $schemaSetConfig)?main"/>
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
                        es:number($content/@es:cY)"/>
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

    <xsl:variable name="piHalf" select="math:pi() div 2"/>


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
                            ($piHalf - math:atan($yDiv div $xDiv))
                        else
                            (0)"/>
                <xsl:variable name="gabXdiv" select="math:cos($angle) * $doubleGap div 2"/>
                <xsl:variable name="gabYdiv" select="math:sin($angle) * $doubleGap div 2"/>
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


    <xsl:function name="es:createDoku" as="element(svg:foreignObject)?">
        <xsl:param name="element" as="element()"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <xsl:sequence select="es:createDoku($element/xs:annotation, $element/local-name(), $schemaSetConfig)"/>
    </xsl:function>

    <xsl:function name="es:createDoku" as="element(svg:foreignObject)?">
        <xsl:param name="annotation" as="element(xs:annotation)*"/>
        <xsl:param name="color-scheme" as="xs:string"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <foreignObject es:color-scheme="{es:getColors($color-scheme, $schemaSetConfig) => serialize(map{'method' : 'json'})}">
            <xsl:sequence select="$annotation"/>
        </foreignObject>
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

    <xsl:function name="es:renderedTextLength" as="xs:double">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="fontStyle" as="map(*)"/>
        <xsl:variable name="result" select="-1"/>
        <xsl:variable name="result" use-when="function-available('r2d:getWidth')" xmlns:font="java:java.awt.Font" xmlns:frc="java:java.awt.font.FontRenderContext" xmlns:at="java:java.awt.geom.AffineTransform" xmlns:r2d="java:java.awt.geom.Rectangle2D">
            <!--        
            AffineTransform affinetransform = new AffineTransform();     
            FontRenderContext frc = new FontRenderContext(affinetransform,true,true);     
            Font font = new Font("Tahoma", Font.PLAIN, 12);
            int textwidth = (int)(font.getStringBounds(text, frc).getWidth());
            -->
            <xsl:variable name="affinetransform" select="at:new()"/>
            <xsl:variable name="frc" select="frc:new($affinetransform, true(), true())"/>
            <xsl:variable name="jfont" select="font:new($fontStyle?font, 0, xs:integer($fontStyle?size))"/>
            <xsl:variable name="r2d" select="font:getStringBounds($jfont, $text, $frc)"/>
            <xsl:sequence select="r2d:getWidth($r2d)"/>
        </xsl:variable>
        <xsl:variable name="result" use-when="function-available('es:textdimensions')">
            <xsl:sequence select="es:textdimensions($text, map:put($fontStyle, 'unit', 'pt'))?width ! xs:double(.)"/>
        </xsl:variable>
        <xsl:sequence select="$result"/>

    </xsl:function>

    <xsl:function name="es:renderedTextLength" as="xs:double">
        <xsl:param name="text" as="xs:string"/>
        <xsl:param name="font" as="xs:string"/>
        <xsl:param name="style" as="xs:string"/>
        <xsl:param name="font-size" as="xs:double"/>

        <xsl:variable name="style" select="
                if ($style ! lower-case(.) ! normalize-space(.) = 'normal') then
                    ('plain')
                else
                    $style"/>

        <xsl:variable name="fontinfo" select="
                map {
                    'font': $font,
                    'style': $style,
                    'size': $font-size
                }"/>

        <xsl:sequence select="es:renderedTextLength($text, $fontinfo)"/>

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

        <xsl:variable name="importSchemas" select="
                for $iu
                in ($importURIs)[not(. = $knownURIs)]
                return
                    es:getReferencedSchemas(doc($iu),
                    ($knownURIs, $schemaUri, $importURIs, $includeURIs))" as="map(xs:string, document-node(element(xs:schema))*)*"/>

        <xsl:variable name="includeSchemas" select="
                for $iu
                in ($includeURIs)[not(. = ($knownURIs, $schemaUri))]
                return
                    es:getReferencedSchemas(doc($iu),
                    ($knownURIs, $schemaUri, $importURIs, $includeURIs))" as="map(xs:string, document-node(element(xs:schema))*)*"/>



        <xsl:variable name="maps" select="map {$namespaceuri: $schema}, $importSchemas, $includeSchemas"/>
        <xsl:sequence select="
                map:merge($maps, map {'duplicates': 'combine'})"/>
    </xsl:function>

    <xsl:function name="es:getColors">
        <xsl:param name="type" as="xs:string"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>

        <xsl:variable name="colorScheme" select="$schemaSetConfig?config?styling?colors"/>
        <xsl:choose>
            <xsl:when test="map:contains($colorScheme, $type)">
                <xsl:sequence select="$colorScheme($type)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="no" expand-text="yes">Unknown color type {$type}, using default color set.</xsl:message>
                <xsl:sequence select="$colorScheme('#default')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!--<xsl:function name="es:getParents" as="element()*">
        <xsl:param name="this" as="element()"/>
        <xsl:sequence select="es:getParents($this, es:getReferencedSchemas(root($this)))"/>
    </xsl:function>-->

    <xsl:function name="es:getParents" as="element()*">
        <xsl:param name="this" as="element()"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>


        <xsl:variable name="schema-context" select="$schemaSetConfig?schema-map" as="map(xs:string, document-node(element(xs:schema))*)"/>


        <xsl:choose>
            <xsl:when test="$this/parent::xs:schema">

                <xsl:variable name="key-map" select="
                        map {
                            'element': 'parentByElementRef',
                            'group': 'parentByGroupRef',
                            'attribute': 'elementByAttributename',
                            'attributeGroup': 'elementByAttributename',
                            'simpleType': 'parentByType',
                            'complexType': 'parentByType'
                        }
                        "/>

                <xsl:variable name="key" select="$key-map($this/local-name())"/>

                <xsl:variable name="key" select="es:exactly-one($key, 'No parents available for ' || $this/local-name() || ' elements.')"/>

                <xsl:variable name="schemas" select="map:keys($schema-context) ! $schema-context(.)"/>

                <xsl:variable name="parents" select="$schemas/key($key, es:getName($this))"/>

                <xsl:sequence select="$parents"/>

            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$this/ancestor::*[@name][1]"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:function name="es:getUses" as="element()*">
        <xsl:param name="component"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>


        <xsl:variable name="containedLocals" select="$component//(xs:element | xs:attribute)[@name]"/>

        <xsl:variable name="ignores" select="$containedLocals//*"/>

        <xsl:variable name="containedLocals" select="$containedLocals except $ignores"/>

        <xsl:variable name="typeRef" select="$component/(self::xs:element | self::xs:attribute)/@type/es:getReference(., $schemaSetConfig)"/>

        <xsl:variable name="children" select="$component//xs:* except $ignores"/>
        <xsl:variable name="refs" select="$children/(@ref | @base | @itemType)/es:getReference(., $schemaSetConfig)"/>

        <xsl:variable name="memberTypes" select="
                $children/@memberTypes/(
                for $mt in tokenize(., '\s')
                return
                    es:getReferenceByQName(es:getQName($mt, ..), $schemaSetConfig, 'simpleType', false())
                )
                "/>


        <xsl:sequence select="$containedLocals | $typeRef | $refs | $memberTypes"/>

    </xsl:function>

    <xsl:function name="es:mergeMaps" as="map(*)">
        <xsl:param name="maps" as="map(*)*"/>

        <xsl:sequence select="fold-left($maps, map{}, es:mergeMaps#2)"/>

    </xsl:function>

    <xsl:function name="es:mergeMaps" as="map(*)">
        <xsl:param name="map1" as="map(*)"/>
        <xsl:param name="map2" as="map(*)"/>

        <xsl:map>
            <xsl:for-each select="(($map1, $map2) ! map:keys(.)) => distinct-values()">
                <xsl:variable name="key" select="."/>
                <xsl:variable name="value1" select="$map1($key)"/>
                <xsl:variable name="value2" select="$map2($key)"/>
                <xsl:map-entry key="$key" select="
                        if ($value1 instance of map(*) and $value2 instance of map(*)) then
                            es:mergeMaps($value1, $value2)
                        else
                            if (empty($value1)) then
                                ($value2)
                            else
                                ($value1)
                        "/>
            </xsl:for-each>
        </xsl:map>
    </xsl:function>




    <!--    
    Component Info
    -->

    <xsl:function name="es:group-components" as="map(xs:string, item()*)">
        <xsl:param name="components" as="map(xs:string, item()*)*"/>
        <xsl:param name="grouping" as="xs:string*"/>

        <xsl:variable name="first-grouping" select="head($grouping)"/>
        <xsl:variable name="rest-grouping" select="tail($grouping)"/>

        <xsl:map>
            <xsl:for-each-group select="$components" group-by=".($first-grouping)">
                <xsl:sequence select="map{
                    string(current-grouping-key()) : if (empty($rest-grouping)) then (current-group()) else es:group-components(current-group(), $rest-grouping)
                    }"/>
            </xsl:for-each-group>
        </xsl:map>

    </xsl:function>

    <xsl:function name="es:getComponentInfos" as="map(xs:string, item()*)*">
        <xsl:param name="schemaSetConfig" as="map(xs:string, map(*))"/>
        <xsl:sequence select="es:getComponentInfos($schemaSetConfig, '*')"/>
    </xsl:function>

    <xsl:function name="es:getComponentInfos" as="map(xs:string, item()*)*">
        <xsl:param name="schemaSetConfig" as="map(xs:string, map(*))"/>
        <xsl:param name="types" as="xs:string*"/>
        <xsl:sequence select="es:getComponentInfos($schemaSetConfig, $types, '*')"/>
    </xsl:function>

    <xsl:function name="es:getComponentInfos" as="map(xs:string, item()*)*">
        <xsl:param name="schemaSetConfig" as="map(xs:string, map(*))"/>
        <xsl:param name="types" as="xs:string*"/>
        <xsl:param name="namesapce" as="xs:string*"/>
        <xsl:sequence select="es:getComponentInfos($schemaSetConfig, $types, $namesapce, '*')"/>
    </xsl:function>

    <xsl:function name="es:getComponentInfos" as="map(xs:string, item()*)*">
        <xsl:param name="schemaSetConfig" as="map(xs:string, map(*))"/>
        <xsl:param name="types" as="xs:string*"/>
        <xsl:param name="namesapce" as="xs:string*"/>
        <xsl:param name="levels" as="xs:string*"/>


        <xsl:variable name="schema-map" select="$schemaSetConfig?schema-map" as="map(xs:string, document-node(element(xs:schema))*)"/>

        <xsl:variable name="schemas" select="
                if ($namesapce = '*') then
                    ($schema-map?*)
                else
                    ($namesapce ! $schema-map(.))" as="document-node(element(xs:schema))*"/>

        <xsl:variable name="globals" select="$schemas/xs:*[@name]"/>
        <xsl:variable name="locals" select="$schemas/xs:*//xs:*[@name]"/>

        <xsl:variable name="all-components" select="$globals[$levels = ('global', '*')], $locals[$levels = ('locals', '*')]"/>

        <xsl:variable name="components" select="$all-components[(local-name(), '*') = $types]"/>

        <xsl:sequence select="$components ! es:getComponentInfo(., $schemaSetConfig)"/>

    </xsl:function>


    <xsl:function name="es:getComponentInfo" as="map(xs:string, item()*)">
        <xsl:param name="comp" as="element()"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, map(*))"/>

        <xsl:variable name="nested" select="$comp//xs:*[@name]"/>
        <xsl:variable name="nested" select="$nested except $nested//*"/>
        <xsl:variable name="nested-by" select="$comp/ancestor::*[@name][1]"/>

        <xsl:variable name="coreInfo" select="es:getComponentCoreInfo($comp)"/>

        <xsl:variable name="detailInfo" select="
            map{
            'used-by' : $comp/es:getParents(., $schemaSetConfig) ! es:getComponentCoreInfo(.),
            'uses' : $comp/es:getUses(., $schemaSetConfig) ! es:getComponentCoreInfo(.),
            'nested' : $nested/es:getComponentCoreInfo(.),
            'nested-by' : $nested-by/es:getComponentCoreInfo(.),
            'svg-model' : es:svg-model($comp, $schemaSetConfig)
            }
            "/>

        <xsl:sequence select="
                ($coreInfo, $detailInfo) => map:merge()
                "/>

    </xsl:function>
    <xsl:function name="es:getComponentCoreInfo" as="map(xs:string, item()*)">
        <xsl:param name="comp" as="element()"/>

        <xsl:sequence select="
            map{
                'id' : $comp/generate-id(),
                'component' : $comp,
                'type' : $comp/local-name(),
                'namespace' : ($comp/root(.)/xs:schema/@targetNamespace/string(.), '')[1],
                'scope' : if ($comp/parent::xs:schema) then ('global') else ('local'),
                'qname' : es:getName($comp)
            }"/>

    </xsl:function>

    <xsl:function name="es:svg-model">
        <xsl:param name="xsdnode" as="element()"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, map(*))"/>
        <!--    
                Dummy implementation! 
                will be overwritten in  xsd2svg_model-pipe.xsl
        -->
    </xsl:function>

    <xsl:function name="es:getMasterFiles" as="xs:anyURI*">
        <xsl:param name="url" as="xs:anyURI"/>
        <xsl:variable name="collection-urls" select="uri-collection($url)"/>

        <!--        
        make for each XSD url an include map
        key: schema url
        values: urls of included schemas (same namespace!)
        -->
        <xsl:variable name="schema-include-map" select="
                ($collection-urls !
                map {
                    .:
                    let $doc := doc(.),
                        $tns := ($doc/*/@targetNamespace, '')[1]
                    return
                        es:getReferencedSchemas($doc)($tns) ! base-uri(/)
                }
                ) => map:merge()
                "/>

        <!--
        make a "reverse map" of $schema-include-map:
        key: schema-url, 
        values: urls which includes this schema.
        -->
        <xsl:variable name="schema-include-reverse-map" select="
            $collection-urls ! (
            let $url := . return
            $schema-include-map(.) ! map{
            . : $url
            }
            ) => map:merge(map{'duplicates': 'combine'})
            "/>

        <!--        
        Returns all urls, which are not included by any other url.
        -->
        <xsl:sequence select="$collection-urls[count($schema-include-reverse-map(.)) = 1]"/>
    </xsl:function>

</xsl:stylesheet>
