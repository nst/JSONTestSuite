JSON.awk
========

A practical JSON parser written in awk.

[https://github.com/step-/JSON.awk](https://github.com/step-/JSON.awk)

Introduction
------------

JSON.awk is a self-contained, single-file program with no external dependencies.
It is similar to [JSON.sh](https://github.com/dominictarr/JSON.sh), a JSON
parser written in Bash -- retrieved on 2013-03-13 to form the basis for
JSON.awk. Since then the projects have separated their development paths, each
one adding new features that you will not find in the other.

Features
--------

* Single file without external dependencies
* Can parse multiple input files within a single invocation (one JSON text per file)
* [Callback interface](doc/callbacks.md) (awk) to hook into parser and output events
* [Library](doc/library.md) of practical callbacks (optional)
* Capture invalid JSON input for further processing
* Choice of MIT or Apache 2 license
* JSON.sh compatible (as of 2013-03-13) default output format

Non-features
------------

* Transforming input values, e.g., string/number normalization

Compatibility with Awk Implementations
--------------------------------------

Of the many awk [implementations](https://en.wikipedia.org/wiki/AWK#Versions_and_implementations)
around, JSON.awk works better with the POSIX ones and with GNU awk.
JSON.awk is routinely tested on Linux with gawk, busybox awk and mawk in this order.
I recommend gawk. JSON.awk does not require GNU gawk extensions, and the differences
of running gawk with or without the `--posix` option enabled are minimal, if any.
Running with busybox awk requires a simple patch [FAQ](doc/FAQ.md#busybox_awk).
Running with mawk requires mawk version 1.3.4 20150503 or higher [FAQ](doc/FAQ.md#mawk).

Supported Platforms
-------------------

All OS platforms for which a POSIX awk implementation is available. Special cases:

* macOS and FreeBSD [&raquo;10](https://github.com/step-/JSON.awk/issues/10)
* macOS [&raquo;15](https://github.com/step-/JSON.awk/issues/15)

Conformance
-----------

There is no official conformance test for the JSON language. Thankfully, some
unofficial test suites exist.  JSON.awk is tested against the
[JSONTestSuite](https://github.com/nst/JSONTestSuite.git).

[Test results and comparisons](doc/JSONTestSuite/results/full_results.md)

Installing
----------

Add files JSON.awk and optionally callbacks.awk to your project and follow the
examples.

Usage Examples
--------------

For full instructions please [read the docs](doc/usage.md).
Mawk users please read the [FAQ](doc/FAQ.md#mawk).
Busybox awk users also please read the [FAQ](doc/FAQ.md#busybox_awk).

Passing file names as command arguments:

```sh
awk -f JSON.awk file1.json [file2.json...]

awk -f JSON.awk - < file.json

cat file.json | awk -f JSON.awk -
```

Passing file names on stdin:

```sh
echo -e "file1.json\nfile2.json" | awk -f JSON.awk
```

Using callbacks to build a custom application ([FAQ 5](doc/FAQ.md#5)):

```
awk -f your-callbacks.awk -f JSON.awk file.json
```

Applications
------------

* [Opera-bookmarks.awk](https://github.com/step-/opera-bookmarks.awk)
  Extract (Chromium) Opera bookmarks and QuickDial thumbnails.
  Convert bookmark data to SQLite database and CSV file.

Projects known to use JSON.awk
------------------------------

* [Awk for JSON](https://github.com/mohd-akram/jawk) makes available JSON
  nested objects as the awk array variable `_`, e.g. awk's `_["person","name"]`
  evaluates to `Jason` for the JSON object `{"person":{"name":"Jason"}}`.
* [KindleLauncher](https://bitbucket.org/ixtab/kindlelauncher/overview)
  a.k.a. KUAL, an application launcher for the Kindle e-ink models, uses
  JSON.awk to parse menu descriptions.

License
-------

This software is available under the following licenses:

* MIT
* Apache 2

Credits
=======

* [JSON.sh](https://github.com/dominictarr/JSON.sh)'s source code, retrieved on
  2013-03-13, more than inspired version 1.0 of JSON.awk; without JSON.sh this
  project would not exist.

* [gron](https://github.com/tomnomnom/gron) for inspiration leading to
  library module [js-dot-path.awk](doc/library.md#js_dot_path), and for some
  test files.

* [JSONTestSuite](https://github.com/nst/JSONTestSuite)

