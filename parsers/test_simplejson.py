#!/usr/bin/env python

import simplejson as json
import sys

#def f_parse_constant(o):
#    raise BaseException

def parse_file(path):

    with open(path, 'r') as f:

        data = f.read()

        try:
            o = json.loads(data)

        except Exception as e:
            sys.exit(1)

if __name__ == "__main__":

    path = sys.argv[1]
    parse_file(path)

    sys.exit(0)

