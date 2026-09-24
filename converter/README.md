# PROG-to-CLAS converter

The converter is a deterministic, offline source-to-source tool for migrating
classic executable reports to the versioned scaffold interfaces in `framework/`.
The library API is the primary entry point:

```js
import { convertProgram } from "./src/api.mjs";

const result = await convertProgram({
  source: "REPORT zdemo.\nSTART-OF-SELECTION.\nWRITE 'hello'.\n",
  filename: "zdemo.prog.abap",
  mode: "strict",
});
```

`result` contains `classSource`, optional `helperSources` for hoisted report-local
classes, serializable `reportIR` and `scaffoldIR` values, a stable JSON-ready
`manifest`, source maps, diagnostics, and the `supported`
flag. Strict mode returns no class source when an error diagnostic exists.
Partial mode emits compilable output with explicit `TODO GGCONV-*` comments for
unsupported semantics. When `partialStrategy: "skeleton"` is requested, a
safe-entry failure gets the diagnostic-only shell; optional feature gaps get a
small runnable application containing the recovered selection-screen content
and headings, with the unsupported operations retained in diagnostics.

For broad migration surveys where unsupported source fragments must never be
preserved in the emitted class, set `partialStrategy: "skeleton"`. The default
`"preserve"` strategy keeps supported lowering around the explicit TODOs for
hands-on migration work.

Read-only workbench adapters can use `previewProgram` or
`previewRepositoryProgram` from `src/index.mjs`. The preview contract requires
an explicit target class, reports a collision before offering generated source,
and returns `repositoryChanged: false`; source is returned only when the caller
explicitly requests it after inspecting diagnostics. The adapter accepts only a
read-side `getProgram` callback and has no save or activation path. A real
workbench can wrap that adapter with `createWorkbenchService`; its separate
`save`/`create` methods require authorization, CSRF validation, a matching
repository revision, and an explicit writer before they can mutate anything.

The CLI is driven by the same `abap_transpile.json` the transpiler reads:

```text
node converter/bin/convert.mjs
node converter/bin/convert.mjs --config abap_transpile.json --check --diagnostics json
node converter/bin/convert.mjs --program ZGG_EX_001 --class ZCL_REPORT --output out/report.clas.abap
```

It takes no positional arguments; a single report is selected with `--program`.
The keys it reads are:

| key | converter use |
| --- | --- |
| `converter.input_folder` | folders scanned for `*.prog.abap` and `*.tran.xml`; searched first for INCLUDEs |
| `converter.output_folder` | where the generated classes are written; owned by the converter |
| `input_folder` | searched for INCLUDEs after the converter input; must list `converter.output_folder` |
| `libs` | dependencies searched for INCLUDEs; their programs are never converted |

```json
{
  "input_folder": ["src", "generated"],
  "output_folder": "output",
  "converter": {
    "input_folder": ["reports"],
    "output_folder": "generated"
  },
  "options": {}
}
```

Each lib is read the way abap_transpile reads it: from `folder` (relative to
the working directory) when that exists, otherwise shallow-cloned from `url`
with `git clone --depth 1`. `files` selects its sources (default `/src/**`) and
`exclude_filter` drops some. The CLI clones into a temporary folder named after
the url — a fixed name, so the include paths and the source hash they feed stay
the same from run to run — and deletes it when the run ends. Library callers
do the same with `loadLibraries(config)`: set `config.libraryFolders` to the
returned `folders`, convert, then call `cleanup()`.

Everything else in the file belongs to the transpiler and is ignored, including
`output_folder`, `input_filter` and `exclude_filter` and keys a newer
transpiler adds: the converter reads that file, it never writes it and never
validates it beyond the keys above. The filters select what abap_transpile
compiles; they do not narrow the converter input, which is a folder of its own.

`abap_transpile.json` is the only configuration file; the `converter` object is
part of the transpiler's schema. Folder names resolve against the working
directory, exactly as abap_transpile resolves them, so the same file names the
same folders for both tools.

A report's transaction code comes from `--tcode` when given, otherwise from an
abapGit transaction object (`<tcode>.tran.xml`) in the converter input folders whose
program is the report, otherwise from the report name. The transaction's short
text becomes the default description. When several transactions start the same
report, the alphabetically first transaction code is used.

Add `converter.output_folder` to `input_folder` or abap_transpile will not
compile what the converter just wrote — `GGCONV-W110` says so, and names the
entry to add. Because a full run clears that folder, it must not be, contain or
sit inside a converter input folder or any other `input_folder` entry;
`GGCONV-E119` rejects such a configuration before anything is converted. The
`converter` object is required even for a `--check` run that writes nothing.

