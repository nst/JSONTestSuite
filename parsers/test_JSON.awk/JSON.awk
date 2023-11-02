#!/usr/bin/awk -f
#
# Software: JSON.awk - a practical JSON parser written in awk
# Version: 1.4.1
# Copyright (c) 2013-2020, step
# License: MIT or Apache 2
# Project home: https://github.com/step-/JSON.awk
# Credits:      https://github.com/step-/JSON.awk#credits

# See README.md for full usage instructions.
# Usage:
#   awk [-v Option="value"...] -f JSON.awk "-" -or- Filepath [Filepath...]
#   printf "%s\n" Filepath [Filepath...] | awk [-v Option="value"...] -f JSON.awk
# Options: (default value in braces)
#    BRIEF=: 0 or M {1}:
#      non-zero excludes non-leaf nodes (array and object) from stdout; bit
#      mask M selects which to include of ""(1), "[]"(2) and "{}"(4), or
#      excludes ""(8) and wins over bit 1. BRIEF=0 includeѕ all.
#   STREAM=: 0 or 1 {1}:
#      zero hooks callbacks into parser and stdout printing.
#   STRICT=: 0,1,2 {0}:
#      1 enforce RFC8259#7 character escapes except for solidus '/'
#      2 enforce solidus escape too (for JSON embedded in HTML/XML)

BEGIN { #{{{1
	if (BRIEF  == "") BRIEF=1  # when 1 parse() omits non-leaf nodes from stdout
	if (STREAM == "") STREAM=1 # when 0 parse() stores JPATHS[] for callback cb_jpaths
	if (STRICT == "") STRICT=1 # when 1 parse() enforces valid character escapes (RFC8259 7)

	# Set if empty string/array/object go to stdout and cb_jpaths when BRIEF>0
	# defaults compatible with version up to 1.2
	NO_EMPTY_STR = 0; NO_EMPTY_ARY = NO_EMPTY_OBJ = 1
	#  leaf             non-leaf       non-leaf

	if (BRIEF > 0) { # parse() will look at NO_EMPTY_*
		NO_EMPTY_STR = !(x=bit_on(BRIEF, 0))
		NO_EMPTY_ARY = !(x=bit_on(BRIEF, 1))
		NO_EMPTY_OBJ = !(x=bit_on(BRIEF, 2))
		if (x=bit_on(BRIEF, 3)) NO_EMPTY_STR = 1 # wins over bit 0
	}

	# for each input file:
	#   TOKENS[], NTOKENS, ITOKENS - tokens after tokenize()
	#   JPATHS[], NJPATHS - parsed data (when STREAM=0)
	# at script exit:
	#   FAILS[] - maps names of invalid files to logged error lines
	delete FAILS
	reset()

	if (1 == ARGC) {
		# file pathnames from stdin
		# usage: echo -e "file1\nfile2\n" | awk -f JSON.awk
		# usage: { echo; cat file1; } | awk -f JSON.awk
		while (getline ARGV[++ARGC] < "/dev/stdin") {
			if (ARGV[ARGC] == "")
				break
		}
	} # else usage: awk -f JSON.awk file1 [file2...]

	# set file slurping mode
	srand(); RS="\1n/o/m/a/t/c/h" rand()
}

{ # main loop: process each file in turn {{{1
	reset() # See important application note in reset()

	++FILEINDEX # 1-based
	tokenize($0) # while(get_token()) {print TOKEN}
	if (0 == parse() && 0 == STREAM) {
		# Pass the callback an array of jpaths.
		cb_jpaths(JPATHS, NJPATHS)
	}
}

END { # process invalid files {{{1
	if (0 == STREAM) {
		# Pass the callback an associative array of failed objects.
		cb_fails(FAILS, NFAILS)
	}
	exit(NFAILS > 0)
}

function bit_on(n, b) { #{{{1
# Return n & (1 << b) for b>0 n>=0 - for awk portability
	if (b == 0) return n % 2
	return int(n / 2^b) % 2
}

