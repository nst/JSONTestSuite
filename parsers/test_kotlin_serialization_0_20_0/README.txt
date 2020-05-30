kotlinc -no-reflect -include-runtime -cp ".:kotlinx-serialization-runtime-0.20.0.jar" TestJSONParsing.kt && \
    jar uvf TestJSONParsing.jar kotlinx-serialization-runtime-0.20.0.jar

java -jar TestJSONParsing.jar file.json
