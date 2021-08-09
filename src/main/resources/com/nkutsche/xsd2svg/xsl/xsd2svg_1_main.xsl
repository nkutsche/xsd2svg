<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:nk="http://www.nkutsche.com/" xmlns:svg="http://www.w3.org/2000/svg" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" exclude-result-prefixes="#all" version="3.0">




    <xsl:mode name="nk:xsd2svg-parent"/>
    <xsl:mode name="nk:xsd2svg-content"/>





    <!--    
    Model main elements
    -->

    <xsl:template match="xs:element[@name] | xs:attribute[@name]" mode="nk:xsd2svg" priority="10">
        <xsl:param name="elementName" select="nk:getName(.)" as="xs:QName"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>

        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object main cs_' || $color-scheme"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:* | @type" mode="nk:xsd2svg-content">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:variable name="symbol">
            <xsl:if test="self::xs:attribute">
                <xsl:call-template name="attributeSymbol">
                    <xsl:with-param name="bold" select="true()"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>

        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs"/>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>

        <xsl:variable name="symbolWidth" select="nk:number($symbol/svg:svg/@width)"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>

        <xsl:variable name="maxCY" select="max(($contentSVGs/@nk:cY, $elementHeight div 2, $parents/@nk:cY))"/>

        <xsl:variable name="parentPosY" select="nk:number($maxCY - $parents/@nk:cY)"/>
        <xsl:variable name="elementPosY" select="nk:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="nk:number($maxCY - $contentSVGs/@nk:cY)"/>

        <xsl:variable name="posY" select="max(($contentSVGs/@nk:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>

        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{nk:convertId(string($elementName))}" nk:cY="{$contentSVGs/@nk:cY}">
            <desc/>


            <xsl:variable name="fontSize" select="11"/>
            
            <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, true())"/>
            <xsl:variable name="width" select="nk:renderedTextLength(nk:printQName($elementName, $schemaSetConfig), $fontInfo)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR) + $symbolWidth"/>
            <xsl:variable name="parentWidth" select="nk:number(max($parents/@width))"/>

            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <svg width="{$width + 1}" height="26">
                    <g transform="translate(0.5, 0.5)">
                        <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} filled" stroke-width="1"/>
                        <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} bordered" stroke-width="1"/>
                        <g transform="translate({$paddingLR div 2}, {$paddingLR div 2})">
                            <xsl:sequence select="$symbol"/>
                        </g>

                        <text x="{$paddingLR + $symbolWidth}" y="16" class="{$class} backgrounded">
                            <xsl:sequence select="$fontInfo?svg-attributes"/>
                            <xsl:value-of select="$elementName"/>
                        </text>
                    </g>
                    <xsl:sequence select="nk:createDoku(.)"/>
                </svg>
            </g>
            <xsl:for-each select="$contentSVGs">
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height) + $contentPosY"/>
                <g transform="translate({$width + $parentWidth}, {$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>

            <g transform="translate(0,{$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>

        </svg>
    </xsl:template>

    <xsl:template match="xs:schema/xs:complexType[@name]" mode="nk:xsd2svg" priority="10">
        <xsl:param name="elementName" select="nk:getName(.)" as="xs:QName"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="content-line" select="exists(self::xs:complexType)" as="xs:boolean"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object main cs_' || $color-scheme"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>
        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="." mode="nk:xsd2svg-content"/>
        </xsl:variable>

        <xsl:variable name="symbol">
            <xsl:call-template name="complexTypeSymbol">
                <xsl:with-param name="bold" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="symbolWidth" select="nk:number($symbol/svg:svg/@width/(. + $paddingLR div 2))"/>

        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs"/>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>

        <xsl:variable name="maxCY" select="max(($contentSVGs/@nk:cY, $elementHeight div 2, $parents/@nk:cY))"/>

        <xsl:variable name="parentPosY" select="nk:number($maxCY - $parents/@nk:cY)"/>
        <xsl:variable name="elementPosY" select="nk:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="nk:number($maxCY - $contentSVGs/@nk:cY)"/>

        <xsl:variable name="posY" select="max(($contentSVGs/@nk:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>

        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{nk:convertId(string($elementName))}" nk:cY="{$contentSVGs/@nk:cY}">
            <desc/>
            <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, true())"/>
            <xsl:variable name="width" select="nk:renderedTextLength(nk:printQName($elementName, $schemaSetConfig), $fontInfo)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR) + $symbolWidth"/>
            <xsl:variable name="parentWidth" select="nk:number(max($parents/@width))"/>

            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <svg width="{$width + 1}" height="26">
                    <g transform="translate(0.5, 0.5)">
                        <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} filled" stoke-width="1"/>
                        <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} bordered" stoke-width="1"/>
                    </g>
                    <g transform="translate({$paddingLR}, {$paddingLR div 2})">
                        <xsl:sequence select="$symbol"/>
                    </g>
                    <text x="{$paddingLR + $symbolWidth}" y="16" class="{$class} backgrounded">
                        <xsl:sequence select="$fontInfo?svg-attributes"/>
                        <xsl:value-of select="$elementName"/>
                    </text>
                    <xsl:sequence select="nk:createDoku(.)"/>
                </svg>
            </g>
            <xsl:for-each select="$contentSVGs">
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height) + $contentPosY"/>
                <g transform="translate({$width + $parentWidth}, {$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>

            <g transform="translate(0,{$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>

        </svg>
    </xsl:template>

    <xsl:template match="xs:simpleType[@name]" mode="nk:xsd2svg">
        <xsl:param name="typeName" select="nk:getName(.)" as="xs:QName"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object main cs_' || $color-scheme"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>
        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" as="element(svg:svg)?">
                    <xsl:apply-templates select="xs:*" mode="nk:xsd2svg-content">
                        <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                        <xsl:with-param name="cY" select="$cY"/>
                    </xsl:apply-templates>
                </xsl:with-param>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>


        <xsl:variable name="symbol">
            <xsl:call-template name="simpleTypeSymbol">
                <xsl:with-param name="bold" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="symbolWidth" select="nk:number($symbol/svg:svg/@width/(. + $paddingLR div 2))"/>

        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs"/>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>

        <xsl:variable name="maxCY" select="max(($contentSVGs/@nk:cY, $elementHeight div 2, $parents/@nk:cY))"/>

        <xsl:variable name="parentPosY" select="nk:number($maxCY - $parents/@nk:cY)"/>
        <xsl:variable name="elementPosY" select="nk:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="nk:number($maxCY - $contentSVGs/@nk:cY)"/>

        <xsl:variable name="posY" select="max(($contentSVGs/@nk:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>

        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{nk:convertId(string($typeName))}" nk:cY="{$contentSVGs/@nk:cY}">
            <desc/>
            <xsl:variable name="label" select="nk:printQName($typeName, $schemaSetConfig)"/>
            <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, true())"/>
            <xsl:variable name="width" select="nk:renderedTextLength($label, $fontInfo)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR) + $symbolWidth"/>
            <xsl:variable name="parentWidth" select="nk:number(max($parents/@width))"/>

            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <svg width="{$width + 1}" height="26">
                    <g transform="translate(0.5, 0.5)">
                        <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} filled" stoke-width="1"/>
                        <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} bordered" stoke-width="1"/>
                    </g>
                    <g transform="translate({$paddingLR}, {$paddingLR div 2})">
                        <xsl:sequence select="$symbol"/>
                    </g>
                    <text x="{$paddingLR + $symbolWidth}" y="16" class="{$class} backgrounded">
                        <xsl:sequence select="$fontInfo?svg-attributes"/>
                        <xsl:value-of select="$label"/>
                    </text>
                    <xsl:sequence select="nk:createDoku(.)"/>
                </svg>
            </g>

            <xsl:for-each select="$contentSVGs">
                <xsl:variable name="precHeight" select="sum(preceding-sibling::svg:svg/@height) + $contentPosY"/>
                <g transform="translate({$width + $parentWidth}, {$precHeight})">
                    <xsl:copy-of select="."/>
                </g>
            </xsl:for-each>

            <g transform="translate(0,{$parentPosY})">
                <xsl:copy-of select="$parents"/>
            </g>

        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" name="namedGroup" mode="nk:xsd2svg">
        <xsl:param name="id" select="generate-id()"/>
        <xsl:param name="multiValue" select="$MultiValues[2]"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="isRoot" select="true()" as="xs:boolean"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object main cs_' || $color-scheme"/>


        <xsl:variable name="groupName" select="nk:getName(.)"/>
        <xsl:variable name="hoverId" select="concat($model-id, '_group_', $id)"/>
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="nk:xsd2svg-content"/>
        </xsl:variable>
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>

        <xsl:variable name="parents">
            <xsl:if test="$isRoot">
                <xsl:call-template name="makeParentSVGs"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="parentsWidth" select="nk:number($parents/@width)"/>
        <xsl:variable name="parentsHeight" select="nk:number($parents/@height)"/>
        <xsl:variable name="parentsCY" select="nk:number($parents/@nk:cY)"/>

        <xsl:variable name="header">
            <xsl:call-template name="groupTitle">
                <xsl:with-param name="title" select="nk:printQName($groupName, $schemaSetConfig)"/>
                <xsl:with-param name="bold" select="$isRoot" tunnel="yes"/>
                <xsl:with-param name="backgrounded" select="$isRoot" tunnel="yes"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="header" select="$header/svg:svg"/>

        <xsl:variable name="cY" select="$content/@nk:cY + $header/@height + 7.5"/>


        <xsl:variable name="maxCY" select="max(($cY, $parents/@nk:cY))"/>

        <xsl:variable name="parentPosY" select="nk:number($maxCY - $parentsCY)"/>
        <xsl:variable name="groupPosY" select="nk:number($maxCY - $cY)"/>
        <xsl:variable name="groupHeight" select="sum(($content/@height, $header/@height))"/>

        <xsl:variable name="width" select="max(($content/@width, $header/@width))"/>
        <xsl:variable name="height" select="max(($groupHeight, $parentsHeight))"/>


        <svg width="{$width + 8 + $parentsWidth}" height="{$height + 15}" nk:cY="{$cY}" class="element_group" nk:multiValue="{$multiValue}">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="$height + 18.5"/>
            </xsl:if>
            <g transform="translate({$parentsWidth + 0.5}, {$groupPosY + 5})" id="{$hoverId}">

                <xsl:variable name="rect">
                    <rect width="{$width + 2.5}" height="{$groupHeight + 5}" rx="7" ry="7" fill="white" class="{$class} bordered" stroke-width="1">
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
                <xsl:variable name="header-background">
                    <rect width="{$width + 2.5}" height="{$groupHeight + 5}" rx="7" ry="7" class="{$class} bordered opaque link-background" stroke-width="1"/>
                </xsl:variable>
                <xsl:variable name="headerWithBorder">
                    <xsl:choose>
                        <xsl:when test="$isRoot">
                            <xsl:sequence select="$header-background"/>
                            <xsl:sequence select="$header"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="createLink">
                                <xsl:with-param name="content" select="
                                        $header-background,
                                        $header
                                        "/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                    <path d="M 2.5 {$header/@height} L {$width} {$header/@height}" fill="none" class="{$class} bordered" stroke-width="0.25"/>
                </xsl:variable>

                <svg height="{$header/@height}" width="{$width + 2.5}">
                    <xsl:variable name="bg-class" select="
                            if ($isRoot) then
                                ($class || ' filled')
                            else
                                ($class || ' opaque')"/>
                    <path class="{$bg-class}">
                        <xsl:attribute name="d" select="
                                'M', 0, $header/@height,
                                'L', 0, 7,
                                'Q', 0, 0, 7, 0,
                                'L', $width - 4.5, 0,
                                'Q', $width + 2.5, 0, $width + 2.5, 7,
                                'L', $width + 2.5, $header/@height, 'Z'"/>
                    </path>

                    <xsl:copy-of select="$headerWithBorder"/>

                    <xsl:sequence select="nk:createDoku(.)"/>
                </svg>

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
    <xsl:template match="xs:attribute[@name] | xs:element[@name]" mode="nk:xsd2svg-content">
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="multiValue" select="nk:getMultiValue(.)" as="xs:string"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object content cs_' || $color-scheme"/>

        <xsl:variable name="attributName" select="nk:getName(.)"/>
        <xsl:variable name="elementHeight" select="
                if (@type) then
                    40
                else
                    25"/>
        <xsl:variable name="position" select="(0, 2.5)"/>
        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="cY" select="$position[2] + ($elementHeight div 2)"/>

        <xsl:variable name="symbol">
            <xsl:if test="self::xs:attribute">
                <xsl:call-template name="attributeSymbol"/>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="symbolWidth" select="nk:number($symbol/svg:svg/@width)"/>

        <xsl:variable name="type-target" select="@type/nk:getReference(., $schemaSetConfig)"/>
        <xsl:variable name="type-mode" select="($type-target/local-name(), 'simpleType')[1]"/>
        <xsl:variable name="type-class" select="'object content cs_' || $type-mode"/>


        <xsl:variable name="hoverId" select="concat($model-id, '_attributName_', generate-id())"/>

        <xsl:variable name="label" select="nk:printQName($attributName, $schemaSetConfig)"/>
        <xsl:variable name="typeLabel" select="
                if (@type) then
                'Type: ' || nk:printQName(nk:getQName(@type), $schemaSetConfig)
                else
                    ''"/>

        <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, false())"/>
        <xsl:variable name="widths" select="
            nk:renderedTextLength($label, $fontInfo) + $symbolWidth,
            nk:renderedTextLength($typeLabel, $fontInfo)
                "/>


        <xsl:variable name="width" select="$widths => max()"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
        <svg width="{$width}" height="{$elementHeight + 5}" nk:cY="{$cY}" class="attribute" id="{$model-id}_attribute_{nk:convertId($label)}" nk:multiValue="{$multiValue}">
            <desc/>
            <g alignment-baseline="baseline" transform="translate({$position[1]}, {$position[2]})" id="{$hoverId}">
                <svg width="{$width + 1}" height="{$elementHeight + 1}">
                    <g transform="translate(0.5, 0.5)">
                        <xsl:call-template name="createLink">
                            <xsl:with-param name="content">
                                <xsl:choose>
                                    <xsl:when test="@type">
                                        <path d="{nk:createHalfRoundBox($width, $elementHeight div 2, 10, true(), false())}" class="{$class} opaque link-background"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <rect height="{$elementHeight}" width="{$width}" rx="10" ry="10" x="0" y="0" class="{$class} opaque link-background"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                
                                <g transform="translate({$paddingLR div 2}, {$paddingLR div 2})">
                                    <xsl:sequence select="$symbol"/>
                                </g>
                                
                                <text x="{$paddingLR + $symbolWidth}" y="16" class="{$class} link-text">
                                    <xsl:sequence select="$fontInfo?svg-attributes"/>
                                    <xsl:value-of select="$label"/>
                                </text>
                            </xsl:with-param>
                        </xsl:call-template>
                    </g>
                    <xsl:sequence select="nk:createDoku(.)"/>
                </svg>

                <xsl:if test="@type">
                    <svg width="{$width + 1}" height="{($elementHeight) + 1}">
                        <g transform="translate(0.5, 0.5)">
                            <xsl:call-template name="createLink">
                                <xsl:with-param name="content">
                                    <g transform="translate(0,{$elementHeight div 2})">
                                        <path d="{nk:createHalfRoundBox($width, $elementHeight div 2, 10, true())}" class="{$type-class} shaded filled link-background"/>
                                    </g>
                                    <text x="{$paddingLR}" y="32" class="{$type-class} shaded backgrounded link-text">
                                        <xsl:sequence select="$fontInfo?svg-attributes"/>
                                        <xsl:value-of select="$typeLabel"/>
                                    </text>
                                </xsl:with-param>
                                <xsl:with-param name="linkTarget" select="nk:getReference(@type, $schemaSetConfig)"/>
                            </xsl:call-template>
                        </g>
                        <xsl:sequence select="$type-target/nk:createDoku(.)"/>
                    </svg>
                </xsl:if>

                
                <svg width="{$width + 1}" height="{$elementHeight + 1}">
                    <g transform="translate(0.5, 0.5)">
                        <rect height="{$elementHeight}" width="{$width}" rx="10" ry="10" class="{$class} bordered" stoke-width="1" fill="none">
                            <xsl:if test="$multiValue = $MultiValues[1]">
                                <xsl:attribute name="stroke-dasharray" select="5, 5" separator=","/>
                            </xsl:if>
                        </rect>

                    </g>
                </svg>

            </g>

        </svg>
    </xsl:template>

    <xsl:template match="xs:element/@type | xs:attribute/@type" mode="nk:xsd2svg-content">
        <xsl:param name="typeName" select="nk:getQName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>

        <xsl:variable name="namespace" select="namespace-uri-from-QName($typeName)"/>

        <xsl:variable name="isXsd" select="$namespace = $XSDNS"/>

        <xsl:variable name="reference" select="nk:getReference(., $schemaSetConfig)"/>

        <xsl:variable name="kindOfType" select="
                if ($isXsd) then
                    'simpleType'
                else
                    local-name($reference)"/>


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
                        <xsl:with-param name="color-scheme" select="$kindOfType"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:variable>

        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
            <xsl:with-param name="color-scheme" select="$kindOfType"/>
        </xsl:call-template>

    </xsl:template>

    <xsl:template match="xs:element[@ref] | xs:attribute[@ref]" name="elementRef" mode="nk:xsd2svg-content">
        <xsl:param name="elementName" select="nk:getName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="multiValue" select="nk:getMultiValue(.)"/>
        <xsl:param name="refAttribute" select="@ref" as="attribute()?"/>
        <xsl:param name="refTarget" select="$refAttribute/nk:getReference(., $schemaSetConfig)" as="node()?"/>
        <xsl:param name="label" select="nk:printQName($elementName, $schemaSetConfig)"/>
        <xsl:param name="bold" select="false()" as="xs:boolean"/>
        <xsl:param name="fontInfo" as="map(*)" select="nk:create-font-info($schemaSetConfig, 11, false())"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object content cs_' || $color-scheme"/>

        <xsl:variable name="refType" select="
                if ($elementName = QName($XSDNS, 'any')) then
                    ('any')
                else
                    $refTarget/local-name()
                "/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="15"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="symbol" select="$refType ! nk:getSymbol(.)"/>

        <xsl:variable name="symbolWidth" select="nk:number($symbol/@width)"/>

        <xsl:variable name="fontSize" select="$fontInfo?size"/>
        <xsl:variable name="fontStyle" select="($fontInfo?style, 'normal')[. != 'plain'][1]"/>

        <xsl:variable name="width" select="nk:renderedTextLength($label, $fontInfo)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR) + $symbolWidth"/>


        <svg width="{$width}" height="30" class="element_ref" nk:cY="{$cY}" nk:multiValue="{$multiValue}">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="33.5"/>
            </xsl:if>
            <xsl:attribute name="nk:minOccurs" select="1"/>
            <xsl:attribute name="nk:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs | @maxOccurs" mode="#current"/>
            <desc/>
            <g alignment-baseline="baseline" class="svg-element-ref" transform="translate(0, 2.5)">
                <svg width="{$width + 1}" height="29">
                    <g id="{$hoverId}" transform="translate(0.5, 0.5)">
                        <xsl:variable name="rect">
                            <rect height="25" width="{$width}" rx="10" ry="10" class="{$class} bordered opaque link-background" stoke-width="1">
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

                        <xsl:call-template name="createLink">
                            <xsl:with-param name="content">
                                <xsl:copy-of select="$rect"/>

                                <g transform="translate({$paddingLR div 2}, {$paddingLR div 2})">
                                    <xsl:sequence select="$symbol"/>
                                </g>
                                <text x="{$paddingLR + $symbolWidth}" y="16" class="{$class} link-text">
                                    <xsl:sequence select="$fontInfo?svg-attributes"/>
                                    <xsl:value-of select="$label"/>
                                </text>
                            </xsl:with-param>
                            <xsl:with-param name="linkTarget" select="$refTarget"/>
                        </xsl:call-template>

                    </g>
                    <xsl:sequence select="$refTarget/nk:createDoku(.)"/>
                </svg>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@ref] | xs:attributeGroup[@ref]" mode="nk:xsd2svg-content">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>

        <xsl:variable name="groupName" select="nk:getName(.)"/>
        <xsl:variable name="namespace" select="namespace-uri-from-QName($groupName)"/>
        <xsl:variable name="mode" select="local-name()"/>
        <xsl:variable name="refGroup" select="nk:getReference(@ref, $schemaSetConfig)" as="node()"/>

        <xsl:apply-templates select="$refGroup" mode="#current">
            <xsl:with-param name="id" select="generate-id()"/>
            <xsl:with-param name="multiValue" select="nk:getMultiValue(.)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" mode="nk:xsd2svg-content">
        <xsl:param name="multiValue"/>
        <xsl:call-template name="namedGroup">
            <xsl:with-param name="isRoot" select="false()"/>
            <xsl:with-param name="multiValue" select="$multiValue"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:complexType" mode="nk:xsd2svg-content">
        <xsl:variable name="content">
            <xsl:call-template name="createAttributeBox"/>
            <xsl:apply-templates select="xs:* except (xs:attribute | xs:attributeGroup)" mode="#current"/>
        </xsl:variable>
        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
            <xsl:with-param name="color-scheme" select="local-name()"/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="xs:complexContent/xs:extension | xs:simpleContent/xs:extension | xs:simpleContent/xs:restriction | xs:simpleType/xs:restriction" mode="nk:xsd2svg-content">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="
                if (parent::xs:complexContent) then
                    'complexType'
                else
                    'simpleType'
                " as="xs:string"/>

        <xsl:variable name="baseName" select="nk:getQName(@base)"/>
        <xsl:variable name="baseNs" select="namespace-uri-from-QName($baseName)"/>

        <xsl:variable name="ref" select="nk:getReference(@base, $schemaSetConfig)"/>
        <xsl:variable name="colorType" select="
                if (parent::xs:complexContent) then
                    'complexType'
                else
                    'simpleType'"/>

        <xsl:variable name="baseIsXSD" select="$baseNs = $XSDNS"/>
        <xsl:variable name="boxTitle" select="
                (
                'Base: ',
                nk:printQName(nk:getQName(@base), $schemaSetConfig)[not($baseIsXSD)]
                ) => string-join()
                "/>

        <xsl:variable name="elementSymbol">
            <xsl:choose>
                <xsl:when test="self::xs:restriction">
                    <xsl:call-template name="restrictionSymbol">
                        <xsl:with-param name="color-scheme" select="$color-scheme"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="extensionSymbol">
                        <xsl:with-param name="color-scheme" select="$color-scheme"/>
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
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
                <xsl:with-param name="title">
                    <xsl:call-template name="boxTitle">
                        <xsl:with-param name="title" select="$boxTitle"/>
                        <xsl:with-param name="symbol" select="$elementSymbol//*[@class = 'core'][1]"/>
                    </xsl:call-template>
                </xsl:with-param>
                <xsl:with-param name="title-link-target" select="$ref"/>
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



        <xsl:call-template name="createTreeNode">
            <xsl:with-param name="symbol" select="$elementSymbol"/>
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
        </xsl:call-template>

    </xsl:template>

    <xsl:template match="xs:sequence" mode="nk:xsd2svg-content">

        <xsl:variable name="multiValue" select="nk:getMultiValue(.)"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="contentNet">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="x1" select="3"/>
                <xsl:with-param name="x2" select="30"/>
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


        <xsl:variable name="posY" select="max(($contentSVGs/@nk:cY - nk:number($elementSVG/@nk:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="
                (if ($contentSVGs/@width) then
                    (max($contentSVGs/@width))
                else
                    (0)) + $elementWidth"/>

        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" nk:cY="{max(($contentSVGs/@nk:cY, nk:number($elementSVG/@nk:cY, xs:decimal($elementHeight div 2))))}" nk:multiValue="{$multiValue}">
            <xsl:attribute name="nk:minOccurs" select="1"/>
            <xsl:attribute name="nk:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs | @maxOccurs" mode="#current"/>

            <g transform="translate(0,{$posY})">
                <xsl:copy-of select="$elementSVG"/>
            </g>
            <g transform="translate({$elementWidth},0)">
                <xsl:copy-of select="$contentSVGs"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:choice" mode="nk:xsd2svg-content" priority="10">
        <xsl:param name="color-scheme" select="'default'"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="#current"/>
        </xsl:variable>

        <xsl:variable name="multiValue" select="nk:getMultiValue(.)"/>

        <xsl:call-template name="createTreeNode">
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
            <xsl:with-param name="this" select="."/>
            <xsl:with-param name="symbol">
                <xsl:call-template name="choiceSymbol">
                    <xsl:with-param name="multiValue" select="$multiValue"/>
                    <xsl:with-param name="connectCount" select="
                            (count($content/svg:svg), 3) => min()"/>
                    <xsl:with-param name="color-scheme" select="$color-scheme"/>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>


    </xsl:template>


    <xsl:template match="xs:element/xs:simpleType | xs:attribute/xs:simpleType" mode="nk:xsd2svg-content">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="'simpleType'"/>
        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" as="element(svg:svg)">
                <xsl:apply-templates select="xs:*" mode="#current"/>
            </xsl:with-param>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:union" mode="nk:xsd2svg-content" priority="10">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="'simpleType'"/>

        <xsl:variable name="union" select="."/>

        <xsl:variable name="content">
            <xsl:call-template name="createTreeNode">
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
                <xsl:with-param name="content">
                    <xsl:for-each select="@memberTypes/tokenize(., '\s')">
                        <xsl:variable name="qname" select="nk:getQName(., $union)"/>
                        <xsl:variable name="ns" select="namespace-uri-from-QName($qname)"/>
                        <xsl:for-each select="$union">
                            <xsl:choose>
                                <xsl:when test="$ns = $XSDNS">
                                    <xsl:call-template name="xsdSimpleTypeRef">
                                        <xsl:with-param name="typeName" select="$qname"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="elementRef">
                                        <xsl:with-param name="elementName" select="$qname"/>
                                        <xsl:with-param name="refTarget" select="nk:getReferenceByQName($qname, $schemaSetConfig, 'simpleType')"/>
                                        <xsl:with-param name="multiValue" select="'one'"/>
                                        <xsl:with-param name="color-scheme" select="'simpleType'"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:for-each>
                    <xsl:apply-templates select="xs:simpleType" mode="#current"/>
                </xsl:with-param>
                <xsl:with-param name="symbol">
                    <xsl:call-template name="st_unionSymbol">
                        <xsl:with-param name="color-scheme" select="$color-scheme"/>
                    </xsl:call-template>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:list" mode="nk:xsd2svg-content" priority="10">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="'simpleType'"/>

        <xsl:variable name="content">
            <xsl:choose>
                <xsl:when test="@itemType">
                    <xsl:variable name="qname" select="nk:getQName(@itemType)"/>
                    <xsl:variable name="ns" select="namespace-uri-from-QName($qname)"/>
                    <xsl:choose>
                        <xsl:when test="$ns = $XSDNS">
                            <xsl:call-template name="xsdSimpleTypeRef">
                                <xsl:with-param name="typeName" select="$qname"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:call-template name="elementRef">
                                <xsl:with-param name="elementName" select="nk:getQName(@itemType)"/>
                                <xsl:with-param name="refAttribute" select="@itemType"/>
                                <xsl:with-param name="multiValue" select="'one'"/>
                                <xsl:with-param name="color-scheme" select="$color-scheme"/>
                            </xsl:call-template>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="xs:simpleType" mode="#current"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="content">
            <xsl:call-template name="createTreeNode">
                <xsl:with-param name="content" select="$content"/>
                <xsl:with-param name="symbol">
                    <xsl:call-template name="st_listSymbol"/>
                </xsl:with-param>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:list/xs:simpleType | xs:union/xs:simpleType" mode="nk:xsd2svg-content">
        <xsl:param name="color-scheme" select="local-name()"/>
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="content">
            <svg>
                <xsl:sequence select="$content/svg:svg/(@* except @nk:multiValue)"/>
                <xsl:sequence select="$content"/>
            </svg>
        </xsl:variable>
        <xsl:call-template name="createContentBox">
            <xsl:with-param name="content" select="$content"/>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template match="xs:restriction" mode="nk:xsd2svg-content">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="st-table-title" select="'Facets'" as="xs:string?" tunnel="yes"/>
        <xsl:param name="color-scheme" select="'simpleType'"/>

        <xsl:variable name="labels" select="
                map {
                    'length': 'Length',
                    'pattern': 'Pattern',
                    'maxLength': 'Maximal Length',
                    'minLength': 'Minimal Length',
                    'whiteSpace': 'Whitespace',
                    'fractionDigits': 'Fractional Digits',
                    'totalDigits': 'Total Digits',
                    'maxExclusive': 'Maximal Value (Exclusive)',
                    'maxInclusive': 'Maximal Value (Inclusive)',
                    'minInclusive': 'Minimal Value (Inclusive)',
                    'minExclusive': 'Minimal Value (Exclusive)'
                }"/>
        <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, 10, false())"/>

        <xsl:variable name="enumValuesCut" select="xs:enumeration/@value => nk:cut-join(' | ', '...', 100.0, $fontInfo)"/>
        <xsl:variable name="enumValues" select="xs:enumeration/@value => string-join(' | ')"/>
        <xsl:variable name="enumCell" select="
            nk:tcell($enumValuesCut, $enumValues)
                "/>

        <xsl:variable name="table" as="array(map(xs:string, item()?))*">
            <xsl:sequence select="([nk:tcell('Values:'), $enumCell])[exists(.?2)]"/>
            <xsl:for-each select="* except xs:enumeration">
                <xsl:sequence select="[nk:tcell($labels(local-name())), nk:tcell(@value)]"/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:sequence select="nk:create-table($schemaSetConfig, array {$table}, 10, $color-scheme, $st-table-title)"/>
    </xsl:template>

    <xsl:template match="xs:any" mode="nk:xsd2svg-content">
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

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
<!--        
            TODO: this should be italic, not supported yet.
        -->
        <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, 11, false())"/>

        <xsl:call-template name="elementRef">
            <xsl:with-param name="elementName" select="QName($XSDNS, 'any')"/>
            <xsl:with-param name="label" select="$label"/>
            <xsl:with-param name="model-id" select="$model-id" tunnel="yes"/>
            <xsl:with-param name="refAttribute" select="@namespace"/>
            <xsl:with-param name="fontInfo" as="map(*)" select="$fontInfo"/>
            <xsl:with-param name="color-scheme" select="$color-scheme"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:function name="nk:tcell" as="map(xs:string, item()?)?">
        <xsl:param name="content" as="xs:string?"/>
        <xsl:sequence select="nk:tcell($content, ())"/>
    </xsl:function>
    <xsl:function name="nk:tcell" as="map(xs:string, item()?)?">
        <xsl:param name="content" as="xs:string?"/>
        <xsl:param name="tooltip" as="xs:string?"/>
        <xsl:sequence select="map{
            'content' : $content,
            'tooltip' : $tooltip
            }[exists($content)]"/>
    </xsl:function>

    <xsl:function name="nk:create-table">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <xsl:param name="cells" as="array(array(map(xs:string, item()?)))"/>
        <xsl:param name="cell-padding" as="xs:double"/>
        <xsl:param name="color-scheme" as="xs:string"/>
        <xsl:sequence select="nk:create-table($schemaSetConfig, $cells, $cell-padding, $color-scheme, ())"/>
    </xsl:function>

    <xsl:function name="nk:create-table">
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)"/>
        <xsl:param name="cells" as="array(array(map(xs:string, item()?)))"/>
        <xsl:param name="cell-padding" as="xs:double"/>
        <xsl:param name="color-scheme" as="xs:string"/>
        <xsl:param name="title" as="xs:string?"/>

        <xsl:variable name="class" select="'table content cs_' || $color-scheme"/>

        <xsl:variable name="lineheight" select="14"/>
        <xsl:variable name="fontSize" select="10"/>
        <xsl:variable name="stroke-width" select="0.5"/>
        
        <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, false())"/>
        
        <xsl:variable name="text-lengths" select="array {$cells?* ! array {.?* ! nk:renderedTextLength(?content, $fontInfo)}}"/>
        <xsl:variable name="cols" select="$cells?* ! array:size(.) => max()"/>

        <xsl:variable name="cell-padding2" select="$cell-padding * 2"/>

        <xsl:variable name="titleWidth" select="nk:renderedTextLength(($title, '')[1], $fontInfo) + $cell-padding2"/>


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
                    
                    <path d="{nk:createHalfRoundBox($tableWidth, $titleHeight, 7.5, true(), false())}" class="{$class} shaded filled"/>
                    
                    <text x="{$cell-padding}" y="{$titleHeight - 7.5}" class="{$class} shaded backgrounded">
                        <xsl:sequence select="$fontInfo?svg-attributes"/>
                        <xsl:value-of select="$title"/>
                    </text>
                    <line x1="0" x2="{$tableWidth}" y1="{$titleHeight}" y2="{$titleHeight}" class="{$class} bordered" stroke-width="{$stroke-width}"/>
                </g>
            </xsl:if>
        </xsl:variable>

        <svg width="{$tableWidth + 1}" height="{$tableHeight}" nk:cY="{$tableHeight div 2}" nk:displayW="{$tableWidth}" nk:displayH="{$tableHeight}">
            <xsl:sequence select="$title-svg"/>
            <g>
                <rect width="{$tableWidth}" height="{$tableHeight}" rx="7.5" ry="7.5" class="{$class} bordered" stoke-width="1" fill="none"/>
            </g>
            <xsl:for-each select="$cells?*">
                <xsl:variable name="rownr" select="position()"/>
                <xsl:variable name="rowPosY" select="($lineheight + $cell-padding) * $rownr - $cell-padding + $titleHeight"/>
                <xsl:variable name="lineY" select="$rowPosY + $cell-padding"/>

                <g alignment-baseline="baseline" transform="translate(0, {$rowPosY})">

                    <xsl:for-each select="$cells($rownr)?*">
                        <xsl:variable name="colnr" select="position()"/>

                        <xsl:variable name="x" select="sum($colWidths[position() lt $colnr])"/>


                        <text x="{$x + $cell-padding}" y="0">
                            <xsl:sequence select="$fontInfo?svg-attributes"/>
                            <xsl:if test="?tooltip">
                                <title>
                                    <xsl:value-of select="?tooltip"/>
                                </title>
                            </xsl:if>
                            <xsl:value-of select="?content"/>
                        </text>
                        <xsl:if test="position() gt 1">
                            <g>
                                <line x1="{$x}" x2="{$x}" y1="{$cell-padding}" y2="{$lineheight * -1}" class="{$class} bordered" stroke-width="{$stroke-width}"/>
                            </g>
                        </xsl:if>



                    </xsl:for-each>

                </g>

                <xsl:if test="position() lt last()">
                    <g>
                        <line x1="0" x2="{$tableWidth}" y1="{$lineY}" y2="{$lineY}" class="{$class} bordered" stroke-width="{$stroke-width}"/>
                    </g>
                </xsl:if>
            </xsl:for-each>

        </svg>


    </xsl:function>

    <xsl:function name="nk:cut-join">
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
                        if (nk:renderedTextLength($newVal || $endvalue, $textStyle) ge $cutvalue)
                            then
                                $oldValue || $endvalue
                            else
                                $newVal
                })
                "/>
    </xsl:function>


    <xsl:template match="@maxOccurs | @minOccurs" mode="nk:xsd2svg-content"/>

    <xsl:template match="xs:annotation" mode="nk:xsd2svg-content"/>




    <xsl:template match="@*" mode="nk:xsd2svg-content">
        <xsl:sequence select="error(xs:QName('nk:not-supported-element'), 'The attribute ' || name() || ' is not supported.')"/>
    </xsl:template>

    <xsl:template match="*" mode="nk:xsd2svg">
        <xsl:sequence select="error(xs:QName('nk:not-supported-element'), 'The element ' || name() || ' can not be converted to a SVG model. [' || path(.) || ']')"/>
    </xsl:template>

    <xsl:template match="*" mode="nk:xsd2svg-parent">
        <xsl:sequence select="error(xs:QName('nk:not-supported-parent'), 'The element ' || name() || ' is not supported as a parent XSD node.')"/>
    </xsl:template>

    <!--
    Parents
    -->

    <xsl:template match="xs:element[@name] | xs:attribute[@name] | xs:complexType[@name]" mode="nk:xsd2svg-parent">
        <xsl:param name="childId"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'object parent cs_' || $color-scheme"/>


        <xsl:variable name="symbol" select="nk:getSymbol(local-name(.))"/>

        <xsl:variable name="symbolWidth" select="nk:number($symbol/@width)"/>

        <xsl:variable name="parentName" select="nk:getName(.)"/>
        <xsl:variable name="hoverId" select="concat($model-id, '_', generate-id(), '_parentOf_', $childId)"/>


        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="label" select="nk:printQName($parentName, $schemaSetConfig)"/>
        
        <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, false())"/>
        
        <xsl:variable name="width" select="nk:renderedTextLength($label, $fontInfo)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR) + $symbolWidth"/>
        <svg width="{$width + 1}" height="30" nk:cY="15">
            <g alignment-baseline="baseline" id="{$hoverId}" transform="translate( 0, 2.5)">
                <!-- TODO               <a xlink:href="#{nk:convertId($parentName)}" target="_top">-->

                <xsl:call-template name="createLink">
                    <xsl:with-param name="content">
                        <svg width="{$width + 1}" height="26">
                            <g transform="translate(0.5, 0.5)">
                                <g>
                                    <rect width="{$width}" height="25" rx="10" ry="10" class="{$class} bordered opaque link-background" stoke-width="1"/>
                                </g>

                                <g transform="translate({$paddingLR div 2}, {$paddingLR div 2})">
                                    <xsl:sequence select="$symbol"/>
                                </g>

                                <text x="{$paddingLR + $symbolWidth}" y="16" class="{$class} link-text">
                                    <xsl:sequence select="$fontInfo?svg-attributes"/>
                                    <xsl:value-of select="$label"/>
                                </text>
                            </g>
                            <xsl:sequence select="nk:createDoku(.)"/>
                        </svg>
                    </xsl:with-param>
                </xsl:call-template>
                <!--</a>-->
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" mode="nk:xsd2svg-parent">
        <xsl:param name="childId"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="local-name()"/>

        <xsl:variable name="class" select="'object parent cs_' || $color-scheme"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_', generate-id(), '_parentOf_', $childId)"/>
        <xsl:variable name="groupName" select="nk:getName(.)"/>

        <xsl:variable name="header">
            <xsl:call-template name="groupTitle">
                <xsl:with-param name="title" select="nk:printQName($groupName, $schemaSetConfig)"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="header" select="$header/svg:svg"/>
        <xsl:variable name="width" select="$header/@width"/>
        <xsl:variable name="height" select="$header/@height"/>

        <svg width="{$width}" height="{$height + 5}" nk:cY="{($height div 2) + 2.5}" nk:color-scheme="{$color-scheme}">
            <g transform="translate(1,1)" id="{$hoverId}">
                <!--    TODO            <a xlink:href="#{nk:convertId($groupName)}" target="_top">-->
                <xsl:call-template name="createLink">
                    <xsl:with-param name="content">
                        <path stoke-width="1" class="{$class} bordered opaque link-background">
                            <xsl:attribute name="d" select="
                                    'M', 0, $height + 3,
                                    'L', 0, 10,
                                    'Q', 0, 0, 10, 0,
                                    'L', $width - 12, 0,
                                    'Q', $width - 2, 0, $width - 2, 10,
                                    'L', $width - 2, $height + 3"/>
                        </path>
                        <path d="M 2.5 {$height + 2} L {$width - 4.5} {$height + 2}" fill="none" class="{$class} bordered link-background" stroke-width="0.25"/>
                        <g transform="translate(0, 2.5)">
                            <xsl:copy-of select="$header"/>
                        </g>
                    </xsl:with-param>
                </xsl:call-template>
                <!--</a>-->
            </g>
            <xsl:sequence select="nk:createDoku(.)"/>
        </svg>
    </xsl:template>

    <xsl:template name="createAttributeBox">

        <xsl:call-template name="createContentBox">
            <xsl:with-param name="color-scheme" select="'attribute'"/>
            <xsl:with-param name="content">
                <xsl:apply-templates select="xs:attribute | xs:attributeGroup" mode="nk:xsd2svg-content"/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="createContentBox">
        <xsl:param name="content" required="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="'default'"/>
        <xsl:param name="title" as="node()*"/>
        <xsl:param name="title-link-target" select="()" as="node()?"/>

        <xsl:variable name="class" select="'box cs_' || $color-scheme"/>


        <xsl:variable name="titleSvg" select="$title/svg:svg"/>

        <xsl:variable name="titleHeight" select="
                ($titleSvg/(@height), 0) => max()"/>

        <xsl:variable name="titleWidth" select="($titleSvg/(@width + 10), 0) => max()"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($content/@height) + $titleHeight"/>
        <xsl:variable name="contentWidth" select="max(($content/@width, $titleWidth))"/>


        <xsl:variable name="svgWidth" select="$contentWidth + 2.5"/>
        <xsl:if test="$content">
            <svg width="{$svgWidth + 1}" height="{$contentHeight + 10}" class="attribute_box" nk:cY="{$content/@nk:cY + 5 + $titleHeight}" nk:multiValue="{nk:multiValuesMerge($contentSVGs)}" nk:color-scheme="{$color-scheme}">
                <g transform="translate(0.5, 2.5)">

                    <xsl:if test="$titleSvg">
                        <xsl:call-template name="createLink">
                            <xsl:with-param name="content">
                                <g>
                                    <rect height="{$titleHeight}" width="{$svgWidth}" rx="10" ry="10" class="{$class} opaque link-background"/>
                                    <rect y="{$titleHeight div 2}" height="{$titleHeight div 2}" width="{$svgWidth}" class="{$class} opaque link-background"/>
                                    <xsl:sequence select="$titleSvg"/>
                                    <path d="M 2.5 {$titleHeight} L {$svgWidth - 4.5} {$titleHeight}" fill="none" class="{$class} bordered" stroke-width="0.25"/>
                                </g>
                            </xsl:with-param>
                            <xsl:with-param name="linkTarget" select="$title-link-target"/>
                        </xsl:call-template>
                    </xsl:if>

                    <rect height="{$contentHeight + 5}" width="{$svgWidth}" rx="10" ry="10" class="{$class} bordered" stoke-width="1" fill="none"/>
                    <g transform="translate(0, {2.5 + $titleHeight})">
                        <xsl:copy-of select="$content"/>
                    </g>
                </g>
            </svg>
        </xsl:if>

    </xsl:template>

    <xsl:template name="createTreeNode">
        <xsl:param name="this" as="node()" select="."/>
        <xsl:param name="symbol" required="yes"/>
        <xsl:param name="content">
            <xsl:apply-templates select="$this/xs:*" mode="#current"/>
        </xsl:param>
        <xsl:param name="color-scheme" select="local-name()" as="xs:string"/>

        <xsl:variable name="class" select="'path cs_' || $color-scheme"/>

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
                <xsl:with-param name="content" select="$contentTop/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="
                        if ($contentCount gt 3) then
                            (30)
                        else
                            (15)"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$contentRight/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="
                        if ($contentCount gt 3) then
                            (30)
                        else
                            (15)"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$contentBottom/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="
                        if ($contentCount gt 3) then
                            (30)
                        else
                            (15)"/>
                <xsl:with-param name="color-scheme" select="$color-scheme"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="multiValue" select="nk:getMultiValue(.)"/>

        <xsl:variable name="contentSVGs" select="$contentNet/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementSVG" select="$symbol/(self::svg:svg, svg:svg)[1]"/>
        <xsl:variable name="elementHeight" select="sum($elementSVG/@height)"/>
        <xsl:variable name="elementWidth" select="max($elementSVG/@width)"/>

        <xsl:variable name="countContent" select="count($contentSVGs)"/>
        <xsl:variable name="contentCY" select="
                if ($countContent = 2)
                then
                    (
                    ($contentSVGs[2]/@nk:cY + $contentSVGs[1]/@height + $contentSVGs[1]/@nk:cY
                    ) div 2
                    )
                else
                    if ($countContent = 1)
                    then
                    ($contentSVGs[1]/@nk:cY)
                    else
                    ($contentSVGs[2]/@nk:cY + $contentSVGs[1]/@height)"/>

        <xsl:variable name="posY" select="max(($contentCY - nk:number($elementSVG/@nk:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="
                (if ($contentSVGs/@width) then
                    (max($contentSVGs/@width))
                else
                    (0)) + $elementWidth"/>
        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" nk:cY="{max(($contentCY, nk:number($elementSVG/@nk:cY, xs:decimal($elementHeight div 2))))}" nk:multiValue="{$multiValue}">
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
                <path fill="none" stroke-width="1" class="{$class} bordered">
                    <xsl:variable name="ctop" select="$elementSVG/@nk:cXTop, $elementSVG/@nk:cYTop"/>
                    <xsl:attribute name="d" select="
                            ('M', $ctop[1], $posY + $ctop[2],
                            'L', $ctop[1], $contentSVGs[1]/@nk:cY + 7,
                            'Q', $ctop[1], $contentSVGs[1]/@nk:cY, $ctop[1] + 7, $contentSVGs[1]/@nk:cY,
                            'L', $elementWidth, $contentSVGs[1]/@nk:cY)"/>
                </path>
                <path fill="none" stroke-width="1" class="{$class} bordered">
                    <xsl:variable name="cbot" select="$elementSVG/@nk:cXBottom, $elementSVG/@nk:cYBottom"/>
                    <xsl:variable name="lastCY" select="sum($contentSVGs[position() != last()]/@height) + $contentSVGs[last()]/@nk:cY"/>
                    <xsl:attribute name="d" select="
                            ('M', $cbot[1], $posY + $cbot[2],
                            'L', $cbot[1], $lastCY - 7,
                            'Q', $cbot[1], $lastCY, $cbot[1] + 7, $lastCY,
                            'L', $elementWidth, $lastCY)"/>
                </path>
            </xsl:if>
        </svg>

    </xsl:template>

    <xsl:template name="makeParentSVGs">
        <xsl:param name="this" select="." as="element()"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>

        <xsl:variable name="parents" select="nk:getParents($this, $schemaSetConfig)"/>

        <xsl:variable name="parentContent">
            <xsl:apply-templates select="$parents" mode="nk:xsd2svg-parent"/>
        </xsl:variable>
        <xsl:variable name="parentConnect">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$parentContent/svg:svg"/>
                <xsl:with-param name="rightPathPosition" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$parentConnect"/>
    </xsl:template>

    <xsl:template name="xsdSimpleTypeRef">
        <xsl:param name="typeName" select="nk:getQName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="schemaSetConfig" as="map(xs:string, item()*)" tunnel="yes"/>
        <xsl:param name="color-scheme" select="'simpleType'" as="xs:string"/>

        <xsl:variable name="class" select="'object content cs_' || $color-scheme"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="15"/>

        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>

        <xsl:variable name="symbol">
            <xsl:call-template name="simpleTypeSymbol"/>
        </xsl:variable>
        <xsl:variable name="symbolWidth" select="nk:number($symbol/svg:svg/@width/(. + $paddingLR div 2))"/>

        <xsl:variable name="label" select="nk:printQName($typeName, $schemaSetConfig)"/>
        <xsl:variable name="fontInfo" select="nk:create-font-info($schemaSetConfig, $fontSize, false())"/>
        <xsl:variable name="width" select="nk:renderedTextLength($label, $fontInfo)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR) + $symbolWidth"/>

        <svg width="{$width}" height="30" class="element_ref" nk:cY="{$cY}" nk:displayW="{$width}" nk:displayH="0" nk:multiValue="one">
            <xsl:attribute name="nk:minOccurs" select="1"/>
            <xsl:attribute name="nk:maxOccurs" select="1"/>
            <desc/>
            <g alignment-baseline="baseline" class="svg-element-ref" transform="translate(0, 2.5)">
                <g id="{$hoverId}">
                    <!--                    
                                    TODO
                                    <xsl:variable name="isDoku" select="root($refElement) = $dokuSchema" as="xs:boolean"/>
                                -->
                    <svg width="{$width + 1}" height="26">
                        <xsl:variable name="rect">
                            <rect height="25" width="{$width}" rx="10" ry="10" class="{$class} bordered opaque" stoke-width="1"/>
                        </xsl:variable>
                        <g transform="translate(0.5, 0.5)">
                            <xsl:copy-of select="$rect"/>

                            <g transform="translate({$paddingLR}, {$paddingLR div 2})">
                                <xsl:sequence select="$symbol"/>
                            </g>

                            <text x="{$paddingLR + $symbolWidth}" y="16">
                                <xsl:sequence select="$fontInfo?svg-attributes"/>
                                <xsl:value-of select="$label"/>
                            </text>
                        </g>

                        <xsl:sequence select="nk:createDoku($buildInTypeDocs, 'simpleType')"/>

                    </svg>


                </g>
            </g>
        </svg>

    </xsl:template>

    <xsl:variable name="buildInTypeDocs" as="element(xs:annotation)">
        <xs:annotation>
            <xs:documentation>XSD build in type.</xs:documentation>
        </xs:annotation>
    </xsl:variable>




</xsl:stylesheet>
