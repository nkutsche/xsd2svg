package de.data2type.je.textdimensions;


import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URL;
import java.util.Base64;
import org.apache.commons.io.IOUtils;

public class Base64FontUrl {

    private final URL fontUrl;
    private final String type;

    public Base64FontUrl(URL fontUrl) {
        this(fontUrl, "truetype");
    }
    public Base64FontUrl(URL fontUrl, String type) {
        this.fontUrl = fontUrl;
        this.type = type;
    }


    public String getDataUrl() throws IOException {

        InputStream inputStream = fontUrl.openStream();
        byte[] dataBytes = IOUtils.toByteArray(inputStream);
        String data = Base64.getEncoder().encodeToString(dataBytes);


        return "data:application/font-" + type + ";charset=utf-8;base64," + data;
    }
}
