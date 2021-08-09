# xsd2svg API Usage

This page describes how to use the xsd2svg API. This requires a [successful setup](Setup.html).

## Namespace

To call the API functions add the following namespace declaration to your stylesheets:

```xml
xmlns:xsd2svg="http://www.xsd2svg.nkutsche.com/"
```

## Functions

### `xsd2svg:getMasterFiles`

The function `xsd2svg:getMasterFiles` returns a sequence of URIs of files which are identified as *XSD master file* in an *extended XSD file set*. 

A **master file** is an XSD file which are not included (not imported!) by another XSD file in a set of XSD files.  

An **extended XSD file set** is the union of a *basic XSD file set* and all XSD files which are imported or included directly and indirectly by one XSD in the *basic XSD file set*. 

The **basic XSD file set** are all XSD files which are found evaluating the parameters `$path` `$extension` and `$recusrive`. 


#### Parameter

| Name | Short Description | Type | Default | Required |
|---|---|---|---|---|
| `path` | Directory searching for XSD files. | `xs:string` | `-` | `yes` |
| `extension` | File name extension identifying XSD files  | `xs:string` | `xsd` | `no` |
| `recursive` | Searching recursive for files in sub folders or not.  | `true` | `xs:boolean` | `no` |

#### Return value

Type: `xs:anyURI*`

A sequence of abolute URIs pointing to XSD master files.



### `xsd2svg:getSchemaInfo`

The function `xsd2svg:getSchemaInfo` receives an URI of an XSD file and returns a SchemaInfo object map (see below).

#### Parameter

| Name | Short Description | Type | Default | Required |
|---|---|---|---|---|
| `schema-url` | URI identifying an XSD file. | `xs:anyURI` | `-` | `yes` |

#### Return value

Type: `map(*)`

An instance of a SchemaInfo object map.


### `xsd2svg:svg-model`

This function creates from an XSD main component (`$xsdnode`) a SVG Content Model Graphic. This SVG graphic describes the content model and the parents of the given XSD main component. The parameter `$standalone` indicates whether the generated SVG should include all neccassary CSS (`true()`) or not (`false()`). The XSD component have to match the described restrictions of Main Components (see below).

#### Parameter

| Name | Short Description | Type | Default | Required |
|---|---|---|---|---|
| `xsdnode` | An XSD component definition element. | `element()` | `-` | `yes` |
| `standalone` | File name extension identifying XSD files  | `xs:boolean` | `-` | `yes` |

#### Return value

Type: `node()*`

The root nodes of a generated SVG Model Graphic.

## Object Maps

### SchemaInfo

The SchemaInfo Object Map is a XPath map describing the content of an XSD schema structure, based on a set of ComponentInfo Object Maps of all XSD Main Components. The map contains the following entries:


| Key | Short Description | Type | 
|---|---|---|---|---|
| `schema-namespace-map` | A sub map associating the found target namespaces in the XSD schema structure with a sequence of the XSD root element of each XSD schema which is part of the XSD structure and bejoined to this target namespace. | `map(xs:string, document-node(element(xs:schema))*)` |
| `create-css` | A function which with no parematers. The return value is a CSS stylesheet styling the generated SVG Model Graphics. Can be used to embed it into an HTML document. | `function() as xs:string?` |
| `get-grouped-components` | A function with one parameter `$grouping`, expecting a sequence of strings. The function groups Component Info Object Map set depending on grouping criterias given by the `$grouping` parameter value and returns a nested map structure. Possible grouping criteria values are `namespace`, `type` and `scope`, refering the keys of the ComponentInfo Object Maps (see below). | `function(xs:string*) as map(xs:string, item()*)` |
| `namespaces` | A sequence of all distinct values of the `namespace` entries in the ComponentInfo Object Maps set. | `xs:string*` |
| `types` | A sequence of all distinct values of the `type` entries in the ComponentInfo Object Maps set. | `xs:string*` |
| `qnames` | A sequence of all distinct values of the `qname` entries in the ComponentInfo Object Maps set. | `xs:QName*` |
| `print-qname` | A function receives a QName as the first argument and returns a string representing this QName. The representation will be the same as it would be in the SVG Model Graphics. | `xs:string` |
| `components-by-id` | A map containing for each ComponentInfo Object Map an entry with the `id` as key and the ComponentInfo Object Map as value. | `map(xs:string, map(xs:string, item()*))` |
| `find-reference` | A function receives as the only argument an XSD referencing attribute (`@ref`, `@type`, `@base`, etc.) and returns a (sequence of) ComponentCoreInfo Object Map of all referenced types (usually only one). In case of a reference to a primitive type, a pseudo ComponentCoreInfo Object Map is returned, describing the primitive data type. | `function(attribute()) as map(xs:string, item()*)*` |

### ComponentCoreInfo

The ComponentCoreInfo Object Map describes a given XSD main component with some identification informations by the following entries:

| Key | Short Description | Type | 
|---|---|---|---|---|
| `id` | A unique ID for the given XSD main component. | `xs:string` |
| `component` | The XSD element declaring the given XSD main component. | `xs:string` |
| `type` | The local name of the component element. | `xs:string` |
| `namespace` | The target namespace for the given XSD main component. | `xs:string` |
| `scope` | A key word indicating whether the given XSD main component was declared on top level (`global`) or nested in other components (`local`).  | `xs:string` |
| `qname` | The QName identifying the XSD main component. | `xs:QName` |


### ComponentInfo

The ComponentInfo Object Map extends the ComponentCoreInfo Object Map by the following entries:

