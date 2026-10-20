// javac --release 17 -cp "essential-kson-jvm-2.17.jar" TestJSONParsing.java

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

import com.republicate.kson.Json;
import com.republicate.kson.JsonException;

public class TestJSONParsing {

    public static boolean isValidJSON(String s) {
        try {
            // parseValue accepts any top-level value (RFC 8259), parse only containers
            Json.Companion.parseValue(s, true);
            return true;
        } catch (JsonException e) {
            System.out.println(e);
            return false;
        }
    }

    public static void main(String[] args) {

        if (args.length == 0) {
            System.out.println("Usage: java TestJSONParsing file.json");
            System.exit(2);
        }

        try {
            String s = new String(Files.readAllBytes(Paths.get(args[0])), StandardCharsets.UTF_8);
            if (isValidJSON(s)) {
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
