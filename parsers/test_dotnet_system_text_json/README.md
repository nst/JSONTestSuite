# Usage

To build and run all tests with only this parser, follow the steps given below:

```sh
git clone https://github.com/nst/JSONTestSuite

RID=linux-x64
# or osx-x64 or win-x64 (according to your platform, until
# there is a platform-agnostic option like: https://github.com/dotnet/cli/issues/12325)
PARSER_DIR=JSONTestSuite/parsers/test_dotnet_system_text_json

dotnet publish -c Release $PARSER_DIR -o $PARSER_DIR -r $RID

echo '[".NET System.Text.Json 4.6.0"]' > dotnet_only.json
python3 JSONTestSuite/run_tests.py --filter=dotnet_only.json
```
