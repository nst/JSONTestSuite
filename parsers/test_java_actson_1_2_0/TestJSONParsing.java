import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import de.undercouch.actson.JsonEvent;
import de.undercouch.actson.JsonParser;

public class TestJSONParsing {
    public static boolean isValidJSON(byte[] bytes) {
        JsonParser parser = new JsonParser();
        int i = 0;
        int event;
        do {
            while ((event = parser.nextEvent()) == JsonEvent.NEED_MORE_INPUT) {
                i += parser.getFeeder().feed(bytes, i, bytes.length - i);
                if (i == bytes.length) {
                    parser.getFeeder().done();
                }
            }
            if (event == JsonEvent.ERROR) {
                return false;
            }
        } while (event != JsonEvent.EOF);
        return true;
    }

    public static void main(String[] args) {
        if (args.length == 0) {
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
