essential-kson 2.17 (Kotlin multiplatform, JVM artifact from Maven Central: com.republicate.kson:essential-kson-jvm:2.17)
https://github.com/arkanovicz/essential-kson

javac --release 17 -cp "essential-kson-jvm-2.17.jar" TestJSONParsing.java

jar cvfm TestJSONParsing.jar META-INF/MANIFEST.MF TestJSONParsing.class

java -jar TestJSONParsing.jar file.json
