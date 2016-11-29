#!/usr/bin/python
import sys

with open(sys.argv[1], 'r') as f:
    json = f.read()

import psycopg2
import psycopg2.errorcodes

conn = psycopg2.connect("")
cur = conn.cursor()
try:
    cur.execute("SELECT %s::jsonb;", (json,))
    result = cur.fetchone()
    exit(0) # allegedly valid json PASS
except psycopg2.Error as e:
    if (e.pgcode[:2] == CLASS_INTERNAL_ERROR):
        print e.pgerror
        exit(2) # unexpected error -- CRASH
    else:
        exit(1) # normal error -- FAIL

    # expected errors are: 
    #
    # INVALID_TEXT_REPRESENTATION (invalid json)
    # CHARACTER_NOT_IN_REPERTOIRE (invalid unicode)
    # UNTRANSLATABLE_CHARACTER (nul unicode code point)
    # STATEMENT_TOO_COMPLEX (nested too deep)
