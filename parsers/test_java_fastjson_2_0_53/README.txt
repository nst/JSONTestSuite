javac -cp ".:fastjson2-2.0.53.jar" TestJSONParsing.java

jar cvfm TestJSONParsing.jar META-INF/MANIFEST.MF fastjson2-2.0.53.jar TestJSONParsing.class

java -jar TestJSONParsing.jar