Writes always overwrite, and a full run clears the generated folder first so a
class that no current program produces cannot survive as a stale transpiler
input. The converter owns that folder entirely. Two runs do not clear it: a
`--program` run, because the classes it does not produce are still current, and
an `--output-folder` run, because that folder may be shared. A run in which two
programs map to the same class writes nothing at all and reports
`GGCONV-E115`, rather than keeping one class and losing the other.

A report's class is named from the report (`ZFOO` becomes `ZCL_FOO`) unless
`--class` names it. When that default name is already taken by a class or
interface in `input_folder`, `converter.input_folder` or the libs, the report
is generated as the next free name (`ZCL_FOO_1`, `ZCL_FOO_2`, …) and
`GGCONV-W106` names the file that holds the original. The generated
transaction metadata records the report's program name, so `SUBMIT zfoo` finds
the renamed class through the transaction registry. A name given with `--class`
is never replaced: if it is taken, `GGCONV-E106` reports it and nothing is
written for that report.

No network or model call is used during conversion; the only network access is
the CLI cloning a lib `url` before it starts. Includes are resolved from
`converter.input_folder`, `input_folder` and the libs, by the optional `resolveInclude(name, parentFilename)` callback,
or by deterministic filesystem candidates.

Selection texts can be supplied as a `Map`, object, or simple text-pool string
through `textPool`; unresolved `TEXT-*` keys remain deterministic and produce a
`GGCONV-W101` warning. Include content participates in the source hash.

Every message class a `MESSAGE` statement names is assumed to exist in the
target system; the message is raised through the session at runtime and the
converter reports nothing about it.

Every type a declaration references is assumed to exist in the target system.
`TYPES` declarations are emitted exactly as written, and `TABLES <name>` becomes
`DATA <name> TYPE <name>`; the converter neither translates type names nor
reports unknown ones. `ddicTypes` is optional field metadata that types
selection-screen elements declared `FOR <table>-<field>`:

```js
ddicTypes: {
  ZSFLIGHT: {
    fields: { CARRID: { type: "c", length: 3 } },
  },
}
```

Generated selection callbacks hydrate private `mv_*` state from scaffold
values and flush changes back to `ct_values` for mutable callbacks.

Report-local classes are emitted as separate, collision-free global helper class
sources. Their class-definition visibility sections, inheritance, method/event
declarations, and private attributes are retained. The generated report grants
only those helpers friendship, so helper methods can use report state without
promoting that state to public visibility.

Classic function modules are lowered only through the explicit compatibility
adapter registry in `src/function-modules.mjs`. Popup/dialog, classic ALV,
dynamic-selection, F4, variant, list-memory, conversion, and frontend URL or
binary families each have a named session operation. Unknown or custom
function modules remain diagnostics, and the manifest records the exact
adapter names used by a conversion.

Lowering is a fixed set of rules for the statements that need rewriting
(`LOWERING_RULES` in `src/passes/lower-statements.mjs`). Every other statement
is carried over as written, with the usual renames, and produces no diagnostic.
Every carried-over statement also gets the same value rewrites: system fields
the session holds (`sy-lsind`, `sy-repid`, …), the `SCREEN` work area inside
`LOOP AT SCREEN`, and the list color constants. A system field that becomes a
method call is kept as written when the statement only takes data objects, as
`CONCATENATE` does. Declarations and comments are not rewritten.
This includes function modules without a compatibility adapter, `FREE`,
dynamic `CREATE DATA`, dynamic Open SQL, and `PERFORM ... IN PROGRAM`, which
are all valid inside a method. Diagnostics are reserved for a statement a rule
exists for but cannot handle in that form (a `LOOP AT` over a table with a
header line, a dynamic `PERFORM (name)`, an unproven field-symbol `ASSIGN`,
unrepresented `WRITE` formatting) and for a statement abaplint cannot parse
(`GGCONV-E201`). They use operation-family codes instead of the broad
`GGCONV-E501` bucket, such as `E515` for unsafe field-symbol operations and
`E516` for other unsupported forms.

`CREATE OBJECT`, method-call statements, `CALL METHOD` (including dynamic
forms), and `SET HANDLER` are carried over as written. The only rewrite is for
report-local classes, which become generated helper classes: their names are
replaced by the helper's, creating one adds the `io_owner`/`io_session`
constructor arguments, and a static call to one is routed to the helper with
the same arguments.

When a sibling `.prog.xml` is available, its `TPOOL` is applied automatically:
selection text symbols resolve `TEXT-*` labels, while report-title entries
provide the default transaction heading. Explicit `textPool` or
`textSymbols` input still takes precedence. The same lookup is applied to
metadata-backed dynpro titles, headings, and pushbuttons.

Selection-screen domain values and GUI status definitions can be supplied as
metadata when the classic repository does not carry those definitions in the
program source:

