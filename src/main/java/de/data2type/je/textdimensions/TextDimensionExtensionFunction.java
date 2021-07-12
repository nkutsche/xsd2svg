package de.data2type.je.textdimensions;

import net.sf.saxon.event.SequenceCollector;
import net.sf.saxon.expr.StaticProperty;
import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.ma.map.HashTrieMap;
import net.sf.saxon.om.GroundedValue;
import net.sf.saxon.om.Item;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.s9api.ItemType;
import net.sf.saxon.s9api.XdmMap;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.AtomicValue;
import net.sf.saxon.value.SequenceType;

import java.awt.*;
import java.io.IOException;
import java.util.HashMap;

import static de.data2type.je.textdimensions.TextDimensions.*;

public class TextDimensionExtensionFunction extends ExtensionFunctionDefinition {


    private final StructuredQName funcname = new StructuredQName("es", "http://www.escali.schematron-quickfix.com/", "textdimensions");

    @Override
    public StructuredQName getFunctionQName() {
        return funcname;
    }

    @Override
    public SequenceType[] getArgumentTypes() {
        return new SequenceType[]{
                SequenceType.SINGLE_STRING,
                new SequenceType(ItemType.ANY_MAP.getUnderlyingItemType(), StaticProperty.EXACTLY_ONE)
        };
    }

    @Override
    public SequenceType getResultType(SequenceType[] sequenceTypes) {
        return new SequenceType(ItemType.ANY_MAP.getUnderlyingItemType(), StaticProperty.EXACTLY_ONE);
    }

    @Override
    public ExtensionFunctionCall makeCallExpression() {
        return new ExtensionFunctionCall() {
            @Override
            public Sequence call(XPathContext xPathContext, Sequence[] args) throws XPathException {

                /* to get result of java processing code, you need a 'outputter' */
                SequenceCollector outputter = xPathContext.getController().allocateSequenceOutputter(50);

                String text = args[0].head().getStringValue();
                TextDimensionConfig config = createConfig((HashTrieMap) args[1]);
                try {

                    HashMap<String, Double> map = new TextDimensions(config).getTextDimensions(text);
    
                    outputter.write(XdmMap.makeMap(map).getUnderlyingValue());
                    return outputter.getSequence();

                } catch (FontFormatException | IOException e){
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
        if(item == null)
            return null;
        return item.getStringValue();
}




}
