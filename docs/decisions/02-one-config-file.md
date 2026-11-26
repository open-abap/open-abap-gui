# One configuration file

The converter has no configuration file of its own. It reads the `converter`
object inside `abap_transpile.json`, plus `input_folder` and `libs` to find
includes, and ignores every other key.

- Folders resolve against the working directory, exactly like the transpiler.
- The converter owns its output folder: a full run clears it first, so no stale
  class survives.
- The output folder must not overlap any input folder (`GGCONV-E119`).

Why: the converter and the transpiler always agree on which folders and libs
are in play.

Code: [converter/src/config.ts](../../converter/src/config.ts)
