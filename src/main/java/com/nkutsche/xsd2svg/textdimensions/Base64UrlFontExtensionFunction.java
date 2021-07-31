package com.nkutsche.xsd2svg.textdimensions;

import net.sf.saxon.event.SequenceCollector;
import net.sf.saxon.expr.StaticProperty;
import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.ma.map.HashTrieMap;
import net.sf.saxon.om.Item;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.XdmMap;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.AtomicValue;
import net.sf.saxon.value.SequenceType;
import net.sf.saxon.value.StringValue;

import java.awt.*;
import java.io.IOException;
import java.net.URL;
import java.util.HashMap;

import static com.nkutsche.xsd2svg.textdimensions.TextDimensions.TextDimensionConfig;

public class Base64UrlFontExtensionFunction extends ExtensionFunctionDefinition {


    private final StructuredQName funcname = new StructuredQName("nk", "http://www.nkutsche.com/", "font-as-data-url");

    @Override
    public StructuredQName getFunctionQName() {
        return funcname;
    }


    @Override
    public int getMinimumNumberOfArguments() {
        return 1;
    }

    @Override
    public int getMaximumNumberOfArguments() {
        return getArgumentTypes().length;
    }

    @Override
    public SequenceType[] getArgumentTypes() {
        return new SequenceType[]{
                SequenceType.SINGLE_STRING,
                SequenceType.OPTIONAL_STRING
        };
    }

    @Override
    public SequenceType getResultType(SequenceType[] sequenceTypes) {
        return SequenceType.SINGLE_STRING;
    }

    @Override
    public ExtensionFunctionCall makeCallExpression() {
        return new ExtensionFunctionCall() {
            @Override
            public Sequence call(XPathContext xPathContext, Sequence[] args) throws XPathException {

                /* to get result of java processing code, you need a 'outputter' */
                SequenceCollector outputter = xPathContext.getController().allocateSequenceOutputter(50);

                String url = args[0].head().getStringValue();

                String fontType = "truetype";
                if(args.length > 1 && args[1] != null){
                    fontType = value(args[1].head(), fontType);
                }

                try {
                    Base64FontUrl b64fu = new Base64FontUrl(new URL(url), fontType);
                    String dataUrl = b64fu.getDataUrl();

                    outputter.write(new StringValue(dataUrl));
                    return outputter.getSequence();

                } catch (IOException e){
                    throw new XPathException(e);
                }

            }
        };
    }

    private TextDimensionConfig createConfig(HashTrieMap map){
        TextDimensionConfig config = new TextDimensionConfig();
        map.keys().forEach(atomicValue -> {
            config.with(atomicValue.head().getStringValue(), value(map.get((AtomicValue) atomicValue).head()));
        });
        return config;
    }

    private String value(Item item){
        return value(item, null);
    }
    private String value(Item item, String def){
        if(item == null)
            return def;
        return item.getStringValue();
}




}
