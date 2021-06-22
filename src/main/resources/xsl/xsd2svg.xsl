<?xml version="1.0" encoding="UTF-8"?>
<xsl:package xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:es="http://www.escali.schematron-quickfix.com/" 
    xmlns:svg="http://www.w3.org/2000/svg" 
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xsd2svg="http://www.xsd2svg.schematron-quickfix.com/"
    xmlns="http://www.w3.org/2000/svg"
    exclude-result-prefixes="#all"
    version="3.0"
    package-version="1.0.0-SNAPSHOT"
    name="http://www.escali.schematron-quickfix.com/xsd2svg"
    >
    
    
    <xsl:import href="xsd2svg_api.xsl"/>
    
    
    <xsl:expose names="xsd2svg:*" component="*" visibility="final"/>
    
    
    
    
</xsl:package>