// javac -cp ".:fastjson2-2.0.53.jar" TestJSONParsing.java && java -classpath ".:fastjson2-2.0.53.jar" TestJSONParsing x.json

import java.nio.charset.StandardCharsets;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONException;

public class TestJSONParsing {
    
    public static boolean isValidJSON(String s) {
        try {
            Object obj = JSON.parse(s);
            System.out.println(obj);
            return true;
        } catch (JSONException e) {
            System.out.println(e);
            return false;            
        }
    }

    public static void main(String[] args) {
        
        if(args.length == 0) {
            System.out.println("Usage: java TestJSONParsing file.json");            
            System.exit(2);
        }
        
        try {
            String s = new String(Files.readAllBytes(Paths.get(args[0])));
            if(isValidJSON(s)) {
                System.out.println("valid");
                System.exit(0);            
            }
            System.out.println("invalid");
            System.exit(1);
        } catch (IOException e) {
            System.out.println("not found");
            System.exit(2);
        }   
    }
}
