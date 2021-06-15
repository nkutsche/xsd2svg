package de.data2type.je.textdimensions;


import java.awt.*;
import java.awt.font.FontRenderContext;
import java.awt.geom.AffineTransform;
import java.awt.geom.Rectangle2D;
import java.util.Arrays;
import java.util.HashMap;


public class TextDimensions {

    private final TextDimensionConfig config;

    public static class TextDimensionConfig {
        private HashMap<TDCfgF, String> values = new HashMap<>();

        public TextDimensionConfig with(String field, String value){
            values.put(TDCfgF.valueOf(field), value);
            return this;
        }
        public String get(TDCfgF type){
            return values.get(type);
        }
        public boolean has(TDCfgF type){
            return values.containsKey(type);
        }
        private Font createFont(){
            String ff = get(TDCfgF.font);
            double sz = Double.parseDouble(get(TDCfgF.size));
            int st = getType(get(TDCfgF.style));
            Font font = new Font(ff, st, (int) sz);
            font = font.deriveFont((float) sz);
            return font;
        }

        public boolean ptTargetUnit() {
            if(has(TDCfgF.unit)){
                return "pt".equals(get(TDCfgF.unit).toLowerCase());
            }
            return false;
        }
    }

    public enum TDCfgF {font, size, style, unit}

    public TextDimensions(TextDimensionConfig config){
        this.config = config;
    }

    public HashMap<String, Double> getTextDimensions(String text){
        return getTextDimensions(text, config.createFont());

    }
    private HashMap<String, Double> getTextDimensions(String text, Font font){
        AffineTransform affinetransform = new AffineTransform();
        FontRenderContext frc = new FontRenderContext(affinetransform,true,true);
        Rectangle2D bounds = font.getStringBounds(text, frc);
        HashMap<String, Double> result = new HashMap<>();

        double w = bounds.getWidth();
        double h = bounds.getHeight();

        if(!config.ptTargetUnit()){
            w = pt2mm(w);
            h = pt2mm(h);
        }

        result.put("width", w);
        result.put("height", h);

        return result;
    }

    private static double pt2mm(double pt){
        return pt / 72.0 * 25.4;
    }

    public enum Types {PLAIN, BOLD, ITALIC}

    public static int getType(String type){

        if (type == null)
            return getDefaultType();

        type = type.toUpperCase();

        boolean convertAble = Arrays.stream(Types.values()).map(Types::name).anyMatch(type::equals);

        if(!convertAble){
            return getDefaultType();
        }

        Types typeEnum = Types.valueOf(type);
        switch (typeEnum){
            case BOLD:
                return Font.BOLD;
            case ITALIC:
                return Font.ITALIC;
            case PLAIN:
                return Font.PLAIN;
            default:
                return getDefaultType();
        }
    }
    public static int getDefaultType(){
        return Font.PLAIN;
    }
}