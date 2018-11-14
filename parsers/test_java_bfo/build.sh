#!/bin/sh
javac -cp bfojson-1.jar:. TestJSONParsing.java
jar cfvm TestJSONParsing.jar META-INF/MANIFEST.MF TestJSONParsing.class bfojson-1.jar
