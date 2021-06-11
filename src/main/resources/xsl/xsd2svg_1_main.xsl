<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:es="http://www.escali.schematron-quickfix.com/" xmlns:svg="http://www.w3.org/2000/svg" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" exclude-result-prefixes="#all" version="3.0">




    <xsl:mode name="es:xsd2svg-parent"/>
    <xsl:mode name="es:xsd2svg-content"/>


    
<!--    
    Model main elements
    -->

    <xsl:template match="xs:schema/xs:element[@name] | xs:schema/xs:attribute[@name]" mode="es:xsd2svg" priority="10">
        <xsl:param name="elementName" select="es:getName(.)" as="xs:QName"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:param name="colors" select="$colorScheme(local-name())"/>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="fill" select="$colors?secondary"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:* except xs:annotation | @type" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="color" select="$color"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>


        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs"/>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>
        <xsl:variable name="dokuWidth" select="es:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>

        <xsl:variable name="maxCY" select="max(($contentSVGs/@es:cY, $elementHeight div 2, $parents/@es:cY))"/>

        <xsl:variable name="parentPosY" select="es:number($maxCY - $parents/@es:cY)"/>
        <xsl:variable name="elementPosY" select="es:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="es:number($maxCY - $contentSVGs/@es:cY)"/>

        <xsl:variable name="posY" select="max(($contentSVGs/@es:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>

        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{es:convertId(string($elementName))}" es:cY="{$contentSVGs/@es:cY}" es:displayW="{$dokuWidth}" es:displayH="{max(($dokuHeight - $elementHeight, 0))}">
            <desc/>
            <xsl:variable name="fontSize" select="11"/>
            <xsl:variable name="paddingLR" select="5"/>
            <xsl:variable name="width" select="es:renderedTextLength(es:printQName($elementName, $schema-context), 'Arial', 'plain', $fontSize)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
            <xsl:variable name="parentWidth" select="es:number(max($parents/@width))"/>

            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <g>
                    <rect width="{$width}" height="25" rx="10" ry="10" stroke="{$color}" stoke-width="1" fill="{$fill}"/>
                </g>
                <text x="{$paddingLR}" y="16" fill="{$colors?text}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$elementName"/>
                </text>
            </g>
            <xsl:for-each select="$contentSVGs">
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height) + $contentPosY"/>
                <g transform="translate({$width + $parentWidth}, {$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>
            <g transform="translate({$width + $parentWidth}, {$elementPosY})">
                <xsl:copy-of select="$doku"/>
            </g>

            <g transform="translate(0,{$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>

        </svg>
    </xsl:template>

    <xsl:template match="xs:schema/xs:complexType[@name]" mode="es:xsd2svg" priority="10">
        <xsl:param name="elementName" select="es:getName(.)" as="xs:QName"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>
        <xsl:param name="content-line" select="exists(self::xs:complexType)" as="xs:boolean"/>

        <xsl:variable name="colors" select="$colorScheme(local-name(.))"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>

        <xsl:variable name="content">
            <xsl:apply-templates select=". except xs:annotation" mode="es:xsd2svg-content"/>
        </xsl:variable>

        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="color" select="$colors?main"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs"/>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>
        <xsl:variable name="dokuWidth" select="es:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>

        <xsl:variable name="maxCY" select="max(($contentSVGs/@es:cY, $elementHeight div 2, $parents/@es:cY))"/>

        <xsl:variable name="parentPosY" select="es:number($maxCY - $parents/@es:cY)"/>
        <xsl:variable name="elementPosY" select="es:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="es:number($maxCY - $contentSVGs/@es:cY)"/>

        <xsl:variable name="posY" select="max(($contentSVGs/@es:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>

        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{es:convertId(string($elementName))}" es:cY="{$contentSVGs/@es:cY}" es:displayW="{$dokuWidth}" es:displayH="{max(($dokuHeight - $elementHeight, 0))}">
            <desc/>
            <xsl:variable name="fontSize" select="11"/>
            <xsl:variable name="paddingLR" select="5"/>
            <xsl:variable name="width" select="es:renderedTextLength(es:printQName($elementName, $schema-context), 'Arial', 'plain', $fontSize)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
            <xsl:variable name="parentWidth" select="es:number(max($parents/@width))"/>

            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <g>
                    <rect width="{$width}" height="25" rx="10" ry="10" stroke="{$colors?main}" stoke-width="1" fill="{$colors?secondary}"/>
                </g>
                <text x="{$paddingLR}" y="16" fill="{$colors?text}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$elementName"/>
                </text>
            </g>
            <xsl:for-each select="$contentSVGs">
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height) + $contentPosY"/>
                <g transform="translate({$width + $parentWidth}, {$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>
            <g transform="translate({$width + $parentWidth}, {$elementPosY})">
                <xsl:copy-of select="$doku"/>
            </g>

            <g transform="translate(0,{$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>

        </svg>
    </xsl:template>

    <xsl:template match="xs:simpleType[@name]" mode="es:xsd2svg">
        <xsl:param name="typeName" select="es:getName(.)" as="xs:QName"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:variable name="colors" select="$colorScheme(local-name(.))"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>
        
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" as="element(svg:svg)?">
                    <xsl:apply-templates select="xs:* except xs:annotation" mode="es:xsd2svg-content">
                        <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                        <xsl:with-param name="cY" select="$cY"/>
                        <xsl:with-param name="st-table-title" select="'Simple Type Facets'" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:with-param>
                <xsl:with-param name="strokeColor" select="$colors?main"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="color" select="$colors?main"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs"/>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>
        <xsl:variable name="dokuWidth" select="es:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>
        
        <xsl:variable name="maxCY" select="max(($contentSVGs/@es:cY, $elementHeight div 2, $parents/@es:cY))"/>
        
        <xsl:variable name="parentPosY" select="es:number($maxCY - $parents/@es:cY)"/>
        <xsl:variable name="elementPosY" select="es:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="es:number($maxCY - $contentSVGs/@es:cY)"/>
        
        <xsl:variable name="posY" select="max(($contentSVGs/@es:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>
        
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{es:convertId(string($typeName))}" es:cY="{$contentSVGs/@es:cY}" es:displayW="{$dokuWidth}" es:displayH="{max(($dokuHeight - $elementHeight, 0))}">
            <desc/>
            <xsl:variable name="fontSize" select="11"/>
            <xsl:variable name="paddingLR" select="5"/>
            <xsl:variable name="label" select="es:printQName($typeName, $schema-context)"/>
            <xsl:variable name="width" select="es:renderedTextLength($label, 'Arial', 'plain', $fontSize)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
            <xsl:variable name="parentWidth" select="es:number(max($parents/@width))"/>
            
            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <g>
                    <rect width="{$width}" height="25" rx="10" ry="10" stroke="{$colors?main}" stoke-width="1" fill="{$colors?secondary}"/>
                </g>
                <text x="{$paddingLR}" y="16" fill="{$colors?text}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$label"/>
                </text>
            </g>
            <xsl:for-each select="$contentSVGs">
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height) + $contentPosY"/>
                <g transform="translate({$width + $parentWidth}, {$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>
            <g transform="translate({$width + $parentWidth}, {$elementPosY})">
                <xsl:copy-of select="$doku"/>
            </g>
            
            <g transform="translate(0,{$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>
            
        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" name="namedGroup" mode="es:xsd2svg">
        <xsl:param name="id" select="generate-id()"/>
        <xsl:param name="multiValue" select="$MultiValues[2]"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>
        <xsl:param name="isRoot" select="true()" as="xs:boolean"/>

        <xsl:variable name="colors" select="$colorScheme(local-name(.))"/>

        <xsl:variable name="color" select="$colors?main"/>
        <xsl:variable name="groupName" select="es:getName(.)"/>
        <xsl:variable name="hoverId" select="concat($model-id, '_group_', $id)"/>
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:* except xs:annotation" mode="es:xsd2svg-content"/>
        </xsl:variable>
        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="15"/>
                <xsl:with-param name="invisible_ids" select="$content//svg:set/@es:dokuViewer" tunnel="yes"/>
                <xsl:with-param name="color" select="$color"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="dokuSVG" select="$doku/es:docu/svg:svg"/>
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="strokeColor" select="$color"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>

        <xsl:variable name="parents">
            <xsl:if test="$isRoot">
                <xsl:call-template name="makeParentSVGs"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="parentsWidth" select="es:number($parents/@width)"/>
        <xsl:variable name="parentsHeight" select="es:number($parents/@height)"/>
        <xsl:variable name="parentsCY" select="es:number($parents/@es:cY)"/>

        <xsl:variable name="header">
            <xsl:call-template name="groupTitle">
                <xsl:with-param name="title" select="es:printQName($groupName, $schema-context)"/>
                <xsl:with-param name="color" select="$color"/>
                <xsl:with-param name="font-color" select="'black'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="header" select="$header/svg:svg"/>

        <xsl:variable name="cY" select="$content/@es:cY + $header/@height + 7.5"/>


        <xsl:variable name="maxCY" select="max(($cY, $parents/@es:cY))"/>

        <xsl:variable name="parentPosY" select="es:number($maxCY - $parentsCY)"/>
        <xsl:variable name="groupPosY" select="es:number($maxCY - $cY)"/>
        <xsl:variable name="groupHeight" select="sum(($content/@height, $header/@height))"/>

        <xsl:variable name="width" select="max(($content/@width, $header/@width))"/>
        <xsl:variable name="height" select="max(($groupHeight, $parentsHeight))"/>


        <svg width="{$width + 7.5 + $parentsWidth}" height="{$height + 15}" es:cY="{$cY}" es:displayW="{es:number($dokuSVG/@width)}" es:displayH="{es:number($dokuSVG/@height)}" class="element_group" es:multiValue="{$multiValue}">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="$height + 18.5"/>
            </xsl:if>
            <g transform="translate({$parentsWidth}, {$groupPosY + 5})" id="{$hoverId}">

                <xsl:variable name="rect">
                    <rect width="{$width + 2.5}" height="{$groupHeight + 5}" rx="7" ry="7" fill="white" stroke="{$color}" stroke-width="1">
                        <xsl:if test="$multiValue = ($MultiValues[1], $MultiValues[3])">
                            <xsl:attribute name="stroke-dashoffset" select="2"/>
                            <xsl:attribute name="stroke-dasharray" select="2"/>
                        </xsl:if>
                    </rect>
                </xsl:variable>
                <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                    <rect>
                        <xsl:copy-of select="$rect/svg:rect/@*"/>
                        <xsl:attribute name="y" select="3.5"/>
                        <xsl:attribute name="stroke-width" select="0.33"/>
                    </rect>
                    <rect>
                        <xsl:copy-of select="$rect/svg:rect/@*"/>
                        <xsl:attribute name="y" select="2"/>
                        <xsl:attribute name="stroke-width" select="0.66"/>
                    </rect>
                </xsl:if>
                <xsl:copy-of select="$rect"/>
                <rect width="{$width + 2.5}" height="{$groupHeight + 5}" rx="7" ry="7" fill="white" stroke="{$color}" stroke-width="1"/>
                <xsl:variable name="headerWithBorder">
                    <xsl:copy-of select="$header"/>
                    <path d="M 2.5 {$header/@height} L {$width} {$header/@height}" fill="none" stroke="{$color}" stroke-width="0.25"/>
                </xsl:variable>

                <xsl:if test="$isRoot">
                    <path fill="{$color}" opacity="0.1">
                        <xsl:attribute name="d" select="
                                'M', 0, $header/@height,
                                'L', 0, 7,
                                'Q', 0, 0, 7, 0,
                                'L', $width - 4.5, 0,
                                'Q', $width + 2.5, 0, $width + 2.5, 7,
                                'L', $width + 2.5, $header/@height, 'Z'"/>
                    </path>
                </xsl:if>
                <xsl:copy-of select="$headerWithBorder"/>
                
                <g transform="translate({$width + 1}, 0)" es:z-index="0">
                    <xsl:copy-of select="$dokuSVG"/>
                </g>
                <g transform="translate(0, {$header/@height + 2.5})">
                    <xsl:copy-of select="$content"/>
                </g>
            </g>
            <g transform="translate(0, {$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>
        </svg>
    </xsl:template>