function append_jpath_component(jpath, component) { #{{{1
	if (0 == STREAM) {
		return cb_append_jpath_component(jpath, component)
	} else {
		return (jpath != "" ? jpath "," : "") component
	}
}

function append_jpath_value(jpath, value) { #{{{1
	if (0 == STREAM) {
		return cb_append_jpath_value(jpath, value)
	} else {
		return sprintf("[%s]\t%s", jpath, value)
	}
}

function get_token() { #{{{1
# usage: {tokenize($0); while(get_token()) {print TOKEN}}

	# return getline TOKEN # for external tokenizer

	TOKEN = TOKENS[++ITOKENS] # for internal tokenize()
	return ITOKENS < NTOKENS  # 1 if more tokens to come
}

function parse_array_empty(jpath) { #{{{1
	if (0 == STREAM) {
		return cb_parse_array_empty(jpath)
	}
	return "[]"
}

function parse_array_enter(jpath) { #{{{1
	if (0 == STREAM) {
		cb_parse_array_enter(jpath)
	}
}

function parse_array_exit(jpath, status) { #{{{1
	if (0 == STREAM) {
		cb_parse_array_exit(jpath, status)
	}
}

function parse_array(a1,   idx,ary,ret) { #{{{1
	idx=0
	ary=""
	get_token()
#	print "parse_array(" a1 ") TOKEN=" TOKEN >"/dev/stderr"
	if (TOKEN != "]") {
		while (1) {
			if (ret = parse_value(a1, idx)) {
				return ret
			}
			idx=idx+1
			ary=ary VALUE
			get_token()
			if (TOKEN == "]") {
				break
			} else if (TOKEN == ",") {
				ary = ary ","
			} else {
				report(", or ]", TOKEN ? TOKEN : "EOF")
				return 2
			}
			get_token()
		}
		CB_VALUE = sprintf("[%s]", ary)
		# VALUE="" marks non-leaf jpath
		VALUE = 0 == BRIEF ? CB_VALUE : ""
	} else {
		VALUE = CB_VALUE = parse_array_empty(a1)
	}
	return 0
}

function parse_object_empty(jpath) { #{{{1
	if (0 == STREAM) {
		return cb_parse_object_empty(jpath)
	}
	return "{}"
}

function parse_object_enter(jpath) { #{{{1
	if (0 == STREAM) {
		cb_parse_object_enter(jpath)
	}
}

function parse_object_exit(jpath, status) { #{{{1
	if (0 == STREAM) {
		cb_parse_object_exit(jpath, status)
	}
}

function parse_object(a1,   key,obj) { #{{{1
	obj=""
	get_token()
#	print "parse_object(" a1 ") TOKEN=" TOKEN >"/dev/stderr"
	if (TOKEN != "}") {
		while (1) {
			if (TOKEN ~ /^".*"$/) {
				key=TOKEN
			} else {
				report("string", TOKEN ? TOKEN : "EOF")
				return 3
			}
			get_token()
			if (TOKEN != ":") {
				report(":", TOKEN ? TOKEN : "EOF")
				return 4
			}
			get_token()
			if (parse_value(a1, key)) {
				return 5
			}
			obj=obj key ":" VALUE
			get_token()
			if (TOKEN == "}") {
				break
			} else if (TOKEN == ",") {
				obj=obj ","
			} else {
				report(", or }", TOKEN ? TOKEN : "EOF")
				return 6
			}
			get_token()
		}
		CB_VALUE = sprintf("{%s}", obj)
		# VALUE="" marks non-leaf jpath
		VALUE = 0 == BRIEF ? CB_VALUE : ""
	} else {
		VALUE = CB_VALUE = parse_object_empty(a1)
	}
	return 0
}

