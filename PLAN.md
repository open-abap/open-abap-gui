# Plan: converter CLI takes `abap_transpile.json` as input

> **Status: implemented.** All five steps are done. Sections marked
> "Correction found during implementation" record where the plan was wrong and
> what was built instead; the root `abap_transpile.json` was deliberately left
> unchanged (see step 5).

## Goal

Replace the converter CLI's one-file-plus-flags contract

```text
node converter/bin/convert.mjs report.prog.abap --include-path src --ddic types.json --output out/x.clas.abap
```

with a config-driven batch contract

```text
node converter/bin/convert.mjs                       # uses ./abap_transpile.json
node converter/bin/convert.mjs --config path/to/abap_transpile.json --check
```

so that the set of programs to convert, where their includes live, and where the
generated `.clas.abap` lands are all derived from the same file the transpiler
already reads. The library API ([converter/src/api.mjs](converter/src/api.mjs))
does not change; this is a change to the CLI layer plus one new config module.

## Why

Three things in the repo currently carry knowledge that `abap_transpile.json`
already has:

1. [converter/bin/convert.mjs](converter/bin/convert.mjs) converts exactly one
   file and needs `--include-path` repeated per source root.
2. [converter/test/gg-gui.mjs:1284-1345](converter/test/gg-gui.mjs#L1284-L1345)
   hand-rolls the whole batch: directory scan, `resolveInclude`, screen-metadata
   load, class-name/tcode derivation, per-report output writing — and then
   *writes an `abap_transpile.json`* at the end
   ([gg-gui.mjs:1352-1372](converter/test/gg-gui.mjs#L1352-L1372)).
3. [abap_transpile.json](abap_transpile.json) and
   [converter/gg-gui-validation/abap_transpile.json](converter/gg-gui-validation/abap_transpile.json)
   already declare `input_folder`, `input_filter`, `exclude_filter`.

After the refactor, the batch driver lives in the converter (tested, reusable)
and the gg-gui harness shrinks to "call the batch API, then run its own audits".

## Config mapping

Keys read from `abap_transpile.json`
([schema](node_modules/@abaplint/transpiler-cli/schema.json)):

| key | converter use |
| --- | --- |
| `input_folder` (string or array) | roots scanned for `*.prog.abap`; also the include search path list (replaces `--include-path`) |
| `input_filter` | case-insensitive regex allow-list applied to each discovered path; empty = all |
| `exclude_filter` | case-insensitive regex deny-list, applied after `input_filter` |
| `output_folder` | the transpiler's JS output; the converter writes generated `.clas.abap` to `<output_folder>_converter` (see **Generated-class output** below) |
| `libs`, `options`, `write_*` | ignored |

`abap_transpile.json` is the **only** config file. There is no sibling
`abap_convert.json` and no extra block inside `abap_transpile.json` — the
schema's `additionalProperties: false`
([schema.json:5-7](node_modules/@abaplint/transpiler-cli/schema.json#L5-L7))
makes a private key off-contract even though nothing enforces it in this repo
today.

That works because the converter-only settings each already have a home:

| setting | where it lives |
| --- | --- |
| generated-class folder | derived: `<output_folder>_converter` |
| conversion mode | `--mode`, default `strict` |
| DDIC types | `--ddic <file.json>`, unchanged |
| class name / transaction code | derived from the program name; `--class`/`--tcode` for a single program; a `className(programName)` callback for library callers |

The only setting with no JSON home is the batch class-name rule — the
`ZGG_GUI_* -> ZCL_CV_*` rewrite at
[gg-gui.mjs:150-156](converter/test/gg-gui.mjs#L150-L156). It is a function of
the program name, so it belongs in the library API as a callback, not in a
config file; its one consumer already calls the API directly.

### Generated-class output

The converter writes to the `output_folder` value postfixed with `_converter`,
resolved relative to the config file's directory:

| config | `output_folder` | converter writes to |
| --- | --- | --- |
| [abap_transpile.json](abap_transpile.json) | `output` | `output_converter` |
| [converter/gg-gui-validation/abap_transpile.json](converter/gg-gui-validation/abap_transpile.json) | `converter/gg-gui-validation/output` | `converter/gg-gui-validation/output_converter` |

This is derived, not configurable — one rule, no extra key, and the two folders
stay adjacent and obviously paired. Consequences to handle:

- **The generated folder must be listed in `input_folder`**, otherwise the
  transpiler never sees the classes the converter just wrote. The converter
  cannot edit the config, so it emits a diagnostic when
  `<output_folder>_converter` is absent from `input_folder`, naming the exact
  line to add. New code: `GGCONV-W1xx` (warning, not error — a `--check` run
  legitimately has no transpile step).
- **`_converter` is itself a scan root**, so `discoverPrograms` must exclude it
  before scanning; otherwise a second run converts its own output. Exclude it
  unconditionally, ahead of `input_filter`/`exclude_filter`.
- **gg-gui's folder moves**: `converter/gg-gui-validation/generated` becomes
  `converter/gg-gui-validation/output_converter`, which changes that config's
  `input_folder` entry and the `generatedRoot` constant in the harness.
- `--output-folder` remains as an escape hatch for one-off runs; it does not get
  the postfix (the value is used verbatim).

Writes always overwrite. The converter replaces whatever is at the target path,
with no existence check and no confirmation flag — a conversion run is
reproducible from source, so a stale file has no value to protect. This
**reverses** today's single-file CLI behaviour
([convert.mjs:102-104](converter/bin/convert.mjs#L102-L104)), which refuses to
write over an existing output and exits `2`. Delete that branch and its
`exists()` helper.

### Derivations replacing today's flags

- **Entry points**: a discovered `*.prog.abap` is a conversion entry point only
  if it starts with `REPORT` or `PROGRAM`; INCLUDE-only files (abapGit
  serialises those as `.prog.abap` too — see
  [source-resolver.mjs:27-28](converter/src/source-resolver.mjs#L27-L28)) are
  skipped as entries but stay available as include targets.

  Implemented with the `/^[ \t]*(?:REPORT|PROGRAM)\s+(\S+)/m` pre-filter rather
  than by classifying and discarding, for a reason the plan missed rather than
  for speed: a `className(programName)` callback has to run *before* conversion,
  so the program name must be read up front anyway. The conversion result stays
  authoritative for `programKind`.
- **Includes**: `includePaths` = resolved `input_folder` list. This makes
  gg-gui's custom `resolveInclude`
  ([gg-gui.mjs:1284-1288](converter/test/gg-gui.mjs#L1284-L1288)) unnecessary,
  because `includeCandidates` already tries `<name>.prog.abap` per search path.
- **Screen/dynpro metadata**: already discovered beside the report by
  [loadDynproMetadata](converter/src/dynpro-metadata.mjs#L553) from the real
  report path. Today the CLI passes a bare filename, so discovery mostly misses.

  **Do not fix this by passing the absolute path as `filename`.** The filename
  is written into the generated class header (`* Source file:`) and feeds the
  compilation hash, so an absolute path bakes a machine-specific string into
  generated ABAP and changes `* Source SHA-256:` on every checkout. The
  before/after diff below caught exactly that. `conversionPlan` therefore passes
  a config-root-relative `filename` and anchors discovery separately with
  `dynproMetadataFilename` and `dynproScreenDirectory`, both absolute —
  `screenFilesForReport` matches on `path.basename`, so the relative name is
  harmless there.
- **Class name / transaction code**: default to
  [`defaultClassName`/`defaultTransactionCode`](converter/src/options.mjs#L22-L35).
  Library callers may pass `className(programName)` / `transactionCode(programName)`
  callbacks to override per program; the CLI exposes only `--class`/`--tcode`,
  valid with a single `--program`. No JSON mapping table.
- **`abaplint.jsonc`**: `readConfig` is already called with a default relative
  path ([api.mjs:557](converter/src/api.mjs#L557)); resolve it against the same
  working directory the folders resolve against.

### Correction found during implementation: paths resolve from cwd

An earlier draft of this plan said to resolve `input_folder` against the
configuration file's directory. That is wrong, and the checked-in gg-gui
configuration is the proof: the file lives in `converter/gg-gui-validation/`
while its `input_folder` names `src` at the repository root.

abap_transpile globs `<input_folder>/**` from `process.cwd()` and matches its
filters against the result of `glob.sync(..., { absolute: true, posix: true })`.
The converter therefore does the same:

- folders resolve against the working directory, not the config file
- filters are tested against the **absolute** posix path, so a pattern cannot be
  anchored with `^` (`"^src/"` matches nothing; `"/src/"` works)

Resolving differently would make one file mean two different things to the two
tools, which is the defect this refactor exists to remove. `loadTranspileConfig`
takes an explicit `{ cwd }` for tests.

## Open decisions

**Decision 1 — where converter-only settings live.** Settled: nowhere.
`abap_transpile.json` is the only file, unmodified and on-schema; everything
else is a derivation, a CLI flag, or a library-API callback. See **Config
mapping** above.

**Decision 2 — where generated classes are written.** Settled: `output_folder`
postfixed with `_converter`. See **Generated-class output** above.

**Decision 3 — overwrite policy.** Settled: always overwrite, everywhere, no
flag. See **Generated-class output** above.

## Work breakdown

### 1. `converter/src/config.mjs` (new)

```js
export async function loadTranspileConfig(configPath) // parse + validate shape
export async function discoverPrograms(config)        // -> [{ filename, source }]
export function conversionPlan(config, overrides)     // -> per-program convertProgram inputs
```

- `loadTranspileConfig`: read JSON, normalise `input_folder` to an array,
  compile `input_filter`/`exclude_filter` to case-insensitive `RegExp`, derive
  `generatedFolder = `${output_folder}_converter``, resolve every path against
  the config file's directory, and emit `GGCONV-E1xx` diagnostics (not throws)
  for a missing file, malformed JSON, a missing `input_folder`, a missing
  `output_folder`, or a filter that is not a valid regex. New codes needed —
  allocate `GGCONV-E110` … `GGCONV-E114` and register them wherever the existing
  codes are documented. The `input_folder`-does-not-contain-`generatedFolder`
  case is a warning, not an error.
- `discoverPrograms`: deterministic recursive scan, sorted with
  `localeCompare`, de-duplicated by normalised path so overlapping
  `input_folder` entries (e.g. `src` and `src/sub`) yield one entry, with
  `generatedFolder` pruned before any filter runs so the converter never reads
  its own output back as input.
- `conversionPlan`: merges the transpile config with caller overrides into the
  `convertProgram` input per program — the single place precedence is decided,
  now only two levels deep (explicit override > derived default). `overrides`
  carries `mode`, `ddicTypes`, and the optional `className`/`transactionCode`
  callbacks; the CLI fills it from flags, gg-gui from its own constants.

### 2. `converter/src/batch.mjs` (new)

```js
export async function convertConfiguredPrograms({ config, overrides, onResult })
```

- Sequential over the sorted program list (determinism first; parallelism is a
  later optimisation and would need the diagnostics order pinned anyway).
- Per program: `convertProgram(...)`, then write `<class>.clas.abap`, helper
  classes, and `<class>.manifest.json` into `config.generatedFolder`, creating
  it if absent and overwriting unconditionally. Keep the existing
  write-to-temp-then-`rename` sequence
  ([convert.mjs:60-64](converter/bin/convert.mjs#L60-L64)): `rename` overwrites
  on POSIX and on Windows for a same-volume move, so an interrupted run leaves
  the previous file intact rather than a truncated one.
- Clear the generated folder once before the run. This is deletion, which is
  broader than overwriting, so it is called out separately — but it is what the
  gg-gui harness already does
  ([gg-gui.mjs:1275-1281](converter/test/gg-gui.mjs#L1275-L1281)), and without
  it a class that no current program produces survives as a stale transpiler
  input. Scope it to `config.generatedFolder` only; when `--output-folder`
  redirects the run elsewhere, overwrite files but never clear the directory,
  since that path may be shared.
- Detect target-class collisions across programs before writing anything and
  report them as a diagnostic (gg-gui asserts this today at
  [gg-gui.mjs:1297](converter/test/gg-gui.mjs#L1297)).
- Return a summary `{ programs: [...], supportedCount, diagnostics }` so both
  the CLI and gg-gui consume the same shape.

### 3. `converter/bin/convert.mjs` (rewrite)

New surface:

```text
Usage: node converter/bin/convert.mjs [options]

  --config <file>          abap_transpile.json (default: ./abap_transpile.json)
  --program <name>         convert only this program (repeatable)
  --output-folder <dir>    write classes here instead of <output_folder>_converter
  --ddic <file.json>       DDIC type metadata (unchanged)
  --mode strict|partial    default: strict
  --diagnostics text|json  default: text
  --check                  analyze and print the summary, write nothing
  --help

Single-program options (require exactly one --program):
  --class <name>           target global class name
  --tcode <code>           transaction code
  --description <text>     transaction description
  --output <path>          write this one .clas.abap instead of the folder
```

- Exit codes stay as they are: `1` when any program is unsupported, `2` for
  usage/IO errors. One case disappears: the `2` that today means "refused to
  overwrite" ([convert.mjs:102-105](converter/bin/convert.mjs#L102-L105)).
- `--check` prints one JSON document for the whole run
  (`{ programs: [{ filename, targetClass, supported, programKind, capabilities, diagnostics }], summary }`)
  rather than today's single-program object. Keep the per-program fields
  identically named so existing consumers of `--check` output need only index
  into `programs`.
- `--class`, `--tcode`, `--description`, `--output` keep working, but **only**
  with exactly one `--program`; with zero or several, exit `2` rather than
  applying one class name to every program. This is what preserves the
  single-file workflow now that the positional form is gone.
- `parseArgs` loses its `positional` array entirely
  ([convert.mjs:31-44](converter/bin/convert.mjs#L31-L44)); anything not
  starting with `--` is an error. `--program` joins `--include-path` as a
  repeatable flag, and `--include-path` itself is deleted — `input_folder`
  supplies the search paths.

**Decision 4 — the bare positional argument.** Settled: dropped. The CLI takes
no positional arguments at all; a filename can only be selected with
`--program`, and only from within a config's `input_folder`.

A positional argument is therefore a usage error, not a silently ignored one.
Exit `2` with a message that names the replacement, because the old form is in
the README and in muscle memory:

```text
convert.mjs takes no positional arguments.
  was:  convert.mjs report.prog.abap --check
  now:  convert.mjs --config abap_transpile.json --program report --check
```

### 4. Retire the duplicated logic in `converter/test/gg-gui.mjs`

Replace the hand-rolled loop
([gg-gui.mjs:1284-1345](converter/test/gg-gui.mjs#L1284-L1345)) with a call to
`convertConfiguredPrograms`, keeping the harness's own responsibilities:
`partialStrategy` fallback probe (preserve → skeleton), reference contracts,
visual audits, `results.json`. The probe/fallback is a real behaviour and should
move into `batch.mjs` as an opt-in `fallbackStrategy: "skeleton"` rather than
being reimplemented in the harness.

`generatedClassName`/`transactionCode`
([gg-gui.mjs:150-156](converter/test/gg-gui.mjs#L150-L156)) stay in the harness
and are passed straight through as the `overrides.className` /
`overrides.transactionCode` callbacks. This is the whole reason the batch API
takes functions rather than reading a mapping from JSON: the rule is two lines
of string manipulation, specific to one repository's naming convention, and
nothing else in the project needs it.

Its final `abap_transpile.json` write
([gg-gui.mjs:1352-1372](converter/test/gg-gui.mjs#L1352-L1372)) **moves to the
top of the run instead of being deleted.** An earlier draft said to delete it
and read the checked-in file; there is no checked-in file. All of
`converter/gg-gui-validation/` is gitignored, so that `abap_transpile.json` is a
build artifact, and deleting the write would break a fresh clone where the file
does not exist yet.

Writing it first is what makes the harness and the converter agree: the config
is written, then loaded with `loadTranspileConfig`, and the converter's output
folder is derived from the same `output_folder` abap_transpile is handed later
in the run. The harness asserts `transpileConfig.generatedFolder === generatedRoot`
rather than assuming it.

Folder rename, in the same step so nothing is half-moved. All of
`converter/gg-gui-validation/` is gitignored ([.gitignore:14](.gitignore#L14))
and nothing under it is tracked, so this is a plain rename of build output, not
a `git mv`; the harness recreates the folder on the next run anyway.

- delete the stale `converter/gg-gui-validation/generated` directory
- `generatedRoot` in the harness becomes `output_converter`
- the `input_folder` entry in the config the harness writes becomes
  `converter/gg-gui-validation/output_converter`
- grep for the literal `gg-gui-validation/generated` across the repo (scripts,
  `.gitignore`, workflows, `webpack.config.cjs`) before declaring this done

**Risk**: this file is 128 KB and its gates currently pass on hollow shells; the
refactor must not change any `results.json` field except the paths that moved.
Gate the step behind an unchanged-output check (see Verification).

### 5. Docs and scripts

- [converter/README.md:42-48](converter/README.md#L42-L48): both example
  invocations use the positional form and no longer run. Replace the "CLI is
  intentionally thin" block with the config-driven usage; document the key
  mapping table and the `_converter` output rule. State that
  `abap_transpile.json` is the only config file, that the converter never writes
  to it or requires a key the transpiler does not already define, and that
  `output_folder` must be present even for a `--check`-only config.
- [converter/README.md:51](converter/README.md#L51): "Generated files are never
  overwritten by default" is now false — replace with the overwrite rule and the
  note that the generated folder is cleared at the start of a run.
- Leave the object-level collision checks alone: `GGCONV-E106`
  ([api.mjs:406-407](converter/src/api.mjs#L406-L407)) and `GGCONV-E602`
  ([workbench-preview.mjs:54-60](converter/src/workbench-preview.mjs#L54-L60))
  guard against clobbering ABAP objects in a repository, which is a different
  question from overwriting a generated file on disk.
- [converter/package.json:18](converter/package.json#L18): `check` currently
  passes a path positionally, which no longer parses. It needs a checked-in
  fixture config — `converter/test/fixtures/check/abap_transpile.json` — and
  becomes `node bin/convert.mjs --config test/fixtures/check/abap_transpile.json --check`.
  The fixture must carry an `input_filter`: `scaffold/examples` holds 149
  `*.prog.abap` files, and `check` is meant to stay a one-program smoke test.

  ```json
  {
    "input_folder": ["../../../../scaffold/examples"],
    "input_filter": ["zgg_ex_001\\.prog\\.abap$"],
    "exclude_filter": [],
    "output_folder": "output",
    "options": {}
  }
  ```

  `output_folder` is required by the schema and unused by `--check`, which
  writes nothing — but `loadTranspileConfig` still derives `output_converter`
  from it, so it cannot be omitted. It cannot be explained in the file either:
  `abap_transpile.json` is strict JSON, not JSONC like
  [abaplint.jsonc](abaplint.jsonc). Put the note in the README instead.
- Root [abap_transpile.json](abap_transpile.json): **left unchanged.** An
  earlier draft said to add `output_converter` to `input_folder` so a root-level
  conversion feeds `npm run transpile`. That is wrong here: the 149 programs in
  `scaffold/examples` convert to `ZCL_GG_EX_001`… and every one of those classes
  already exists as a hand-written `.clas.abap` in the same folder. Wiring the
  folder in would mean a bare `convert.mjs` at the repository root produces 149
  duplicate class definitions and breaks `npm run transpile`.

  The scaffold examples are the converter's expected *output*, not its input, so
  a root-level conversion is not a meaningful operation. `GGCONV-W110` still
  fires for that config, which is correct — it says the output folder is not
  wired in, and here it should not be.

  Open question for a follow-up: a batch run currently detects collisions
  between two converted programs (`GGCONV-E115`) but not against classes that
  already exist in `input_folder`. `convertProgram` already accepts
  `existingClassNames` and reports `GGCONV-E106`; wiring it from the batch would
  turn the hazard above into an explicit diagnostic. Deliberately not done here,
  because "already exists" needs a definition (same folder? any input folder?).
- [.gitignore](.gitignore): the existing `output` entry (line 1) does **not**
  cover `output_converter` — gitignore matches the whole path segment. Add an
  explicit `output_converter` entry. The gg-gui folder needs nothing, since
  `converter/gg-gui-validation/` is already ignored wholesale.
- Root [README.md](README.md) and [package.json](package.json): no other change
  — `npm run transpile` still calls `abap_transpile` directly.

## Verification

Run before and after, and diff:

1. `cd converter && npm run test:unit` — plus new unit tests for
   `loadTranspileConfig` (missing file, bad JSON, string vs array
   `input_folder`, missing `output_folder`, bad regex, folder resolution against
   the working directory, filters matching absolute paths,
   `generatedFolder` derivation, and the warning when
   `input_folder` omits it; plus: an unknown top-level key in the config is
   ignored, not rejected — the converter reads the transpiler's file and must
   not become a second validator of it) and `discoverPrograms` (filter precedence,
   de-duplication, sort stability, include-only `.prog.abap` skipped, and — the
   one that bites in practice — a second run over a populated
   `<output_folder>_converter` discovering the same program set as the first).
2. `npm run check` and `npm run check:matrix` — CLI smoke, must keep the same
   supported/unsupported verdicts per fixture. `check` now runs through the new
   fixture config, so confirm it still covers exactly `zgg_ex_001` and has not
   quietly become a 149-program run.
3. A positional argument exits `2` with the replacement-usage message, and
   `--class` with zero or several `--program` values exits `2` as well.
4. Run the CLI twice in a row against the same config with no `--check`: the
   second run must exit the same way as the first and leave byte-identical
   files. Today the second run exits `2`. This is the direct test of the
   overwrite rule and belongs in `test:unit`.
5. `npm run test` (the full [verify.mjs](converter/test/verify.mjs) chain).
6. `npm run test:gg-gui` — capture `converter/gg-gui-validation/results.json`,
   `reference-manifest.json`, and the generated `.clas.abap` files before the
   change; after the change they must be byte-identical except for paths that
   intentionally moved. This is the real regression gate for step 4.

## Sequencing

Steps 1–3 are one self-contained change and can land first: the library API,
gg-gui harness, and every existing test keep working because nothing else
imports the CLI. Steps 4–5 land second, once the byte-identical gg-gui output is
demonstrated. Splitting them keeps the risky 128 KB harness edit out of the
change that introduces the new config path.

## Explicitly out of scope

- Discovering DDIC types from `.tabl.xml`/`.dtel.xml` in `input_folder`. That
  would remove `--ddic` and the hardcoded
  [GG_GUI_DDIC_TYPES](converter/src/gg-gui-ddic.mjs) catalog, but it is a
  separate parser-shaped piece of work. `--ddic` and the `ddicTypes` option stay
  exactly as they are. It is also the change that would most tempt someone to
  add a converter key to `abap_transpile.json`; the answer stays no — DDIC
  metadata would be discovered from `input_folder` like everything else.
- Reading `libs` to fetch and convert programs from dependency repositories.
- Any change to `convertProgram` semantics, diagnostics content, or emitted ABAP.
