#!/bin/sh
fy-testsuite --streaming --json=force $1 >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	exit 1
fi
exit 0
