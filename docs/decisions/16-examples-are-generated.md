# Example classes are generated

Every `examples/zcl_gg_ex_NNN` class is the converter's output for the matching
`zgg_ex_NNN` program. The classes are committed, and `npm test` fails when a
committed class differs from what the converter produces now.

```sh
node test/examples-drift.mjs            # check
node test/examples-drift.mjs --update   # regenerate
```

Why: the examples test the converter and the host together, and cannot drift
into hand-written code that no conversion would produce.

Code: [test/examples-drift.mjs](../../test/examples-drift.mjs)