function parse_value(a1, a2,   jpath,ret,x,reason) { #{{{1
	jpath = append_jpath_component(a1, a2)
#	print "parse_value(" a1 "," a2 ") TOKEN=" TOKEN " jpath=" jpath >"/dev/stderr"

	if (TOKEN == "{") {
		parse_object_enter(jpath)
		if (parse_object(jpath)) {
			parse_object_exit(jpath, 7)
			return 7
		}
		parse_object_exit(jpath, 0)
	} else if (TOKEN == "[") {
		parse_array_enter(jpath)
		if (ret = parse_array(jpath)) {
			parse_array_exit(jpath, ret)
			return ret
		}
		parse_array_exit(jpath, 0)
	} else if (TOKEN == "") { #test case 20150410 #4
		report("value", "EOF")
		return 8
	} else if ((x = is_value(TOKEN)) >0) {
		CB_VALUE = VALUE = TOKEN
	} else {
		if (-1 == x || -2 == x) {
			reason = "missing or invalid character escape"
		}
		report("value", TOKEN, reason)
		return 9
	}

	# jpath=="" occurs on starting and ending the parsing session.
	# VALUE=="" is set on parsing a non-empty array or a non-empty object.
	# Either condition is a reason to discard the parsed jpath if BRIEF>0.
	if (0 < BRIEF && ("" == jpath || "" == VALUE)) {
		return 0
	}

	# BRIEF>1 is a bit mask that selects if an empty string/array/object is passed on
	if (0 < BRIEF && (NO_EMPTY_STR && VALUE=="\"\"" || NO_EMPTY_ARY && VALUE=="[]" || NO_EMPTY_OBJ && VALUE=="{}")) {
		return 0
	}

	x = append_jpath_value(jpath, VALUE)
	if(0 == STREAM) {
		# save jpath+value for cb_jpaths
		JPATHS[++NJPATHS] = x
	} else {
		# consume jpath+value directly
		print x
	}
	return 0
}

function parse(   ret) { #{{{1
	get_token()
	if (ret = parse_value()) {
		return ret
	}
	if (get_token() || "" != TOKEN) {
		report("EOF", TOKEN)
		return 10
		# TODO the next JSON text starts here.
	}
	return 0
}

function report(expected, got, extra,   i,from,to,context) { #{{{1
	from = ITOKENS - 10; if (from < 1) from = 1
	to = ITOKENS + 10; if (to > NTOKENS) to = NTOKENS
	for (i = from; i < ITOKENS; i++)
		context = context sprintf("%s ", TOKENS[i])
	context = context "<<" got ">> "
	for (i = ITOKENS + 1; i <= to; i++)
		context = context sprintf("%s ", TOKENS[i])
	scream("expected <" expected "> but got <" got "> (length " length(got) (extra ? ", "extra :"") ") at input token " ITOKENS "\n" context)
}

function reset() { #{{{1
# Application Note:
# If you need to build JPATHS[] incrementally from multiple input files:
# 1) Comment out below:        delete JPATHS; NJPATHS=0
#    otherwise each new input file would reset JPATHS[].
# 2) Move the call to apply() from the main loop to the END statement.
# 3) In the main loop consider adding code that deletes partial JPATHS[]
#    elements that would result from parsing invalid JSON files.
# Compatibility Note:
# 1) Very old gawk versions: replace 'delete JPATHS' with 'split("", JPATHS)'.

	TOKEN=""; delete TOKENS; NTOKENS=ITOKENS=0
	delete JPATHS; NJPATHS=0
	CB_VALUE = VALUE = ""
}

function scream(msg) { #{{{1
	NFAILS += (FILENAME in FAILS ? 0 : 1)
	FAILS[FILENAME] = FAILS[FILENAME] (FAILS[FILENAME]!="" ? "\n" : "") msg
	if(0 == STREAM) {
		if(cb_fail1(msg)) {
			print FILENAME ": " msg >"/dev/stderr"
		}
	} else {
		print FILENAME ": " msg >"/dev/stderr"
	}
}

