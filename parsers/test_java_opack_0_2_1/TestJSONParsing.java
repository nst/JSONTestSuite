import com.realtimetech.opack.codec.json.Json;
import com.realtimetech.opack.exception.DecodeException;
import com.realtimetech.opack.value.OpackValue;

import java.io.BufferedInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class TestJSONParsing {
    public static String readFileAutoDetect(Path path) throws IOException {
        try (InputStream inputStream = Files.newInputStream(path);
             BufferedInputStream bufferedInputStream = new BufferedInputStream(inputStream)) {

            bufferedInputStream.mark(4);

            byte[] bom = new byte[4];
            int read = bufferedInputStream.read(bom, 0, bom.length);

            Charset encoding;
            int bomLength = 0;

            if (read >= 3 && bom[0] == (byte) 0xEF && bom[1] == (byte) 0xBB && bom[2] == (byte) 0xBF) {
                encoding = StandardCharsets.UTF_8;
                bomLength = 3;
            } else if (read >= 2 && bom[0] == (byte) 0xFE && bom[1] == (byte) 0xFF) {
                encoding = StandardCharsets.UTF_16BE;
                bomLength = 2;
            } else if (read >= 2 && bom[0] == (byte) 0xFF && bom[1] == (byte) 0xFE) {
                encoding = StandardCharsets.UTF_16LE;
                bomLength = 2;
            } else {
                encoding = StandardCharsets.UTF_8;
            }

            bufferedInputStream.reset();
            bufferedInputStream.skip(bomLength);

            return new String(bufferedInputStream.readAllBytes(), encoding);
        }
    }

    public static boolean isValidJSON(String jsonString) {
        try {
            Object object = Json.decodeObject(jsonString);

            System.out.println(object);

            return true;
        } catch (DecodeException exception) {
            exception.printStackTrace();
            return false;
        }
    }

    public static void main(String[] args) {
        if (args.length == 0) {
            System.out.println("Usage: java TestJSONParsing file.json");
            System.exit(2);
        }

        try {
            String jsonString = readFileAutoDetect(Paths.get(args[0]));

            if (isValidJSON(jsonString)) {
                System.out.println("valid");
                System.exit(0);
            }

            System.out.println("invalid");
            System.exit(1);
        } catch (IOException exception) {
            System.out.println("not found");
            System.exit(2);
        }
    }
}
