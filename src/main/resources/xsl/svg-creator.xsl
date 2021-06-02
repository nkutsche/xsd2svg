<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:saxon="http://saxon.sf.net/" exclude-result-prefixes="xs" version="2.0">

    <xsl:output saxon:next-in-chain="svg-creator2.xsl"/>

    <xsl:key name="elementByQName" match="xs:*[@name]" use="sqf:getName(.)"/>

    <!--    <xsl:include href="../functions.xsl"/>-->

    <!--    <xsl:variable name="allSchema" select="sqf:getReferencedSchemas(/, ())"/>-->

    <!--<xsl:template match="/">
        <svg width="100%" height="100%">
            <xsl:apply-templates select="$allSchema/xs:schema" mode="svg"/>
        </svg>
    </xsl:template>-->


    <xsl:template match="xs:schema/xs:element[@name]" mode="svg">
        <xsl:param name="elementName" select="sqf:getName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="12.5"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="svg">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="parents">
            <xsl:call-template name="makeParentSVGs">
                <xsl:with-param name="elementName" select="$elementName"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="doku" select="$content/sqf:docu/svg:svg"/>

        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementHeight" select="30"/>
        <xsl:variable name="dokuWidth" select="sqf:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>

        <xsl:variable name="maxCY" select="max(($contentSVGs/@sqf:cY, $elementHeight div 2, $parents/@sqf:cY))"/>

        <xsl:variable name="parentPosY" select="sqf:number($maxCY - $parents/@sqf:cY)"/>
        <xsl:variable name="elementPosY" select="sqf:number($maxCY - ($elementHeight div 2))"/>
        <xsl:variable name="contentPosY" select="sqf:number($maxCY - $contentSVGs/@sqf:cY)"/>

        <xsl:variable name="posY" select="max(($contentSVGs/@sqf:cY - ($elementHeight div 2), 0))"/>
        <xsl:variable name="position" select="(0, $posY)"/>

        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight, $parents/@height))"/>
        <svg width="10" height="{$svgHeight}" id="{$model-id}_{sqf:convertId($elementName)}" sqf:cY="{$contentSVGs/@sqf:cY}" sqf:displayW="{$dokuWidth}" sqf:displayH="{max(($dokuHeight - $elementHeight, 0))}">
            <desc/>
            <xsl:variable name="fontSize" select="11"/>
            <xsl:variable name="paddingLR" select="5"/>
            <xsl:variable name="width" select="sqf:renderedTextLength($elementName, 'Arial', 'plain', $fontSize)"/>
            <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
            <xsl:variable name="parentWidth" select="sqf:number(max($parents/@width))"/>

            <g alignment-baseline="baseline" transform="translate({$parentWidth}, {$elementPosY + 2.5})" id="{$hoverId}">
                <g>
                    <!--                    <path d="{sqf:createRoundBox($width, 25, 10, true())}" stroke="#007" stoke-width="1" fill="none"/>-->
                    <rect width="{$width}" height="25" rx="10" ry="10" stroke="#007" stoke-width="1" fill="#88f"/>
                </g>
                <text x="{$paddingLR}" y="16" fill="white" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
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

    <xsl:template name="makeParentSVGs">
        <xsl:param name="elementName" select="sqf:getName(.)"/>
        <xsl:param name="model-id"/>
        <xsl:param name="id" select="generate-id()"/>
        <xsl:param name="isElement" select="true()" as="xs:boolean"/>
        
        <xsl:variable name="dokuParents" select="for $ds 
                                                  in $dokuSchema
                                              return if ($isElement) 
                                                   then (key('parentByElement',$elementName, $ds)) 
                                                   else (key('elementByAttributename', $elementName, $ds))"/>
        <xsl:variable name="refParents" select="for $rs
                                                 in $refSchema 
                                             return if ($isElement) 
                                                  then (key('parentByElement',$elementName, $rs)) 
                                                  else (key('elementByAttributename', $elementName, $rs))"/>
        <xsl:variable name="parentContent">
            <xsl:apply-templates select="$dokuParents | $refParents" mode="svgParent"/>
        </xsl:variable>
        <xsl:variable name="parentConnect">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$parentContent/svg:svg"/>
                <xsl:with-param name="rightPathPosition" select="true()"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="$parentConnect"/>
    </xsl:template>

    <xsl:template match="xs:element[@name]" mode="svgParent">
        <xsl:param name="childId"/>
        <xsl:param name="model-id" tunnel="yes"/>

        <xsl:variable name="parentName" select="sqf:getName(.)"/>
        <xsl:variable name="hoverId" select="concat($model-id,'_', generate-id() ,'_parentOf_', $childId)"/>

        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="svg">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="12.5"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/sqf:docu/svg:svg"/>

        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="width" select="sqf:renderedTextLength($parentName, 'Arial', 'plain', $fontSize)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
        <svg width="{$width}" height="30" sqf:cY="15">
            <g alignment-baseline="baseline" id="{$hoverId}" transform="translate( 0, 2.5)">
                <a xlink:href="#{sqf:convertId($parentName)}" target="_top">
                    <g>
                        <!--                    <path d="{sqf:createRoundBox($width, 25, 10, true())}" stroke="#007" stoke-width="1" fill="none"/>-->
                        <rect width="{$width}" height="25" rx="10" ry="10" stroke="#007" stoke-width="1" fill="white"/>
                    </g>
                    <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                        <xsl:value-of select="$parentName"/>
                    </text>
                </a>
            </g>
            <g transform="translate({$width}, 2.5)">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>
    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" mode="svgParent">
        <xsl:param name="childId"/>
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:variable name="color" select="if (self::xs:group) then ('#007') else ('#F5844C')"/>
        <xsl:variable name="hoverId" select="concat($model-id,'_', generate-id() ,'_parentOf_', $childId)"/>
        <xsl:variable name="groupName" select="sqf:getName(.)"/>

        <xsl:variable name="header">
            <xsl:call-template name="groupTitle">
                <xsl:with-param name="title" select="$groupName"/>
                <xsl:with-param name="color" select="$color"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="header" select="$header/svg:svg"/>
        <xsl:variable name="width" select="$header/@width"/>
        <xsl:variable name="height" select="$header/@height"/>

        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="svg">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$height div 2"/>
                <xsl:with-param name="color" select="$color"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/sqf:docu/svg:svg"/>

        <svg width="{$width}" height="{$height + 5}" sqf:cY="{($height div 2) + 2.5}" sqf:stroke="{$color}">
            <g transform="translate(1,1)" id="{$hoverId}">
                <a xlink:href="#{sqf:convertId($groupName)}" target="_top">
                    <path stroke="{$color}" stoke-width="1" fill="white">
                        <xsl:attribute name="d" select="'M', 0, $height + 3,
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
                </a>
            </g>
            <g transform="translate({$width}, 2.5)">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:complexType" mode="svg">
        <xsl:variable name="content">
            <xsl:call-template name="createAttributeBox"/>
            <xsl:apply-templates select="xs:* except (xs:attribute | xs:attributeGroup)" mode="svg"/>
        </xsl:variable>
        <xsl:call-template name="drawObjectPaths">
            <xsl:with-param name="content" select="$content/svg:svg"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:any" mode="svg">
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:variable name="ns" select=" if (@namespace) then (@namespace) else ('##any')"/>
        <!--        <xsl:variable name="prefix" select="name(namespace::*[.=$ns])"/>
        <xsl:variable name="name" select=" if ($prefix) then (concat($prefix, ':*')) else ('*')"/>-->
        <xsl:call-template name="elementRef">
            <xsl:with-param name="elementName" select="$ns"/>
            <xsl:with-param name="model-id" select="$model-id"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="xs:element[@ref]" name="elementRef" mode="svg">
        <xsl:param name="elementName" select="sqf:getName(.)"/>
        <xsl:param name="model-id" tunnel="yes"/>

        <xsl:variable name="refElement" select="(for $s in $allSchema return key('elementByQName', $elementName, $s)[self::xs:element])[1]" as="node()?"/>
        <xsl:variable name="hoverId" select="concat($model-id, '_elementRef_', generate-id())"/>
        <xsl:variable name="cY" select="15"/>
        <xsl:variable name="doku">
            <xsl:apply-templates select="$refElement/xs:annotation" mode="svg">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/sqf:docu/svg:svg"/>
        <xsl:variable name="dokuWidth" select="sqf:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>

        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="width" select="sqf:renderedTextLength($elementName, 'Arial', 'plain', $fontSize)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>

        <xsl:variable name="multiValue" select="sqf:getMultiValue(.)"/>

        <svg width="{$width}" height="30" class="element_ref" sqf:cY="{$cY}" sqf:displayW="{$dokuWidth}" sqf:displayH="{max(($dokuHeight - 30, 0))}" sqf:multiValue="{$multiValue}">
            <xsl:if test="$multiValue = ($MultiValues[3], $MultiValues[4])">
                <xsl:attribute name="height" select="33.5"/>
            </xsl:if>
            <xsl:attribute name="sqf:minOccurs" select="1"/>
            <xsl:attribute name="sqf:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs|@maxOccurs" mode="svg"/>
            <desc/>
            <g alignment-baseline="baseline" class="svg-element-ref" transform="translate(0, 2.5)">
                <g id="{$hoverId}">
                    <xsl:variable name="isDoku" select="root($refElement) = $dokuSchema" as="xs:boolean"/>
                    <xsl:variable name="rect">
                        <rect height="25" width="{$width}" rx="10" ry="10" stroke="#007" stoke-width="1" fill="white">
                            <xsl:if test="$multiValue = ($MultiValues[1], $MultiValues[3])">
                                <xsl:attribute name="stroke-dashoffset" select="2"/>
                                <xsl:attribute name="stroke-dasharray" select="2"/>
                            </xsl:if>
                            <xsl:if test="$isDoku">
                                <set attributeName="fill" to="#88f" begin="{$hoverId}.mouseover" end="{$hoverId}.mouseout"/>
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
                    <xsl:choose>
                        <xsl:when test="$isDoku">
                            <a xlink:href="#{sqf:convertId($elementName)}" target="_top">
                                <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                                    <set attributeName="fill" to="#fff" begin="{$hoverId}.mouseover" end="{$hoverId}.mouseout"/>
                                    <xsl:value-of select="$elementName"/>
                                </text>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                                <xsl:value-of select="$elementName"/>
                            </text>
                        </xsl:otherwise>
                    </xsl:choose>
                </g>
            </g>
            <g transform="translate({$width}, 0)" sqf:z-index="0">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="@minOccurs|@maxOccurs" mode="svg" priority="50">
        <xsl:attribute name="sqf:{local-name()}" select="."/>
    </xsl:template>

    <xsl:template name="createAttributeBox">
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:attribute | xs:attributeGroup" mode="svg"/>
        </xsl:variable>
        <xsl:variable name="contentSVGs" select="$content/svg:svg"/>
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="strokeColor" select="'#F5844C'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($content/@height)"/>
        <xsl:variable name="contentWidth" select="max($content/@width)"/>

        <xsl:variable name="svgWidth" select="$contentWidth + 2.5"/>
        <xsl:if test="$content">
            <svg width="{$svgWidth}" height="{$contentHeight + 10}" class="attribute_box" sqf:cY="{$content/@sqf:cY + 5}" sqf:multiValue="{sqf:multiValuesMerge($contentSVGs)}" sqf:stroke="#F5844C">
                <g transform="translate(0, 2.5)">
                    <!--                    <path d="{sqf:createRoundBox($svgWidth, $contentHeight + 5, 10, true())}" stroke="#F5844C" stroke-width="1" fill="none"/>-->
                    <rect height="{$contentHeight + 5}" width="{$svgWidth}" rx="10" ry="10" stroke="#F5844C" stoke-width="1" fill="white"/>
                    <g transform="translate(0, 2.5)">
                        <xsl:copy-of select="$content"/>
                    </g>
                </g>
            </svg>
        </xsl:if>
    </xsl:template>

    <xsl:template match="xs:attribute[@name]" mode="svg">
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:param name="multiValue" select="sqf:getMultiValue(.)" as="xs:string"/>
        <xsl:variable name="attributName" select="sqf:getName(.)"/>
        <xsl:variable name="elementHeight" select="25"/>
        <xsl:variable name="position" select="(0, 2.5)"/>
        <xsl:variable name="cY" select="$position[2] + ($elementHeight div 2)"/>

        <xsl:variable name="hoverId" select="concat($model-id, '_attributName_', generate-id())"/>
        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="svg">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="color" select="'#F5844C'"/>
                <xsl:with-param name="cY" select="$cY"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="doku" select="$doku/sqf:docu/svg:svg"/>
        <xsl:variable name="dokuWidth" select="sqf:number(max($doku/@width))"/>
        <xsl:variable name="dokuHeight" select="sum($doku/@height)"/>


        <xsl:variable name="fontSize" select="11"/>
        <xsl:variable name="paddingLR" select="5"/>
        <xsl:variable name="width" select="sqf:renderedTextLength($attributName, 'Arial', 'plain', $fontSize)"/>
        <xsl:variable name="width" select="$width + (2 * $paddingLR)"/>
        <svg width="{$width}" height="{$elementHeight + 5}" sqf:cY="{$cY}" class="attribute" id="{$model-id}_attribute_{sqf:convertId($attributName)}" sqf:displayW="{$dokuWidth}" sqf:displayH="{max(($dokuHeight - ($elementHeight + 5), 0))}" sqf:multiValue="{$multiValue}">
            <desc/>
            <g alignment-baseline="baseline" transform="translate({$position[1]}, {$position[2]})" id="{$hoverId}">
                <g>
                    <!--                    <path d="{sqf:createRoundBox($width, $elementHeight, 10, true())}" stroke="#F5844C" stoke-width="1" fill="none"/>-->
                    <rect height="{$elementHeight}" width="{$width}" rx="10" ry="10" stroke="#F5844C" stoke-width="1" fill="white">
                        <xsl:if test="$multiValue = $MultiValues[1]">
                            <xsl:attribute name="stroke-dasharray" select="5, 5" separator=","/>
                        </xsl:if>
                    </rect>
                </g>
                <text x="{$paddingLR}" y="16" fill="black" font-family="arial, helvetica, sans-serif" font-size="{$fontSize}">
                    <xsl:value-of select="$attributName"/>
                </text>
            </g>
            <g transform="translate({$width}, 0)" sqf:z-index="0">
                <xsl:copy-of select="$doku"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:attribute[@ref]" mode="svg">
        <xsl:param name="model-id" tunnel="yes"/>
        <xsl:variable name="attributName" select="sqf:getName(.)"/>
        <xsl:variable name="nsUri" select="namespace-uri-for-prefix(substring-before($attributName, ':'), .)"/>
        <xsl:variable name="schema" select="$allSchema[xs:schema/@targetNamespace=$nsUri]"/>
        <xsl:variable name="refAttribut" select="$schema/xs:schema/xs:attribute[sqf:getName(.) = $attributName]"/>
        <xsl:apply-templates select="$refAttribut" mode="svg">
            <xsl:with-param name="multiValue" select="sqf:getMultiValue(.)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="xs:choice" mode="svg" priority="10">
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="svg"/>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentCount" select="count($content)"/>
        <xsl:variable name="contentMod" select="$contentCount mod 3"/>
        <xsl:variable name="contentTopBotCount" select="xs:integer(floor($contentCount div 3) + (if ($contentMod = 2) then (1) else (0)))" as="xs:integer"/>

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
                <xsl:with-param name="minX1" select=" if ($contentCount gt 3) then (30) else (15)"/>
            </xsl:call-template>
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$contentRight/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="if ($contentCount gt 3) then (30) else (15)"/>
            </xsl:call-template>
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$contentBottom/svg:svg"/>
                <xsl:with-param name="x1" select="0"/>
                <xsl:with-param name="x2" select="30"/>
                <xsl:with-param name="minX1" select="if ($contentCount gt 3) then (30) else (15)"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="multiValue" select="sqf:getMultiValue(.)"/>
        <xsl:variable name="elementSymbol">
            <xsl:call-template name="choiceSymbol">
                <xsl:with-param name="multiValue" select="$multiValue"/>
                <xsl:with-param name="connectCount" select=" if ($contentCount ge 3) then (3) else ($contentCount)"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="contentSVGs" select="$contentNet/svg:svg"/>
        <xsl:variable name="contentHeight" select="sum($contentSVGs/@height)"/>
        <xsl:variable name="elementSVG" select="$elementSymbol/svg:svg"/>
        <xsl:variable name="elementHeight" select="sum($elementSVG/@height)"/>
        <xsl:variable name="elementWidth" select="max($elementSVG/@width)"/>

        <xsl:variable name="countContent" select="count($contentSVGs)"/>
        <xsl:variable name="contentCY" select=" if ($countContent = 2) 
                                              then (
                                              ($contentSVGs[2]/@sqf:cY + $contentSVGs[1]/@height + $contentSVGs[1]/@sqf:cY
                                              ) div 2
                                              ) 
                                           else if ($countContent = 1) 
                                              then ($contentSVGs[1]/@sqf:cY) 
                                              else ($contentSVGs[2]/@sqf:cY + $contentSVGs[1]/@height)"/>

        <xsl:variable name="posY" select="max(($contentCY - sqf:number($elementSVG/@sqf:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="(if ($contentSVGs/@width) then (max($contentSVGs/@width)) else (0)) + $elementWidth"/>
        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" sqf:cY="{max(($contentCY, sqf:number($elementSVG/@sqf:cY, xs:decimal($elementHeight div 2))))}" sqf:multiValue="{$multiValue}">
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
                <path fill="none" stroke-width="1" stroke="#007">
                    <xsl:variable name="ctop" select="$elementSVG/@sqf:cXTop, $elementSVG/@sqf:cYTop"/>
                    <xsl:attribute name="d" select="('M', $ctop[1], $posY + $ctop[2],
                                                     'L', $ctop[1], $contentSVGs[1]/@sqf:cY + 7,
                                                     'Q', $ctop[1], $contentSVGs[1]/@sqf:cY, $ctop[1] + 7, $contentSVGs[1]/@sqf:cY,
                                                     'L', $elementWidth, $contentSVGs[1]/@sqf:cY)"/>
                </path>
                <path fill="none" stroke-width="1" stroke="#007">
                    <xsl:variable name="cbot" select="$elementSVG/@sqf:cXBottom, $elementSVG/@sqf:cYBottom"/>
                    <xsl:variable name="lastCY" select="sum($contentSVGs[position() != last()]/@height) + $contentSVGs[last()]/@sqf:cY"/>
                    <xsl:attribute name="d" select="('M', $cbot[1], $posY + $cbot[2],
                                                     'L', $cbot[1],  $lastCY - 7,
                                                     'Q', $cbot[1], $lastCY, $cbot[1] + 7, $lastCY,
                                                     'L', $elementWidth, $lastCY)"/>
                </path>
            </xsl:if>
        </svg>

    </xsl:template>

    <xsl:template match="xs:sequence" mode="svg">
        <xsl:variable name="multiValue" select="sqf:getMultiValue(.)"/>
        
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:*" mode="svg"/>
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


        <!--        <xsl:variable name="posY" select="max((($contentHeight div 2) - ($elementHeight div 2), 0))"/>-->
        <xsl:variable name="posY" select="max(($contentSVGs/@sqf:cY - sqf:number($elementSVG/@sqf:cY, xs:decimal($elementHeight div 2)), 0))"/>
        <xsl:variable name="svgHeight" select="max(($contentHeight, $elementHeight))"/>
        <xsl:variable name="svgWidth" select="(if ($contentSVGs/@width) then (max($contentSVGs/@width)) else (0)) + $elementWidth"/>

        <svg width="{$svgWidth}" height="{$svgHeight}" class="{local-name()}" sqf:cY="{max(($contentSVGs/@sqf:cY, sqf:number($elementSVG/@sqf:cY, xs:decimal($elementHeight div 2))))}" sqf:multiValue="{$multiValue}">
            <xsl:attribute name="sqf:minOccurs" select="1"/>
            <xsl:attribute name="sqf:maxOccurs" select="1"/>
            <xsl:apply-templates select="@minOccurs|@maxOccurs" mode="svg"/>

            <g transform="translate(0,{$posY})">
                <xsl:copy-of select="$elementSVG"/>
            </g>
            <g transform="translate({$elementWidth},0)">
                <xsl:copy-of select="$contentSVGs"/>
            </g>
        </svg>
    </xsl:template>

    <xsl:template match="xs:group[@ref] | xs:attributeGroup[@ref]" mode="svg">
        <xsl:variable name="groupName" select="sqf:getName(.)"/>
        <xsl:variable name="refGroup" select="(for $s in $allSchema return key('elementByQName', $groupName, $s))[1]"/>
        <xsl:apply-templates select="$refGroup" mode="svg">
            <xsl:with-param name="id" select="generate-id()"/>
            <xsl:with-param name="multiValue" select="sqf:getMultiValue(.)"/>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="xs:group[@name] | xs:attributeGroup[@name]" mode="svg">
        <xsl:param name="id" select="generate-id()"/>
        <xsl:param name="multiValue" select="$MultiValues[2]"/>
        <xsl:param name="model-id" tunnel="yes"/>

        <xsl:variable name="isRoot" select="$id = generate-id()" as="xs:boolean"/>

        <xsl:variable name="color" select="if (self::xs:group) then ('#007') else ('#F5844C')"/>
        <xsl:variable name="groupName" select="sqf:getName(.)"/>
        <xsl:variable name="hoverId" select="concat($model-id, '_group_', $id)"/>
        <xsl:variable name="content">
            <xsl:apply-templates select="xs:* except xs:annotation" mode="svg"/>
        </xsl:variable>
        <xsl:variable name="doku">
            <xsl:apply-templates select="xs:annotation" mode="svg">
                <xsl:with-param name="hover_id" select="$hoverId" tunnel="yes"/>
                <xsl:with-param name="cY" select="15"/>
                <xsl:with-param name="invisible_ids" select="$content//svg:set/@sqf:dokuViewer" tunnel="yes"/>
                <xsl:with-param name="color" select="$color"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="dokuSVG" select="$doku/sqf:docu/svg:svg"/>
        <xsl:variable name="content">
            <xsl:call-template name="drawObjectPaths">
                <xsl:with-param name="content" select="$content/svg:svg"/>
                <xsl:with-param name="strokeColor" select="$color"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>

        <xsl:variable name="parents">
            <xsl:if test="$isRoot">
                <xsl:call-template name="makeParentSVGs">
                    <xsl:with-param name="elementName" select="$groupName"/>
                    <xsl:with-param name="isElement" select="exists(self::xs:group)"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="parents" select="$parents/svg:svg"/>
        <xsl:variable name="parentsWidth" select="sqf:number($parents/@width)"/>
        <xsl:variable name="parentsHeight" select="sqf:number($parents/@height)"/>
        <xsl:variable name="parentsCY" select="sqf:number($parents/@sqf:cY)"/>

        <xsl:variable name="header">
            <xsl:call-template name="groupTitle">
                <xsl:with-param name="title" select="$groupName"/>
                <xsl:with-param name="color" select="$color"/>
                <xsl:with-param name="font-color" select=" if ($isRoot) then ('black') else ('black')"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="header" select="$header/svg:svg"/>

        <xsl:variable name="cY" select="$content/@sqf:cY + $header/@height + 7.5"/>


        <xsl:variable name="maxCY" select="max(($cY, $parents/@sqf:cY))"/>

        <xsl:variable name="parentPosY" select="sqf:number($maxCY - $parentsCY)"/>
        <xsl:variable name="groupPosY" select="sqf:number($maxCY - $cY)"/>
        <xsl:variable name="groupHeight" select="sum(($content/@height, $header/@height))"/>

        <xsl:variable name="width" select="max(($content/@width, $header/@width))"/>
        <xsl:variable name="height" select="max(($groupHeight, $parentsHeight))"/>


        <svg width="{$width + 7.5 + $parentsWidth}" height="{$height + 15}" sqf:cY="{$cY}" sqf:displayW="{sqf:number($dokuSVG/@width)}" sqf:displayH="{sqf:number($dokuSVG/@height)}" class="element_group" sqf:multiValue="{$multiValue}">
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
                <xsl:choose>
                    <xsl:when test="$isRoot">
                        <path fill="{$color}" opacity="0.1">
                            <xsl:attribute name="d" select="'M', 0, $header/@height,
                                                            'L', 0, 7, 
                                                            'Q', 0, 0, 7, 0,
                                                            'L', $width - 4.5, 0,
                                                            'Q', $width + 2.5, 0, $width + 2.5, 7,
                                                            'L', $width + 2.5, $header/@height, 'Z'"/>
                        </path>
                        <xsl:copy-of select="$headerWithBorder"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <a xlink:href="#{sqf:convertId($groupName)}" target="_top">
                            <xsl:copy-of select="$headerWithBorder"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
                <g transform="translate({$width + 1}, 0)" sqf:z-index="0">
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

    <xsl:template match="node() | @*" mode="groupContent">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="xs:annotation[xs:documentation]" mode="svg">
        <xsl:param name="hover_id" tunnel="yes" select="''"/>
        <xsl:param name="invisible_ids" tunnel="yes" select="()"/>
        <xsl:param name="color" select="'#007'"/>
        <xsl:param name="cY" select="15"/>
        <xsl:variable name="textContent" select="string-join(xs:documentation, '')"/>
        <xsl:variable name="textLength" select="sqf:renderedTextLength($textContent, 'Arial', 'plain', 11)"/>

        <xsl:variable name="content">
            <xsl:apply-templates select="xs:documentation" mode="svg">
                <xsl:with-param name="text-width" select=" if ($textLength lt 2000) then (300) else (500)"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="content" select="$content/svg:svg"/>
        <xsl:variable name="contentWidth" select="max($content/@width)"/>
        <xsl:variable name="contentHeight" select="sum($content/@height)"/>
        <sqf:docu>
            <svg width="{$contentWidth + 32}" height="{$contentHeight + 17}" class="annotation">
                <g visibility="hidden" style="z-index:1000">
                    <set attributeName="visibility" to="visible" begin="{$hover_id}.mouseover" end="{$hover_id}.mouseout" sqf:dokuViewer="{$hover_id}"/>
                    <xsl:for-each select="$invisible_ids">
                        <set attributeName="visibility" to="hidden" begin="{.}.mouseover" end="{.}.mouseout"/>
                    </xsl:for-each>
                    <g transform="translate(1,1)">
                        <xsl:variable name="curve" select="min((10, $cY - 5))"/>
                        <path d="{sqf:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="white" opacity="1" stroke="{$color}" stroke-width="1"/>
                        <path d="{sqf:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="{$color}" opacity="0.1" stroke="{$color}" stroke-width="1"/>
                        <path d="{sqf:createBalloon($contentWidth + 20, $contentHeight + 10, $curve, $curve, $cY, 10)}" fill="none" opacity="1" stroke="{$color}" stroke-width="1"/>
                        <xsl:for-each select="$content">
                            <xsl:variable name="precHeight" select="sum(preceding-sibling::*/@height)"/>
                            <g transform="translate(20,{$precHeight + 5})">
                                <xsl:copy-of select="."/>
                            </g>
                        </xsl:for-each>
                    </g>

                </g>
            </svg>
        </sqf:docu>
    </xsl:template>

    <xsl:template match="xs:documentation" mode="svg">
        <xsl:param name="text-width" select="300"/>
        <xsl:variable name="fontSize" select="11"/>

        <xsl:if test="@source or not(preceding-sibling::xs:documentation)">
            <xsl:variable name="title">
                <xsl:call-template name="wrap">
                    <xsl:with-param name="text" select=" if (@source) then (@source) else ('Documentation')"/>
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

    <!--    <xsl:template match="xs:complexType">
        <xsl:param name="position" select="(0,0)" tunnel="yes"/>
        
    </xsl:template>
    
    <xsl:template match="xs:sequence">
        <xsl:param name="position" select="(0,0)" tunnel="yes"/>
        <xsl:variable name="width" select="25"/>
        <g alignment-baseline="baseline" transform="translate({$position[1]}, {$position[2]})">
            <circle r="10" cx="12" cy="12" fill="#ff0000"/>
        </g>
        <xsl:apply-templates>
            <xsl:with-param name="position" select="($position[1] + $width + 50, $position[2])" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="xs:choice">
        <xsl:param name="position" select="(0,0)" tunnel="yes"/>
        <xsl:variable name="width" select="25"/>
        <g alignment-baseline="baseline" transform="translate({$position[1]}, {$position[2]})">
            <circle r="10" cx="12.5" cy="12.5" fill="#00ff00"/>
        </g>
        <xsl:apply-templates>
            <xsl:with-param name="position" select="($position[1] + $width + 50, $position[2])" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>-->

    <xsl:template match="node()" priority="-10" mode="#all">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    <xsl:template match="text()" priority="-5" mode="#all"/>




    <xsl:include href="svg-paths.xsl"/>

</xsl:stylesheet>
