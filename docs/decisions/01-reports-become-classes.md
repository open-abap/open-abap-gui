# Reports become classes

Classic reports (`*.prog.abap`) are not run as programs. The converter rewrites
each one into a global class that implements the framework's interfaces, and
the transpiler compiles that class like any other.

- Conversion is deterministic and offline: same input, same output, no network
  or model calls.
- The converter reads ABAP through abaplint's syntax tree, never through text
  matching, and a rewrite replaces only the span of the node it changes.
- Only statements with a lowering rule are rewritten; everything else is carried
  over as written, apart from renames and system fields the session holds
  (`sy-lsind`, `sy-repid`, ...).
- Strict mode emits nothing when there is an error diagnostic. Partial mode emits
  compilable output with `TODO GGCONV-*` comments.

Why: a class runs on the open-abap runtime without a program/event runtime, and
the original source stays the single source of truth.

Code: [converter/src/passes/lower-statements.ts](../../converter/src/passes/lower-statements.ts),
[converter/README.md](../../converter/README.md)