| Key | Short Description | Type | 
|---|---|---|---|---|
| `used-by` | The ComponentCoreInfo Object Maps of all XSD main components which are refering the given XSD main component. | `map(xs:string, item()*)*` |
| `uses` | The ComponentCoreInfo Object Maps of all XSD main components which are refered by the given XSD main component. | `map(xs:string, item()*)*` |
| `nested` | The ComponentCoreInfo Object Maps of all XSD main components which are nested by the given XSD main components. | `map(xs:string, item()*)*` |
| `nested-by` | If the given XSD main component is nested by another XSD main component, this entry contains the ComponentCoreInfo Object Map of the next ancestor component. | `map(xs:string, item()*)?` |
| `get-svg-model` | A function creates the SVG Model Graphic for the XSD main component. The only argument `$standalone` indicates whether the returned SVG Model Graphic should contain all necessary CSS stylesheets or not. | `function(xs:boolean) as node()*` |


## Global Parameter

### `config`

The document root node of the configuration XML file.

### `link-provider-function`

A function matching to the signature `function(map(xs:string, item()*)) as xs:string?`. This function will receive a ComponentCoreInfo Object Map and returns a string or an empty sequence.

This function is called every time when the XSD2SVG library should create a link for a referenced Component. The ComponentCoreInfo Object Map describes the target Component. If the function returns a string it will create an SVG link by this string. If the function returns an empty sequence it will not create a link.

## Configuration

The configuration file is XML based and has to be valid against this [RelaxNG schema](../../main/resources/com/nkutsche/xsd2svg/rnc/config.rnc).

### Font Configuration

There are two different kind of text in the generated SVG Model Graphics. The configuration element `emphasis` configures the font of emphasized text like headings or main components. The element `main` configures the font of regular text - all other shown text.

There are to ways to configure a font:

#### By Font File

```xml
<fonts>
    <emphasis href="font/Roboto-Bold.ttf" name="Roboto Bold" type="truetype"/>
    <main href="font/Roboto-Regular.ttf" name="Roboto" type="truetype"/>
</fonts>
```

The `href` attributes references a font file in format TrueType (ttf) or WOFF. The `name` attributes is used to reference the given font in the custom CSS. The `type` attribute should match with the values `truetype` or `woff` to the format of the given fonts.

#### By Name Reference

```xml
<fonts>
    <emphasis name="Arial" style="bold"/>
    <main name="Arial" style="regular"/>
</fonts>
```

The `name` attribute reference with its value to an installed font. With the `style` attribute a font style can be choosen. Please note that this way is *not recommanded* in the most cases (see below).

#### Why do I need to configure the font separately?

The SVG format is not designed to make a proper text rendering graphics. As the generated graphics contains content dependent text, the generator needs to know the final dimensions of the text representations (after rendering) during the generation of the SVG Model Graphics. For this it is required to provide the used font for rendering the SVG graphics.

#### Why it is recommended to provide a font file?

Usually the rendering of the SVG files is done on client side (e.g. in a browser). In the SVG Model Graphics we want create it is important that the renderer uses the same font, as the generator has assumed (see above). If the the rendering system has the requested font not installed, it will use a fallback font and the SVG graphics may have space conflicts.

If the configured fonts are provided as font files (e.g. TTF file), these files will be embedded into the CSS of the generated files and all renderer should be able to use the correct font.

If the configuration just reference a font by the name, it is required that the SVG renderer has installed that font as well. This will lead to no issues if the SVG renderer is known.


### Custom CSS

A custom CSS can be added by:

```xml
<css href="custom.css"/>
```

The content of the provided CSS file will be added at the end of the generated CSS.

### Specific Prefix Bindings

For the QNames which are described in the SVG Model graphics the XSD2SVG library will use a static prefix binding to reference the used namespaces. By default the XSD2SVG library will look into the given XSD files and searches for namespace declarations for the given target namespaces to create such a prefix binding. If there is no namespace declaration for a given target namespace or all of them has no prefix it will generate a generic prefix. The library also checks that the prefix is unique and can be associated with a single namespace.

To make a custom specification for all or some target namespaces the configuration file can have an own prefix binding, like this:

```
<namespaces>
    <namespace prefix="nk" uri="http://www.nkutsche.com/xsd2svg"/>
    <namespace prefix="xsd2svg" uri="http://www.xsd2svg.nkutsche.com/"/>
</namespaces>
```

The library will use this prefix binding as base and generate prefixes only for target namespaces which are not covered by this binding. 

## XSD support/Restrictions

This section describes the XSD support of the XSD2SVG library. 

### Main Components

For the following components this libary is able to create SVG Model graphics:

* `xs:element`
* `xs:attribute`
* `xs:complexType`
* `xs:simpleType`
* `xs:group`
* `xs:attributeGroup`

In addition the following restrictions applies:

* All components needs to be named (by a `name` attribute).

### Content Support

The following list shows all XSD elements which are supported by this library:  

* `xs:annotation`
* `xs:attribute`
* `xs:element`
* `xs:group`
* `xs:attributeGroup`
* `xs:complexType`
* `xs:complexContent`
* `xs:simpleContent`
* `xs:extension`
* `xs:restriction`
* `xs:sequence`
* `xs:choice`
* `xs:all`
* `xs:union`
* `xs:list`
* `xs:any`
* `xs:length`
* `xs:pattern`
* `xs:maxLength`
* `xs:minLength`
* `xs:whiteSpace`
* `xs:fractionDigits`
* `xs:totalDigits`
* `xs:maxExclusive`
* `xs:maxInclusive`
* `xs:minInclusive`
* `xs:minExclusive`
* `xs:enumeration`
* `xs:documentation`

Any other element may are ignored.

### Parenthood Recognization

In the following cases a Parenthood is detected for a main component:

* A named component contains a reference using `@ref` attribute to the main component.
* The main component is a nested declaration inside of a named component (`xs:element` or `xs:complexType`).
* A named component (`xs:element` or `xs:attribute`) references the main component using `@type` attribute.  
