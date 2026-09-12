# PROG-to-CLAS converter

The converter is a deterministic, offline source-to-source tool for migrating
classic executable reports to the versioned scaffold interfaces in `scaffold/`.
The library API is the primary entry point:

```js
import { convertProgram } from "./src/api.mjs";

const result = await convertProgram({
  source: "REPORT zdemo.\nSTART-OF-SELECTION.\nWRITE 'hello'.\n",
  filename: "zdemo.prog.abap",
  mode: "strict",
});
```

`result` contains `classSource`, serializable `reportIR` and `scaffoldIR` values,
a stable JSON-ready `manifest`, source maps, diagnostics, and the `supported`
flag. Strict mode returns no class source when an error diagnostic exists.
Partial mode emits a compilable skeleton with explicit `TODO GGCONV-*` comments
for unsupported semantics.

Read-only workbench adapters can use `previewProgram` or
`previewRepositoryProgram` from `src/index.mjs`. The preview contract requires
an explicit target class, reports a collision before offering generated source,
and returns `repositoryChanged: false`; source is returned only when the caller
explicitly requests it after inspecting diagnostics. The adapter accepts only a
read-side `getProgram` callback and has no save or activation path. A real
workbench can wrap that adapter with `createWorkbenchService`; its separate
`save`/`create` methods require authorization, CSRF validation, a matching
repository revision, and an explicit writer before they can mutate anything.

The CLI is intentionally thin:

```text
node converter/bin/convert.mjs report.prog.abap --class ZCL_REPORT --output out/report.clas.abap
node converter/bin/convert.mjs report.prog.abap --check --diagnostics json
```

No network or model call is used during conversion. Includes are resolved by the
optional `resolveInclude(name, parentFilename)` callback or by deterministic
filesystem candidates. Generated files are never overwritten by default.

Selection texts can be supplied as a `Map`, object, or simple text-pool string
through `textPool`; unresolved `TEXT-*` keys remain deterministic and produce a
`GGCONV-W101` warning. Include content participates in the source hash.

Message-class references remain executable when the target ABAP message class
is available at runtime. Without `messageMetadata`, the converter records an
`GGCONV-I101` external-dependency diagnostic. Supplying a message map makes
missing class/number entries an actionable `GGCONV-E306` error instead:

```js
messageMetadata: { ZMSG: { "001": { text: "Value &1" } } },
```

DDIC-dependent declarations are explicit. Pass `ddicTypes` as a map when the
source uses `TABLES`, `TYPES ... TYPE <ddic>`, or `FOR <table>-<field>`:

```js
ddicTypes: {
  ZSFLIGHT: {
    type: "zsflight",
    fields: { CARRID: { type: "c", length: 3 } },
  },
}
```

Unresolved DDIC references produce `GGCONV-E301` rather than an invented type.
Generated selection callbacks hydrate private `mv_*` state from scaffold
values and flush changes back to `ct_values` for mutable callbacks.

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

Module pools are accepted only with explicit `dynproMetadata` or an
`resolveDynpro(metadataRequest)` callback. Metadata supplies screens, flow
logic, and module direction; source code is never used to invent dynpro
controls.

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
npm test
```

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
