#!/usr/bin/env python

import demjson as json
import sys

def parse_file_intrinsically(path):
    try:
        o = json.decode_file(path, strict=True)

    except Exception as e:
        raise
        sys.exit(1)
    return

def parse_file(path):
    with open(path, 'rb') as f:

        data = f.read()

        try:
            o = json.decode(data, strict=True)

        except Exception as e:
            raise
            sys.exit(1)

if __name__ == "__main__":

    path = sys.argv[1]
    parse_file_intrinsically(path)

    sys.exit(0)

