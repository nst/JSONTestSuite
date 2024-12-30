#!/usr/bin/env python3

import sys
import jsoncgx

if __name__ == "__main__":
    allow_comments = sys.argv[1] == "on"
    path = sys.argv[2]

    try:
        jsoncgx.loadf(path, allow_comments)
    except Exception:
        sys.exit(1)
    sys.exit(0)
