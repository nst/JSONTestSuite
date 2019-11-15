import com.bfo.json.*;
import java.io.*;
import java.nio.file.*;

public class TestJSONParsing {

    public static boolean isValidJSON(byte[] bytes) {
        try {
            return Json.read(new ByteArrayInputStream(bytes), null) != null;
        } catch (Exception e) {
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
            byte[] bytes = Files.readAllBytes(Paths.get(args[0]));
            if (isValidJSON(bytes)) {
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
