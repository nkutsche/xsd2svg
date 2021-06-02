<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    exclude-result-prefixes="xs sqf"
    version="2.0">
    <xsl:output indent="yes"/>
    <!-- 
        copies all nodes:
    -->
    <xsl:template match="node() | @*" mode="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@sqf:*[not(local-name()=('width', 'height'))]"/>
    
</xsl:stylesheet>