// javac -cp ".:json-20160810.jar" TestJSONParsing.java && java -classpath ".:json-20160810.jar" TestJSONParsing x.json

import java.nio.charset.StandardCharsets;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

public class TestJSONParsing {

    public static boolean isValidJSON(String s) {
        try {
            int idxArray  = s.indexOf('[');
            int idxObject = s.indexOf('{');

            if (idxArray < 0 && idxObject < 0) {
                System.out.println("Not an array or object");
                return false;
            }
            else if (idxObject >= 0 && (idxArray < 0 || idxObject < idxArray)) {
                JSONObject obj = new JSONObject(s);
                System.out.println(obj);
                System.out.println(obj.getClass().getSimpleName());
                return true;
            }
            else {
                JSONArray obj = new JSONArray(s);
                System.out.println(obj);
                System.out.println(obj.getClass().getSimpleName());
                return true;
            }
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
            System.out.println(args[0]);
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