<!--
    Model contents
    -->
    <xsl:template match="xs:attribute[@name] | xs:element[@name]" mode="es:xsd2svg-content">
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="multiValue" select="es:getMultiValue(.)" as="xs:string"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:variable name="colors" select="$colorScheme(local-name(.))"/>

        <xsl:variable name="attributName" select="es:getName(.)"/>
        <xsl:variable name="elementHeight" select="
                if (@type) then
                    40
                else
                    25"/>
        <xsl:variable name="position" select="(0, 2.5)"/>
        <xsl:variable name="cY" select="$position[2] + ($elementHeight div 2)"/>

        <xsl:variable name="stroke" select="$colors?main"/>

        <xsl:variable name="type-target" select="@type/es:getReference(., $schema-context)"/>
        <xsl:variable name="type-mode" select="($type-target/local-name(), 'simpleType')[1]"/>
        <xsl:variable name="type-bg" select="$colorScheme($type-mode)?secondary"/>
        <xsl:variable name="type-text-color" select="$colorScheme($type-mode)?text"/>


        <xsl:variable name="hoverId" select="concat($model-id, '_attributName_', generate-id())"/>
        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="#current">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="color" select="$stroke"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>
        <xsl:variable name="dokuWidth" select="es:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>


        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="label" select="es:printQName($attributName, $schema-context)"/>
        <xsl:variable name="typeLabel" select="
                if (@type) then
                    'Type: ' || es:printQName(es:getQName(@type), $schema-context)
                else
                    ''"/>
        <xsl:variable name="widths" select="
                es:renderedTextLength($label, 'Arial', 'plain', $fontSize),
                es:renderedTextLength($typeLabel, 'Arial', 'plain', $fontSize)
                "/>

        <xsl:variable name="width" select="$widths => max()"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
        <svg width="{$width}" height="{$elementHeight + 5}" es:cY="{$cY}" class="attribute" id="{$model-id}_attribute_{es:convertId($label)}" es:displayW="{$dokuWidth}" es:displayH="{max(($dokuHeight - ($elementHeight + 5), 0))}" es:multiValue="{$multiValue}">
            <desc/>
            <g alignment-baseline="baseline" transform="translate({$position[1]}, {$position[2]})" id="{$hoverId}">
                <g>
                    <xsl:if test="@type">
                        <rect width="{$width}" height="{$elementHeight div 2}" x="0" y="{$elementHeight div 2}" fill="{$type-bg}" ry="10" rx="10"/>
                        <rect width="{$width}" height="{$elementHeight div 2 - 10}" x="0" y="{$elementHeight div 2}" fill="{$type-bg}"/>
                        <!--                        <rect width="{$width}" height="{$titleHeight - 7.5}" x="0" y="7.5" fill="{$type-bg}"/>-->
                    </xsl:if>
                    <rect height="{$elementHeight}" width="{$width}" rx="10" ry="10" stroke="{$stroke}" stoke-width="1" fill="none">
                        <xsl:if test="$multiValue = $MultiValues[1]">
                            <xsl:attribute name="stroke-dasharray" select="5, 5" separator=","/>
                        </xsl:if>
                    </rect>
                </g>
                <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$label"/>
                </text>
                <xsl:if test="@type">
                    <text x="{$paddingLR}" y="32" fill="{$type-text-color}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                        <xsl:value-of select="$typeLabel"/>
                    </text>
                </xsl:if>
            </g>
            <g transform="translate({$width}, 0)" es:z-index="0">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:element/@type | xs:attribute/@type" mode="es:xsd2svg-content">
        <xsl:param name="typeName" select="es:getQName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:variable name="namespace" select="namespace-uri-from-QName($typeName)"/>

        <xsl:variable name="reference" select="es:getReference(., $schema-context)"/>

        <xsl:variable name="isXsd" select="$namespace = $XSDNS"/>

        <xsl:variable name="kindOfType" select="
                if ($isXsd) then
                    'simpleType'
                else
                    local-name($reference)"/>

        <xsl:variable name="colors" select="$colorScheme($kindOfType)"/>


        <xsl:variable name="content">

            <xsl:choose>
                <xsl:when test="$isXsd">

                    <xsl:call-template name="xsdSimpleTypeRef">
                        <xsl:with-param name="typeName" select="$typeName"/>
                    </xsl:call-template>

                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="elementRef">
                        <xsl:with-param name="elementName" select="$typeName"/>
                        <xsl:with-param name="multiValue" select="'one'"/>
                        <xsl:with-param name="refAttribute" select="."/>
                        <xsl:with-param name="colors" select="$colors"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
            <xsl:with-param name="strokeColor" select="$colors?main"/>
        </xsl:call-template>

    </xsl:template>

    <xsl:template match="xs:element[@ref] | xs:attribute[@ref]" name="elementRef" mode="es:xsd2svg-content">
        <xsl:param name="elementName" select="es:getName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>
        <xsl:param name="multiValue" select="es:getMultiValue(.)"/>
        <xsl:param name="refAttribute" select="@ref" as="attribute()?"/>
        <xsl:param name="refTarget" select="$refAttribute/es:getReference(., $schema-context)" as="node()?"/>
        <xsl:param name="colors" select="$colorScheme(local-name($refTarget))"/>
        <xsl:param name="stroke" select="$colors?main"/>
        <xsl:param name="label" select="es:printQName($elementName, $schema-context)"/>
        <xsl:param name="text-style" as="map(*)" select="
                map {
                    'font': 'Arial',
                    'style': 'plain',
                    'size': 11
                }"/>


        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="15"/>
        <xsl:variable name="doku">
            <xsl:apply-templates select="$refTarget/xs:annotation" mode="#current">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$cY"/>
                <xsl:with-param name="color" select="$stroke"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>
        <xsl:variable name="dokuWidth" select="es:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>

        <xsl:variable name="fontSize" select="$text-style?size"/>
        <xsl:variable name="fontStyle" select="($text-style?style, 'normal')[. != 'plain'][1]"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="width" select="es:renderedTextLength($label, $text-style)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>


        <svg width="{$width}" height="30" class="element_ref" es:cY="{$cY}" es:displayW="{$dokuWidth}" es:displayH="{max(($dokuHeight - 30, 0))}" es:multiValue="{$multiValue}">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="33.5"/>
            </xsl:if>
            <xsl:attribute name="es:minOccurs" select="1"/>
            <xsl:attribute name="es:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs | @maxOccurs" mode="#current"/>
            <desc/>
            <g alignment-baseline="baseline" class="svg-element-ref" transform="translate(0, 2.5)">
                <g id="{$hoverId}">
                    <!--                    
                        TODO
                        <xsl:variable name="isDoku" select="root($refElement) = $dokuSchema" as="xs:boolean"/>
                    -->
                    <xsl:variable name="rect">
                        <rect height="25" width="{$width}" rx="10" ry="10" stroke="{$stroke}" stoke-width="1" fill="white">
                            <xsl:if test="$multiValue = ($MultiValues[1], $MultiValues[3])">
                                <xsl:attribute name="stroke-dashoffset" select="2"/>
                                <xsl:attribute name="stroke-dasharray" select="2"/>
                            </xsl:if>
                            <!--
                                TODO    
                                <xsl:if test="$isDoku">
                                <set attributeName="fill" to="#88f" begin="{$hoverId}.mouseover" end="{$hoverId}.mouseout"/>
                            </xsl:if>
                            -->
                        </rect>
                    </xsl:variable>
                    <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                        <rect>
                            <xsl:copy-of select="$rect/svg:rect/@*"/>
                            <xsl:attribute name="y" select="3.5"/>
                            <xsl:attribute name="stroke-width" select="0.33"/>
                        </rect>
                        <rect>
                            <xsl:copy-of select="$rect/svg:rect/@*"/>
                            <xsl:attribute name="y" select="2"/>
                            <xsl:attribute name="stroke-width" select="0.66"/>
                        </rect>
                    </xsl:if>
                    <xsl:copy-of select="$rect"/>
                    <xsl:choose>
                        <xsl:when test="false()">
                            <!--                       TODO <xsl:when test="$isDoku">-->
                            <a xlink:href="#{es:convertId($elementName)}" target="_top">
                                <text x="{$paddingLR}" y="16" fill="black" font-family="{$text-style?font}, helvetica, sans-serif" font-size="{$fontSize}" font-style="{$fontStyle}">
                                    <set attributeName="fill" to="#fff" begin="{$hoverId}.mouseover" end="{$hoverId}.mouseout"/>
                                    <xsl:value-of select="$label"/>
                                </text>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <text x="{$paddingLR}" y="16" fill="black" font-family="{$text-style?font}, helvetica, sans-serif" font-size="{$fontSize}" font-style="{$fontStyle}">
                                <xsl:value-of select="$label"/>
                            </text>
                        </xsl:otherwise>
                    </xsl:choose>
                </g>
            </g>
            <g transform="translate({$width}, 0)" es:z-index="0">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@ref] | xs:attributeGroup[@ref]" mode="es:xsd2svg-content">
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>
        <xsl:variable name="groupName" select="es:getName(.)"/>
        <xsl:variable name="namespace" select="namespace-uri-from-QName($groupName)"/>
        <xsl:variable name="mode" select="local-name()"/>
        <xsl:variable name="refGroup" select="es:getReference(@ref, $schema-context)" as="node()"/>

        <xsl:apply-templates select="$refGroup" mode="#current">
            <xsl:with-param name="id" select="generate-id()"/>
            <xsl:with-param name="multiValue" select="es:getMultiValue(.)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" mode="es:xsd2svg-content">
        <xsl:param name="multiValue"/>
        <xsl:call-template name="namedGroup">
            <xsl:with-param name="isRoot" select="false()"/>
            <xsl:with-param name="multiValue" select="$multiValue"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:complexType" mode="es:xsd2svg-content">
        <xsl:variable name="content">
            <xsl:call-template name="createAttributeBox"/>
            <xsl:apply-templates select="xs:* except (xs:attribute | xs:attributeGroup)" mode="#current"/>
        </xsl:variable>
        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="xs:complexContent/xs:extension | xs:simpleContent/xs:extension | xs:simpleContent/xs:restriction | xs:simpleType/xs:restriction" mode="es:xsd2svg-content">
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:variable name="baseName" select="es:getQName(@base)"/>
        <xsl:variable name="baseNs" select="namespace-uri-from-QName($baseName)"/>

        <xsl:variable name="ref" select="es:getReference(@base, $schema-context)"/>
        <xsl:variable name="colorType" select="
                if (parent::xs:complexContent) then
                    'complexType'
                else
                    'simpleType'"/>
        <xsl:variable name="colors" select="$colorScheme($colorType)"/>

        <xsl:variable name="baseIsXSD" select="$baseNs = $XSDNS"/>
        <xsl:variable name="boxTitle" select="
                (
                'Base: ',
                es:printQName(es:getQName(@base), $schema-context)[not($baseIsXSD)]
                ) => string-join()
                "/>

        <xsl:variable name="elementSymbol">
            <xsl:choose>
                <xsl:when test="self::xs:restriction">
                    <xsl:call-template name="restrictionSymbol">
                        <xsl:with-param name="colors" select="$colors"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="extensionSymbol">
                        <xsl:with-param name="colors" select="$colors"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="content">
            <xsl:call-template name="createContentBox">
                <xsl:with-param name="content">
                    <xsl:choose>
                        <xsl:when test="$baseIsXSD">
                            <xsl:call-template name="xsdSimpleTypeRef">
                                <xsl:with-param name="typeName" select="$baseName"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="$ref/*" mode="#current"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="colors" select="$colors => map:put('secondary', 'none') => map:put('text', 'black')"/>
                <xsl:with-param name="title" select="$boxTitle"/>
                <xsl:with-param name="titleSymbol" select="$elementSymbol//*[@class = 'core'][1]" as="node()"/>
            </xsl:call-template>

            <xsl:choose>
                <xsl:when test="self::xs:restriction">
                    <xsl:next-match/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="createAttributeBox"/>
                    <xsl:apply-templates select="xs:* except (xs:attribute | xs:attributeGroup)" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>


        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="x1" select="3"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="strokeColor" select="$colors?main"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementSVG" select="$elementSymbol/svg:svg"/>
        <xsl:variable name="elementHeight" select="sum($elementSVG/@height)"/>
        <xsl:variable name="elementWidth" select="max($elementSVG/@width)"/>


        <xsl:variable name="posY" select="max(($contentSVGs/@es:cY - es:number($elementSVG/@es:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="
                (if ($contentSVGs/@width) then
                    (max($contentSVGs/@width))
                else
                    (0)) + $elementWidth"/>

        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" es:cY="{max(($contentSVGs/@es:cY, es:number($elementSVG/@es:cY, xs:decimal($elementHeight div 2))))}">
            <xsl:attribute name="es:minOccurs" select="1"/>
            <xsl:attribute name="es:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs | @maxOccurs" mode="#current"/>

            <g transform="translate(0,{$posY})">
                <xsl:copy-of select="$elementSVG"/>
            </g>
            <g transform="translate({$elementWidth},0)">
                <xsl:copy-of select="$contentSVGs"/>
            </g>
        </svg>

    </xsl:template>

    <xsl:template match="xs:sequence" mode="es:xsd2svg-content">

        <xsl:variable name="colors" select="$colorScheme('#default')"/>

        <xsl:variable name="multiValue" select="es:getMultiValue(.)"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="contentNet">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="x1" select="3"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="strokeColor" select="$colors?main"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="elementSymbol">
            <xsl:call-template name="sequenceSymbol">
                <xsl:with-param name="multiValue" select="$multiValue"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="contentSVGs" select="$contentNet/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementSVG" select="$elementSymbol/svg:svg"/>
        <xsl:variable name="elementHeight" select="sum($elementSVG/@height)"/>
        <xsl:variable name="elementWidth" select="max($elementSVG/@width)"/>


        <xsl:variable name="posY" select="max(($contentSVGs/@es:cY - es:number($elementSVG/@es:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="
                (if ($contentSVGs/@width) then
                    (max($contentSVGs/@width))
                else
                    (0)) + $elementWidth"/>

        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" es:cY="{max(($contentSVGs/@es:cY, es:number($elementSVG/@es:cY, xs:decimal($elementHeight div 2))))}" es:multiValue="{$multiValue}">
            <xsl:attribute name="es:minOccurs" select="1"/>
            <xsl:attribute name="es:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs | @maxOccurs" mode="#current"/>

            <g transform="translate(0,{$posY})">
                <xsl:copy-of select="$elementSVG"/>
            </g>
            <g transform="translate({$elementWidth},0)">
                <xsl:copy-of select="$contentSVGs"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:choice" name="choice" mode="es:xsd2svg-content" priority="10">
        <xsl:param name="colors" select="$colorScheme('#default')"/>
        <xsl:param name="content">
            <xsl:apply-templates select="xs:*" mode="#current"/>
        </xsl:param>
        <xsl:param name="overwriteSymbol"/>

        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentCount" select="count($content)"/>
        <xsl:variable name="contentMod" select="$contentCount mod 3"/>
        <xsl:variable name="contentTopBotCount" select="
                xs:integer(floor($contentCount div 3) + (if ($contentMod = 2) then
                    (1)
                else
                    (0)))" as="xs:integer"/>

        <xsl:variable name="contentTop" select="$content[position() le $contentTopBotCount]"/>
        <xsl:variable name="contentBottom" select="$content[position() gt (last() - $contentTopBotCount)]"/>
        <xsl:variable name="contentRight" select="$content except ($contentTop, $contentBottom)"/>
        <xsl:variable name="contentTop">
            <xsl:copy-of select="$contentTop"/>
        </xsl:variable>
        <xsl:variable name="contentRight">
            <xsl:copy-of select="$contentRight"/>
        </xsl:variable>
        <xsl:variable name="contentBottom">
            <xsl:copy-of select="$contentBottom"/>
        </xsl:variable>
        <xsl:variable name="contentNet">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="strokeColor" select="$colors?main"/>
                <xsl:with-param name="content" select="$contentTop/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="
                        if ($contentCount gt 3) then
                            (30)
                        else
                            (15)"/>
            </xsl:call-template>
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="strokeColor" select="$colors?main"/>
                <xsl:with-param name="content" select="$contentRight/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="
                        if ($contentCount gt 3) then
                            (30)
                        else
                            (15)"/>
            </xsl:call-template>
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="strokeColor" select="$colors?main"/>
                <xsl:with-param name="content" select="$contentBottom/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="
                        if ($contentCount gt 3) then
                            (30)
                        else
                            (15)"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="multiValue" select="es:getMultiValue(.)"/>
        <xsl:variable name="elementSymbol">
            <xsl:choose>
                <xsl:when test="$overwriteSymbol">
                    <xsl:sequence select="$overwriteSymbol"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="choiceSymbol">
                        <xsl:with-param name="colors" select="$colors"/>
                        <xsl:with-param name="multiValue" select="$multiValue"/>
                        <xsl:with-param name="connectCount" select="
                                if ($contentCount ge 3) then
                                    (3)
                                else
                                    ($contentCount)"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="contentSVGs" select="$contentNet/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementSVG" select="$elementSymbol/svg:svg"/>
        <xsl:variable name="elementHeight" select="sum($elementSVG/@height)"/>
        <xsl:variable name="elementWidth" select="max($elementSVG/@width)"/>

        <xsl:variable name="countContent" select="count($contentSVGs)"/>
        <xsl:variable name="contentCY" select="
                if ($countContent = 2)
                then
                    (
                    ($contentSVGs[2]/@es:cY + $contentSVGs[1]/@height + $contentSVGs[1]/@es:cY
                    ) div 2
                    )
                else
                    if ($countContent = 1)
                    then
                        ($contentSVGs[1]/@es:cY)
                    else
                        ($contentSVGs[2]/@es:cY + $contentSVGs[1]/@height)"/>

        <xsl:variable name="posY" select="max(($contentCY - es:number($elementSVG/@es:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="
                (if ($contentSVGs/@width) then
                    (max($contentSVGs/@width))
                else
                    (0)) + $elementWidth"/>
        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" es:cY="{max(($contentCY, es:number($elementSVG/@es:cY, xs:decimal($elementHeight div 2))))}" es:multiValue="{$multiValue}">
            <g transform="translate(0,{$posY})">
                <xsl:copy-of select="$elementSVG"/>
            </g>
            <xsl:for-each select="reverse($contentSVGs)">
                <xsl:variable name="pos" select="position()"/>
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height)"/>
                <g transform="translate({$elementWidth},{$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>
            <xsl:if test="$countContent gt 1">
                <path fill="none" stroke-width="1" stroke="{$colors?main}">
                    <xsl:variable name="ctop" select="$elementSVG/@es:cXTop, $elementSVG/@es:cYTop"/>
                    <xsl:attribute name="d" select="
                            ('M', $ctop[1], $posY + $ctop[2],
                            'L', $ctop[1], $contentSVGs[1]/@es:cY + 7,
                            'Q', $ctop[1], $contentSVGs[1]/@es:cY, $ctop[1] + 7, $contentSVGs[1]/@es:cY,
                            'L', $elementWidth, $contentSVGs[1]/@es:cY)"/>
                </path>
                <path fill="none" stroke-width="1" stroke="{$colors?main}">
                    <xsl:variable name="cbot" select="$elementSVG/@es:cXBottom, $elementSVG/@es:cYBottom"/>
                    <xsl:variable name="lastCY" select="sum($contentSVGs[position() != last()]/@height) + $contentSVGs[last()]/@es:cY"/>
                    <xsl:attribute name="d" select="
                            ('M', $cbot[1], $posY + $cbot[2],
                            'L', $cbot[1], $lastCY - 7,
                            'Q', $cbot[1], $lastCY, $cbot[1] + 7, $lastCY,
                            'L', $elementWidth, $lastCY)"/>
                </path>
            </xsl:if>
        </svg>

    </xsl:template>

    <xsl:template match="xs:element/xs:simpleType" mode="es:xsd2svg-content">
        <xsl:apply-templates select="xs:*" mode="#current">
            <xsl:with-param name="st-table-title" select="'Simple Type Facets'" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xs:restriction" mode="es:xsd2svg-content">
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>
        <xsl:param name="st-table-title" as="xs:string?" tunnel="yes"/>

        <xsl:variable name="labels" select="map{
            'length' : 'Length',
            'pattern' : 'Pattern',
            'maxLength' : 'Maximal Length',
            'minLength' : 'Minimal Length',
            'whiteSpace' : 'Whitespace',
            'fractionDigits' : 'Fractional Digits',
            'totalDigits' : 'Total Digits',
            'maxExclusive' : 'Maximal Value (Exclusive)',
            'maxInclusive' : 'Maximal Value (Inclusive)',
            'minInclusive' : 'Minimal Value (Inclusive)',
            'minExclusive' : 'Minimal Value (Exclusive)'
            }"/>
        <xsl:variable name="colors" select="$colorScheme('simpleType')"/>
        <xsl:variable name="textStyle" select="
                map {
                    'font': 'Arial',
                    'style': 'plain',
                    'size': 10
                }
                "/>

        <xsl:variable name="enumValues" select="xs:enumeration/@value => es:cut-join(' | ', '...', 100.0, $textStyle)"/>

        <xsl:variable name="table" as="array(xs:string)*">
            <xsl:sequence select="['Type:', 'Restriction']"/>
            <xsl:sequence select="['Base:', es:printQName(es:getQName(@base), $schema-context)]"/>
            <xsl:sequence select="(['Values:', $enumValues])[exists(.?2)]"/>
            <xsl:for-each select="* except xs:enumeration">
                <xsl:sequence select="[$labels(local-name()), @value/string()]"/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="es:create-table(array {$table}, 10, $colors, $st-table-title)"/>
            <xsl:with-param name="strokeColor" select="$colors?main"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:any" mode="es:xsd2svg-content">
        <xsl:param name="model-id" tunnel="yes"/>

        <xsl:variable name="colors" select="$colorScheme(local-name(.))"/>

        <xsl:variable name="ns" select="(@namespace, '##any')[1]"/>
        <xsl:variable name="tns" select="root(.)/xs:schema/@targetNamespace"/>
        <xsl:variable name="labels" select="
                map {
                    '##any': 'Any of *',
                    '##local': 'Any of Q{}*',
                    '##targetNamespace': 'Any of Q{' || $tns || '}*',
                    '##other': 'Any other than Q{' || $tns || '}*'
                }
                "/>
        <xsl:variable name="label" select="
                if (starts-with($ns, '##')) then
                    ($labels($ns))
                else
                    ('Any of Q{' || @namespace || '}*')"/>

        <xsl:call-template name="elementRef">
            <xsl:with-param name="elementName" select="QName($XSDNS, 'any')"/>
            <xsl:with-param name="label" select="$label"/>
            <xsl:with-param name="model-id" select="$model-id" tunnel="yes"/>
            <xsl:with-param name="refAttribute" select="@namespace"/>
            <xsl:with-param name="colors" select="$colors"/>
            <xsl:with-param name="text-style" as="map(*)" select="
                    map {
                        'font': 'Arial',
                        'style': 'italic',
                        'size': 11
                    }"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:function name="es:create-table">
        <xsl:param name="cells" as="array(array(xs:string?))"/>
        <xsl:param name="cell-padding" as="xs:double"/>
        <xsl:param name="colors" as="map(xs:string, xs:string)"/>
        <xsl:sequence select="es:create-table($cells, $cell-padding, $colors, ())"/>
    </xsl:function>

    <xsl:function name="es:create-table">
        <xsl:param name="cells" as="array(array(xs:string?))"/>
        <xsl:param name="cell-padding" as="xs:double"/>
        <xsl:param name="colors" as="map(xs:string, xs:string)"/>
        <xsl:param name="title" as="xs:string?"/>

        <xsl:variable name="lineheight" select="14"/>
        <xsl:variable name="fontSize" select="10"/>
        <xsl:variable name="stroke-width" select="0.5"/>
        <xsl:variable name="stroke-color" select="$colors?main"/>
        <xsl:variable name="title-bg" select="$colors?secondary"/>


        <xsl:variable name="stroke" as="attribute()*">
            <xsl:attribute name="stroke-width" select="$stroke-width"/>
            <xsl:attribute name="stroke" select="$stroke-color"/>
        </xsl:variable>

        <xsl:variable name="text-lengths" select="array {$cells?* ! array {.?* ! es:renderedTextLength(., 'Arial', 'plain', $fontSize)}}"/>
        <xsl:variable name="cols" select="$cells?* ! array:size(.) => max()"/>

        <xsl:variable name="cell-padding2" select="$cell-padding * 2"/>

        <xsl:variable name="titleWidth" select="es:renderedTextLength(($title, '')[1], 'Arial', 'plain', $fontSize) + $cell-padding2"/>


        <xsl:variable name="colWidths" select="
                for $c in (1 to $cols)
                return
                    ($text-lengths?* ! (.($c) + $cell-padding2)) => max()"/>

        <xsl:variable name="tableWidth" select="sum($colWidths)"/>
        <xsl:variable name="tableWidthAdd" select="(0, $titleWidth - $tableWidth) => max()"/>

        <xsl:variable name="tableWidth" select="$tableWidth + $tableWidthAdd"/>
        <xsl:variable name="colWidths" select="$colWidths[position() lt last()], $colWidths[last()] + $tableWidthAdd"/>

        <xsl:variable name="titleHeight" select="
                if ($title) then
                    ($lineheight + $cell-padding)
                else
                    (0)"/>
        <xsl:variable name="tableHeight" select="array:size($cells) * ($lineheight + $cell-padding) + $titleHeight"/>

        <xsl:variable name="title-svg" as="element(svg:g)?">
            <xsl:if test="$title">
                <g>
                    <rect width="{$tableWidth}" height="{$titleHeight}" x="0" y="0" fill="{$title-bg}" ry="7.5" rx="7.5"/>
                    <rect width="{$tableWidth}" height="{$titleHeight - 7.5}" x="0" y="7.5" fill="{$title-bg}"/>
                    <text x="{$cell-padding}" y="{$titleHeight - 7.5}" fill="{$colors?text}" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                        <xsl:value-of select="$title"/>
                    </text>
                    <line x1="0" x2="{$tableWidth}" y1="{$titleHeight}" y2="{$titleHeight}">
                        <xsl:sequence select="$stroke"/>
                    </line>
                </g>
            </xsl:if>
        </xsl:variable>

        <svg width="{$tableWidth + 1}" height="{$tableHeight}" es:cY="{$tableHeight div 2}" es:displayW="{$tableWidth}" es:displayH="{$tableHeight}">
            <xsl:sequence select="$title-svg"/>
            <g>
                <rect width="{$tableWidth}" height="{$tableHeight}" rx="7.5" ry="7.5" stroke="{$stroke-color}" stoke-width="1" fill="none"/>
            </g>
            <xsl:for-each select="$cells?*">
                <xsl:variable name="rownr" select="position()"/>
                <xsl:variable name="rowPosY" select="($lineheight + $cell-padding) * $rownr - $cell-padding + $titleHeight"/>
                <xsl:variable name="lineY" select="$rowPosY + $cell-padding"/>

                <g alignment-baseline="baseline" transform="translate(0, {$rowPosY})">

                    <xsl:for-each select="$cells($rownr)?*">
                        <xsl:variable name="colnr" select="position()"/>

                        <xsl:variable name="x" select="sum($colWidths[position() lt $colnr])"/>

                        <text x="{$x + $cell-padding}" y="0" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                            <xsl:value-of select="."/>
                        </text>

                        <xsl:if test="position() gt 1">
                            <g>
                                <line x1="{$x}" x2="{$x}" y1="{$cell-padding}" y2="{$lineheight * -1}">
                                    <xsl:sequence select="$stroke"/>
                                </line>
                            </g>
                        </xsl:if>
                    </xsl:for-each>

                </g>

                <xsl:if test="position() lt last()">
                    <g>
                        <line x1="0" x2="{$tableWidth}" y1="{$lineY}" y2="{$lineY}">
                            <xsl:sequence select="$stroke"/>
                        </line>
                    </g>
                </xsl:if>
            </xsl:for-each>

        </svg>


    </xsl:function>

    <xsl:function name="es:cut-join">
        <xsl:param name="values" as="xs:string*"/>
        <xsl:param name="sep" as="xs:string"/>
        <xsl:param name="endvalue" as="xs:string"/>
        <xsl:param name="cutvalue" as="xs:double"/>
        <xsl:param name="textStyle" as="map(*)"/>

        <xsl:sequence select="
                fold-left($values, (), function ($oldValue, $v) {
                    let $newVal := string-join(($oldValue, $v), $sep)
                    return
                        if (ends-with($oldValue, $endvalue))
                        then
                            $oldValue
                        else
                            if (es:renderedTextLength($newVal || $endvalue, $textStyle) ge $cutvalue)
                            then
                                $oldValue || $endvalue
                            else
                                $newVal
                })
                "/>
    </xsl:function>



    <xsl:template match="xs:annotation[xs:documentation]" mode="es:xsd2svg-content">
        <xsl:param name="hover_id" tunnel="yes" select="''"/>
        <xsl:param name="invisible_ids" tunnel="yes" select="()"/>
        <xsl:param name="color" select="$colorScheme('#default')?main"/>
        <xsl:param name="cY" select="15"/>
        <xsl:variable name="textContent" select="string-join(xs:documentation, '')"/>
        <xsl:variable name="textLength" select="es:renderedTextLength($textContent, 'Arial', 'plain', 11)"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:documentation" mode="#current">
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
        <es:docu>
            <svg width="{$contentWidth + 32}" height="{$contentHeight + 17}" class="annotation">
                <g visibility="hidden" style="z-index:1000">
                    <set attributeName="visibility" to="visible" begin="{$hover_id}.mouseover" end="{$hover_id}.mouseout" es:dokuViewer="{$hover_id}"/>
                    <xsl:for-each select="$invisible_ids">
                        <set attributeName="visibility" to="hidden" begin="{.}.mouseover" end="{.}.mouseout"/>
                    </xsl:for-each>
                    <g transform="translate(1,1)">
                        <xsl:variable name="curve" select="min((10, $cY - 5))"/>
                        <path d="{es:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="white" opacity="1" stroke="{$color}" stroke-width="1"/>
                        <path d="{es:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="{$color}" opacity="0.1" stroke="{$color}" stroke-width="1"/>
                        <path d="{es:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="none" opacity="1" stroke="{$color}" stroke-width="1"/>
                        <xsl:for-each select="$content">
                            <xsl:variable name="precHeight" select="sum(preceding-sibling::*/@height)"/>
                            <g transform="translate(20,{$precHeight + 5})">
                                <xsl:copy-of select="."/>
                            </g>
                        </xsl:for-each>
                    </g>

                </g>
            </svg>
        </es:docu>
    </xsl:template>

    <xsl:template match="xs:documentation" mode="es:xsd2svg-content">
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
            <xsl:copy-of select="$title"/>
        </xsl:if>

        <xsl:variable name="wrap">
            <xsl:call-template name="wrap">
                <xsl:with-param name="text" select="."/>
                <xsl:with-param name="fontSize" select="$fontSize"/>
                <xsl:with-param name="font" select="'Arial'"/>
                <xsl:with-param name="width" select="$text-width"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$wrap"/>
    </xsl:template>

    <xsl:template match="@maxOccurs | @minOccurs" mode="es:xsd2svg-content"/>



    <xsl:template match="@*" mode="es:xsd2svg-content">
        <xsl:sequence select="error(xs:QName('es:not-supported-element'), 'The attribute ' || name() || ' is not supported.')"/>
    </xsl:template>

    <xsl:template match="*" mode="es:xsd2svg">
        <xsl:sequence select="error(xs:QName('es:not-supported-element'), 'The element ' || name() || ' can not be converted to an SVG model.')"/>
    </xsl:template>

    <xsl:template match="*" mode="es:xsd2svg-parent">
        <xsl:sequence select="error(xs:QName('es:not-supported-parent'), 'The element ' || name() || ' is not be as an parent XSD node.')"/>
    </xsl:template>

