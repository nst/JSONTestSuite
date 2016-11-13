
# Rebuild with: nim c -d:release test_json.nim

import json
import os

let fn = os.paramStr(1)

try:
  discard fn.readFile().parseJson()
  quit(0)
except:
  quit(1)
