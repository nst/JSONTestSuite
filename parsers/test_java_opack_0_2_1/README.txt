javac -cp opack-0.2.1.jar TestJSONParsing.java

jar cvfm TestJSONParsing.jar META-INF/MANIFEST.MF opack-0.2.1.jar TestJSONParsing.class

java -jar TestJSONParsing.jar