<!--
    Parents
    -->

    <xsl:template match="xs:element[@name]" mode="es:xsd2svg-parent">
        <xsl:param name="childId"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>


        <xsl:variable name="colors" select="$colorScheme('#default')"/>

        <xsl:variable name="parentName" select="es:getName(.)"/>
        <xsl:variable name="hoverId" select="concat($model-id, '_', generate-id(), '_parentOf_', $childId)"/>

        <xsl:variable name="stroke" select="$colors?main"/>

        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="12.5"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>

        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="label" select="es:printQName($parentName, $schema-context)"/>
        <xsl:variable name="width" select="es:renderedTextLength($label, 'Arial', 'plain', $fontSize)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
        <svg width="{$width}" height="30" es:cY="15">
            <g alignment-baseline="baseline" id="{$hoverId}" transform="translate( 0, 2.5)">
                <!-- TODO               <a xlink:href="#{es:convertId($parentName)}" target="_top">-->
                <g>
                    <rect width="{$width}" height="25" rx="10" ry="10" stroke="{$stroke}" stoke-width="1" fill="white"/>
                </g>
                <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$label"/>
                </text>
                <!--</a>-->
            </g>
            <g transform="translate({$width}, 2.5)">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" mode="es:xsd2svg-parent">
        <xsl:param name="childId"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:variable name="colors" select="$colorScheme('#default')"/>

        <xsl:variable name="color" select="$colors?main"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_', generate-id(), '_parentOf_', $childId)"/>
        <xsl:variable name="groupName" select="es:getName(.)"/>

        <xsl:variable name="header">
            <xsl:call-template name="groupTitle">
                <xsl:with-param name="title" select="es:printQName($groupName, $schema-context)"/>
                <xsl:with-param name="color" select="$color"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="header" select="$header/svg:svg"/>
        <xsl:variable name="width" select="$header/@width"/>
        <xsl:variable name="height" select="$header/@height"/>

        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="es:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$height div 2"/>
                <xsl:with-param name="color" select="$color"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/es:docu/svg:svg"/>

        <svg width="{$width}" height="{$height + 5}" es:cY="{($height div 2) + 2.5}" es:stroke="{$color}">
            <g transform="translate(1,1)" id="{$hoverId}">
                <!--    TODO            <a xlink:href="#{es:convertId($groupName)}" target="_top">-->
                <path stroke="{$color}" stoke-width="1" fill="white">
                    <xsl:attribute name="d" select="
                            'M', 0, $height + 3,
                            'L', 0, 10,
                            'Q', 0, 0, 10, 0,
                            'L', $width - 12, 0,
                            'Q', $width - 2, 0, $width - 2, 10,
                            'L', $width - 2, $height + 3"/>
                </path>
                <path d="M 2.5 {$height + 2} L {$width - 4.5} {$height + 2}" fill="none" stroke="{$color}" stroke-width="0.25"/>
                <g transform="translate(0, 2.5)">
                    <xsl:copy-of select="$header"/>
                </g>
                <!--</a>-->
            </g>
            <g transform="translate({$width}, 2.5)">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template name="createAttributeBox">

        <xsl:call-template name="createContentBox">
            <xsl:with-param name="colors" select="$colorScheme('attribute')"/>
            <xsl:with-param name="content">
                <xsl:apply-templates select="xs:attribute | xs:attributeGroup" mode="es:xsd2svg-content"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="createContentBox">
        <xsl:param name="content" required="yes"/>
        <xsl:param name="colors" select="$colorScheme('#default')"/>
        <xsl:param name="title" select="()" as="xs:string?"/>
        <xsl:param name="titleSymbol" as="node()?"/>

        <xsl:variable name="strokeColor" select="$colors?main"/>
        <xsl:variable name="titleBgColor" select="$colors?secondary"/>
        <xsl:variable name="titleColor" select="$colors?text"/>


        <xsl:variable name="titleSvg">
            <xsl:if test="$title">
                <xsl:call-template name="boxTitle">
                    <xsl:with-param name="title" select="$title"/>
                    <xsl:with-param name="font-color" select="$titleColor"/>
                    <xsl:with-param name="symbol" select="$titleSymbol"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>

        <xsl:variable name="titleHeight" select="
                ($titleSvg/svg:svg/(@height), 0) => max()"/>

        <xsl:variable name="titleWidth" select="($titleSvg/svg:svg/(@width + 10), 0) => max()"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="strokeColor" select="$strokeColor"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($content/@height) + $titleHeight"/>
        <xsl:variable name="contentWidth" select="max(($content/@width, $titleWidth))"/>


        <xsl:variable name="svgWidth" select="$contentWidth + 2.5"/>
        <xsl:if test="$content">
            <svg width="{$svgWidth}" height="{$contentHeight + 10}" class="attribute_box" es:cY="{$content/@es:cY + 5 + $titleHeight}" es:multiValue="{es:multiValuesMerge($contentSVGs)}" es:stroke="{$strokeColor}">
                <g transform="translate(0, 2.5)">

                    <xsl:if test="$title">
                        <g>
                            <rect height="{$titleHeight}" width="{$svgWidth}" rx="10" ry="10" fill="{$titleBgColor}"/>
                            <rect y="{$titleHeight div 2}" height="{$titleHeight div 2}" width="{$svgWidth}" fill="{$titleBgColor}"/>
                            <xsl:sequence select="$titleSvg"/>
                            <path d="M 2.5 {$titleHeight} L {$svgWidth - 4.5} {$titleHeight}" fill="none" stroke="{$strokeColor}" stroke-width="0.25"/>
                            <!--<text y="{$titleHeight - 5}" x="5" font-family="Arial" font-size="9" fill="{$titleColor}">
                            <xsl:value-of select="$title"/>
                        </text>-->
                        </g>
                    </xsl:if>

                    <rect height="{$contentHeight + 5}" width="{$svgWidth}" rx="10" ry="10" stroke="{$strokeColor}" stoke-width="1" fill="none"/>
                    <g transform="translate(0, {2.5 + $titleHeight})">
                        <xsl:copy-of select="$content"/>
                    </g>
                </g>
            </svg>
        </xsl:if>

    </xsl:template>

    <xsl:template name="makeParentSVGs">
        <xsl:param name="this" select="." as="element()"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>

        <xsl:variable name="parents" select="es:getParents($this, $schema-context)"/>

        <xsl:variable name="parentContent">
            <xsl:apply-templates select="$parents" mode="es:xsd2svg-parent"/>
        </xsl:variable>
        <xsl:variable name="parentConnect">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$parentContent/svg:svg"/>
                <xsl:with-param name="rightPathPosition" select="true()"/>
                <xsl:with-param name="strokeColor" select="$colorScheme(local-name($this))?main"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$parentConnect"/>
    </xsl:template>

    <xsl:template name="xsdSimpleTypeRef">
        <xsl:param name="typeName" select="es:getQName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schema-context" as="map(xs:string, document-node(element(xs:schema))*)" tunnel="yes"/>
        <xsl:param name="colors" select="$colorScheme('simpleType')" as="map(xs:string, xs:string)"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="15"/>


        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="label" select="es:printQName($typeName, $schema-context)"/>
        <xsl:variable name="width" select="es:renderedTextLength($label, 'Arial', 'plain', $fontSize)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>

        <svg width="{$width}" height="30" class="element_ref" es:cY="{$cY}" es:displayW="{$width}" es:displayH="0" es:multiValue="one">
            <xsl:attribute name="es:minOccurs" select="1"/>
            <xsl:attribute name="es:maxOccurs" select="1"/>
            <desc/>
            <g alignment-baseline="baseline" class="svg-element-ref" transform="translate(0, 2.5)">
                <g id="{$hoverId}">
                    <!--                    
                                    TODO
                                    <xsl:variable name="isDoku" select="root($refElement) = $dokuSchema" as="xs:boolean"/>
                                -->
                    <xsl:variable name="rect">
                        <rect height="25" width="{$width}" rx="10" ry="10" stroke="{$colors?main}" stoke-width="1" fill="white"/>
                    </xsl:variable>
                    <xsl:copy-of select="$rect"/>

                    <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                        <xsl:value-of select="$label"/>
                    </text>


                </g>
            </g>
        </svg>

    </xsl:template>




</xsl:stylesheet>
