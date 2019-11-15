// javac -cp ".:json-mergebase-2019.09.09.jar" TestJSONParsing.java && java -classpath ".:json-mergebase-2019.09.09.jar" TestJSONParsing x.json

import com.mergebase.util.Java2Json;
import java.nio.charset.StandardCharsets;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class TestJSONParsing {
    
    public static boolean isValidJSON(String s) {
        try {
            Object obj = Java2Json.parse(s);
        } catch (Throwable t) {
            System.out.println(t);
            return false;
        }
        return true;
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
