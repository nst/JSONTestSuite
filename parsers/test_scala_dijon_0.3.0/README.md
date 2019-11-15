### To build from sources

Install JDK and sbt, then run following command

```sh
sbt clean assembly
```

### To run

```sh
java -jar target/scala-2.13/TestJSONParsing.jar <test_case_file>
```