function tokenize(a1) { #{{{1
# usage A: {for(i=1; i<=tokenize($0); i++) print TOKENS[i]}
# see also get_token()

# Pattern string summary with adjustments:
# - replace strings with regex constant; https://github.com/step-/JSON.awk/issues/1
# - reduce [:cntrl:] to [\000-\037]; https://github.com/step-/JSON.awk/issues/5
# - reduce [:space:] to [ \t\n\r]; https://tools.ietf.org/html/rfc8259#page-5 ws
# - replace {4} quantifier with three [0-9a-fA-F] for mawk; https://unix.stackexchange.com/a/506125
# - BOM encodings UTF-8, UTF16-LE and UTF-BE; https://en.wikipedia.org/wiki/Byte_order_mark#Byte_order_marks_by_encoding
# ----------
# 	TOKENS  = BOM "|" STRING "|" NUMBER "|" KEYWORD "|" SPACE "|."
# 	BOM     = "^\357\273\277|^\377\376|^\376\377"
# 	STRING  = "\"" CHAR "*(" ESCAPE CHAR "*)*\""
# 	ESCAPE  = "(\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})"
# 	CHAR    = "[^[:cntrl:]\\\"]"
# 	NUMBER  = "-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?"
# 	KEYWORD = "null|false|true"
# 	SPACE   = "[[:space:]]+"

	gsub(/^\357\273\277|^\377\376|^\376\377|"[^"\\\000-\037]*((\\[^u\000-\037]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])[^"\\\000-\037]*)*"|-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?|null|false|true|[ \t\n\r]+|./, "\n&", a1)
	gsub("\n" "[ \t\n\r]+", "\n", a1)
	# ^\n BOM?
	sub(/^\n((\357\273\277|\377\376|\376\377)\n)?/, "", a1)
	ITOKENS=0 # get_token() helper
	return NTOKENS = split(a1, TOKENS, /\n/)
}

function is_value(a1) { #{{{1
	# Return 0(malformed <value>) <0(<value> but !strict content) >0(pass)

	# STRING | NUMBER | KEYWORD
	if(!STRICT)
		return a1 ~ /^("[^"\\\000-\037]*((\\[^u\000-\037]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])[^"\\\000-\037]*)*"|-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?|null|false|true)$/

	# STRICT is on
	# unescaped = %x20-21 / %x23-5B / %x5D-10FFFF
	# Characters in a STRING are restricted as follows (RFC8259):
	# All Unicode characters may be placed within the quotation marks, except for the characters that MUST be escaped:
	# quotation mark, reverse solidus, and the control characters (U+0000 through U+001F).
	# Any character may be escaped with \uXXXX, alternatively, with the following two-character escapes:
	# %x75 4HEXDIG    ; uXXXX                U+XXXX
	# %x22 /          ; "    quotation mark  U+0022
	# %x5C /          ; \    reverse solidus U+005C
	# %x62 /          ; b    backspace       U+0008
	# %x66 /          ; f    form feed       U+000C
	# %x6E /          ; n    line feed       U+000A   removed by tokenizer
	# %x72 /          ; r    carriage return U+000D   removed by tokenizer
	# %x2F /          ; /    solidus         U+002F   enforced only when STRICT >1
	# %x74 /          ; t    tab             U+0009   removed by tokenizer

	# NUMBER | KEYWORD
	if (1 != index(a1, "\"")) {
		return a1 ~ /^(-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?|null|false|true)$/
	}
	# invalid STRING
	if (a1 !~ /^("[^"\\\000-\037]*((\\[^u\000-\037]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])[^"\\\000-\037]*)*")$/) {
		return 0
	}
	a1 = substr(a1, 2, length(a1) -2)

	# STRICT 1: allowed character escapes
	gsub(/\\["\\\/bfnrt]|\\u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]/, "", a1)
	# STRICT 1: unescaped quotation-mark, reverse solidus and control characters
	if (a1 ~ /["\\\000-\037]/) {
		return -1
	}
	# STRICT 2: unescaped solidus
	if (STRICT > 1 && index(a1, "/")) {
		return -2
	}
	# PASS STRICT STRING
	return 1
}

# vim:fdm=marker:
