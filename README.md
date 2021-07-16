# colorls

A port of the famous ruby `colorls` tool to Crystal.

See also: [Ruby colorls](https://github.com/athityakumar/colorls)

## Motivation

I found the original colorls to be a pretty neat tool and was interested to start learning Crystal since they released v1.0, so I decided trying to port colorls would be a nice way to:
+ learn about how colorls works
+ learn about Crystal and its standard library
+ figure out some of the pitfalls in translating a work from Ruby to Crystal

## Performance

Another motivation is that I've been interested more recently in using high-level compiled languages to write command-line utilities in order to reduce the runtime dependencies.  Just starting up a ruby interpreter and loading in some packages can be a pretty expensive task.  Since a tool like colorls is designed for interactive use, it seemed like a good fit.

In limited testing on my development machine, I'm seeing a 30-50x speedup.  Yay Crystal!

CAVEAT: Please take any anecdotal benchmarks with a grain of salt.  Feel free to drop me a line and tell me what you see.

## Installation

TODO: Come up with a procedure to install this and then write installation instructions here

## Usage

This has only been tested with Crystal 1.0.0 w/ LLVM 10.0.  YMMV.

compile with:
```
crystal build --release src/colorls.cr
```

then:
```
./colorls
./colorls -l
./colorls -1
```

## Development

Currently there are no shard dependencies, everything comes from the stdlib.

Test with
```
crystal spec
```

Build with
```
crystal build src/colorls.cr
```

## TODO
- Some tests from the Ruby version were ported, others have not (yet).
- Some functionality from the original version is known to not work or have been tested.
- All the special encoding features in the Ruby version dont exist here.
- Wide-unicode chars may not have surrounding formatting computed appropriately
- Movement of the binary with respect to the /lib directory containing the yaml config files probably will cause issues
- Need more tests

## Contributing

1. Fork it (<https://github.com/nanobowers/colorls/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors / Attribution
- [Ben Bowers](https://github.com/nanobowers) - creator and maintainer

