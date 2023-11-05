javac -cp ".:nanojson-1.6.jar" TestJSONParsing.java

jar cvfm TestJSONParsing.jar META-INF/MANIFEST.MF nanojson-1.6.jar TestJSONParsing.class

java -jar TestJSONParsing.jar
