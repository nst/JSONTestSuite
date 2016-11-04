javac -cp ".:json-20160810.jar" TestJSONParsing.java

jar cvfm TestJSONParsing.jar META-INF/MANIFEST.MF json-20160810.jar TestJSONParsing.class

java -jar TestJSONParsing.jar
