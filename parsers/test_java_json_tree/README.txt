javac -cp ".:json-tree-0.5.0.jar" TestJSONParsing.java

jar cvfm TestJSONParsing.jar META-INF/MANIFEST.MF json-tree-0.5.0.jar TestJSONParsing.class

java -jar TestJSONParsing.jar
