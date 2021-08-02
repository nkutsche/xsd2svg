# xsd2svg API Setup 

## Requirements

* *This package works only with Saxon 10.x.*

## Java & Classpath Adjustments

### Using Maven

[Tbd.]

Meanwhile have a look at the Sample on the [download page](Download.html).

### Without Maven

1. Download the Package *Zip-Package for manual installation* from the [download page](Download.html).
1. Unzip into an empty folder (we call it from now on `${xsd2svg}`).
1. Setup your Saxon call:
    1. Call the Saxon with the xsd2svg configuration `${xsd2svg}/src/com/nkutsche/xsd2svg/saxon/saxon-config.xml` or take over the configurations from this file to yours. Keep in mind, that taking over configurations may need adjustments on relative paths.
    1. Add to the Java classpath the jars in `${xsd2svg}/bin`. If you have your own Saxon, you *must not* add the contained Saxon to your classpath.


## XSLT Adjustments

Add to one of your Stylesheets the following top-level element:

```xml
<xsl:use-package name="http://www.nkutsche.com/xsd2svg" package-version="*"/>
```

If you want to use a [custom configuration file](Usage.html#config) or a [link provider function](Usage.html#link-provider-function), you have to use the overwrite element, like this:

```xml
<xsl:use-package name="http://www.nkutsche.com/xsd2svg" package-version="*">
    <xsl:override>
        <xsl:param name="link-provider-function" select="function($comp){'#' || $comp?id}" as="function(map(xs:string, item()*)) as xs:string?"/>
        <xsl:param name="config" select="doc('path/to/my/config.xml')" as="document-node()?"/>
    </xsl:override>
</xsl:use-package>
```
