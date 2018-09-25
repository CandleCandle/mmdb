

Installation
============

Use [pony-stable](https://github.com/ponylang/pony-stable)

* `stable add [github CandleCandle/mmdb | local-git <local path>]`
* `stable fetch` to fetch your dependencies
* `use "mmdb"` to include this package
* `stable env ponyc` to compile your application

Test
====

Build and run tests with:
`stable env ponyc -o bin test/ && ./bin/test`

Example
=======

```pony

use "mmdb"
use "files"
use logger = "logger"

actor Main
  new create(env: Env) =>
    try
      let path = FilePath(env.root as AmbientAuth, env.args(1)?)?
      let file = File.open(path)

      let log = logger.StringLogger(logger.Error, env.out)
      let parser: Parser val = recover val Parser(file.read(file.size()), log) end
      let reader: Reader val = recover val Reader.create(parser, log)? end
      let result: Field = reader.resolve(U128.from[U32]( 0x08080808 )) // 8.8.8.8, Google's open DNS.

      Dump(env.out, result)
    end

```

Compile with:
`stable env ponyc -o bin -b mmdb-example .`
Run with:
`./bin/mmdb-example <path to mmdb file>`
The MMDB files can be found (at time of writing) from https://dev.maxmind.com/geoip/geoip2/geolite2/#Databases

Notes
=====

This follows the spec from https://maxmind.github.io/MaxMind-DB/

At time of writing, none of the example databases contain byte arrays, booleans or "data container" type fields, therefore these data types are currently left unimplemented.