```js
selectionMetadata: {
  P_MODE: { fixedValues: [{ key: "A", text: "Add" }] },
},
guiStatusMetadata: {
  LIST: { activeUcomm: ["PRI"], activePFKeys: [5] },
},
```

Reports containing supported `CALL SCREEN`, `CALL SELECTION-SCREEN`, `SUBMIT
... AND RETURN`, or `CALL TRANSACTION` forms expose
`zif_gg_resumable_v1`; the generated class contains deterministic continuation
cases. Complex or metadata-dependent transfers remain explicitly diagnosed in
partial mode.

Module pools are accepted with explicit `dynproMetadata`, an
`resolveDynpro(metadataRequest)` callback, or report-owned abapGit metadata.
The exported `loadDynproMetadata({ filename })` helper reads the sibling
`.prog.xml` and every matching `.prog.screen_NNNN.abap` file. It supplies
screen geometry and attributes, field elements, flow logic, GUI statuses,
titlebars, subscreens, next-screen relationships, and text-pool entries;
source code is never used to invent dynpro controls. For REPORT sources the
same automatic load is retained as `reportIR.screenMetadata` for the screen
provider layer.

Development commands:

```text
cd converter
npm run check
npm run check:matrix
npm run test:unit
npm run fixtures
npm run structural
npm run warnings
npm run hardening
npm run coverage
npm run transpile
npm run behavior
npm run browser
npm run test:gg-gui
npm test
```

`test:gg-gui` clones `https://github.com/larshp/gg-gui` into the gitignored
`gg-gui-validation/` workspace (or reads `GG_GUI_REPOSITORY`), writes
`gg-gui-validation/abap_transpile.json` naming that checkout as the converter input folder,
converts every report that configuration selects with the safe partial
strategy, transpiles the same configuration and serves the
generated report classes, verifies every generated target/helper class has clean
transpiler output before marking it as an application-parity candidate, and
writes one browser screenshot per report plus an HTML index under
`gg-gui-validation/screenshots/`. It is intentionally separate
from the offline verification gate because it resolves an external repository.

`behavior` compiles generated and hand-written report classes under
distinct names, runs examples `001`-`057` through `zcl_gg_host`, and compares
typed result models, plus selected user-input, validation-failure, and
interactive-action scenarios, and checks the `NEXT`/`BACK` host transitions for
dynpro example `058`. `structural` checks normalized scaffold-IR snapshots for
examples `001` through `058`. `test` runs the unit, CLI smoke, matrix, fixture,
structural, warning, hardening, coverage, transpile, behavioral, and generated-
browser gates in one sequence. 058 screen/flow/status parity is checked when the
corresponding explicit metadata is supplied. `browser` builds a disposable generated
058 class, runs its ABAP Unit transitions, and drives the generated transaction
through the HTTP/Playwright boundary without changing the shipped catalog.
The workbench Tools menu opens `/converter/preview`, a read-only HTTP adapter
that lists display-authorized programs, requires an explicit target class and
collision confirmation, and offers diagnostics before generated source or a
download. Save and activation remain unavailable until a separately authorized
repository writer is supplied.
`coverage` reports capability coverage by parsed AST construct across
the repository fixtures.
The converter also enforces configurable source byte/line and conversion-time
limits (`maxSourceBytes`, `maxSourceLines`, and `maxDurationMs`).
Known open boundaries remain explicit: parser-representable unsupported dynamic
WRITE operands are evaluated once before a guarded field-symbol fallback,
while parser-unrepresentable dynamic calls and unsafe field-symbol variants
retain diagnostics; supported lowered expressions remain inside their source
exception scope.
Top-level executable statements are assigned to their source event: an
explicit `LOAD-OF-PROGRAM` block is emitted to `load_of_program`, while
pre-event statements remain in `start_of_selection` as required by report
semantics.
Method-safe ordinary ABAP statements are preserved only through explicit
lowering rules. Method-local elementary field symbols with static bindings and
dynamic `WRITE` variable/offset name expressions are supported in their proven
subsets; dynamic function calls, unsafe field-symbol operations, and dynamic
database targets remain explicit diagnostics. Static Open SQL and ordinary internal-table loops
are also preserved when their targets are statically named; implicit-header-table
loops and local classes remain explicit diagnostics.
Composite fixtures under
`converter/test/fixtures/` cover nested includes, reusable FORM routines,
selection state, and seeded SQLite database behavior.

Output compatibility follows the converter version in generated headers:
patch releases keep the manifest and scaffold operation contract stable while
fixing diagnostics or incorrect lowering; minor releases may add supported
constructs and fields; a major release is required for incompatible manifest,
diagnostic, or scaffold-interface changes.
