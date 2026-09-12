# Converter implementation log

## Baseline and toolchain

- Node: `v22.18.0`
- `@abaplint/cli`: `2.120.50`
- `@abaplint/core`: `2.120.50`
- `@abaplint/runtime`: `2.13.85`
- `@abaplint/transpiler-cli`: `2.13.85`
- Language configuration: repository `abaplint.jsonc`, `open-abap` release and
  `Normal` language mode.
- Fixture inventory: 149 `.prog.abap` sources; the initial matrix contains all
  58 reports `zgg_ex_001` through `zgg_ex_058`.

## Verification checkpoints

- `npm --prefix converter run test:unit` - green.
- `npm --prefix converter run check` - green for `zgg_ex_001`.
- `npm --prefix converter run fixtures` - green for all 149 repository fixtures; 8 are
  explicitly reported as partial-mode conversions (unsupported DDIC and
  advanced-construct cases remain visible in diagnostics).
- Generated classes for all 149 repository fixtures reparse with abaplint core in
  partial mode; unsupported constructs remain explicit diagnostics/TODOs.
- `npm --prefix converter run transpile` validates all 149 generated classes with
  repository abaplint rules and the open-abap transpiler: 0 lint issues and
  `1,604` transpiled objects, including example 058 with explicit dynpro metadata
  and a typed FORM/PERFORM fixture.
- Local `FORM` routines now emit typed private methods; local `PERFORM` calls map
  `USING` to `EXPORTING` and `CHANGING`/`TABLES` to `CHANGING`, while dynamic and
  external calls remain explicit diagnostics. `CONSTANTS` and global `STATICS`
  are also represented in generated class state.
- Selection fields are lifted into private `mv_*` state with callback hydration
  and mutable-callback flushes; supplied DDIC metadata resolves `TABLES` and
  `FOR <table>-<field>` types, while missing metadata produces `GGCONV-E301`.
- Capability checks now classify program kinds, reject duplicate singleton
  events, preserve ordered qualified handlers, expose a machine-readable
  `--check` report, and diagnose nested suspension contexts.
- Message-class operands are tokenized outside literals so dynamic variables are
  preserved in `v1` through `v4`; local classes receive `GGCONV-E305` instead of
  being silently copied into the generated report class.
- The lowering boundary now exposes a serializable scaffold IR containing class
  definition, interfaces, members, ordered methods, transaction metadata,
  screen/list lowering metadata, continuation points, no-op methods, and source
  map segments.
- Chained elementary declarations and basic method-safe arithmetic/internal-table
  statements are retained through explicit allow-listed lowering rules. Dynpro
  elementary globals now hydrate and flush through `ct_values`; repeated
  top-level continuations each receive a resume-dispatch case.
- Message-class references now record `GGCONV-I101` when their text remains an
  external runtime dependency and produce `GGCONV-E306` when supplied message
  metadata omits the referenced class/number. Generated parser diagnostics carry
  an original source mapping where a method segment is available.
- `npm test` - green: abaplint reported 0 issues, ABAP Unit completed, and all
  214 Playwright browser tests passed.
- `npm --prefix converter run behavior` - green: generated classes for report examples
  `001`-`057` compiled beside their hand-written counterparts and matched typed
  `zcl_gg_host` results, including list output, selection state, messages,
  statuses, and navigation metadata. The run supplies fixture text pools,
  DDIC field metadata, listbox values, and GUI status metadata where those
  definitions are external to the classic source.
- The same behavior run now checks generated dynpro 058 `NEXT` and `BACK`
  transitions through `zcl_gg_host_dynpro`, including screen definitions, flow
  logic, and supplied status metadata.
- The behavior run also covers representative default, user-input,
  validation-failure, user-command, and PF-key scenarios.
- `npm --prefix converter run structural` - green for all 58 numbered fixtures; each
  normalized scaffold-IR shape is checked against a deterministic snapshot
  hash covering interfaces, members, operations, screens, continuations, and
  control-flow graph presence.
- `npm --prefix converter run warnings` - green; warning diagnostics are restricted to
  the documented deterministic selection-text fallback code `GGCONV-W101`.
- `npm --prefix converter run hardening` - green for whitespace, BOM/newline, comments,
  chained writes, nested control flow, deterministic regeneration, and source
  size limits.
- `npm --prefix converter run coverage` - green; all 853 parsed statements across 149
  repository fixtures are accounted for by AST kind and capability status,
  including the explicit module-pool and unresolved-DDIC gaps.
- Negative coverage includes an explicit desktop GUI call diagnostic; partial
  mode emits a marked TODO instead of inventing browser semantics.
- Repository sanity after the final converter changes: `npm run lint`,
  `npm run unit`, all converter JavaScript syntax checks, and `git diff --check`
  are green.
- Successful transpile/behavior validation removes both its work directory and
  the transpiler's `converter/.tmp` artifacts; the cleanup assertion is green.
- `npm --prefix converter test` is the single-run gate for converter unit tests,
  the 001-058 matrix, all repository fixture conversions, normalized structural
  snapshots, generated transpile validation, and report behavioral parity.
  The final run is green, including the expanded user-input/validation/
  interactive scenarios and the dynpro transition checks.
- Continuations now retain conditional control-stack context: nested IF/CASE
  resumptions close the suspended branch and skip sibling branches, while loop
  and exception suspensions remain explicit `GGCONV-E402` diagnostics. The
  behavior suite exercises a stateful selection-screen pause/resume round trip.
- Method-local elementary field symbols with a statically provable `ASSIGN`
  are preserved; global or dynamic field-symbol bindings remain `GGCONV-E501`.
- Lifecycle behavior now includes a generated shared-counter report across
  initialization/start/end events and a dynpro PBO/PAI instance-state round
  trip through `ct_values`.
- Include expansion follows classic compilation order, so declarations and
  FORM routines in nested includes retain their source visibility and event
  ownership. Composite fixtures cover nested includes, selection state,
  reusable routines, local-class diagnostics, and static Open SQL.
- Static Open SQL and ordinary internal-table loops are preserved through
  explicit rules. The behavioral suite seeds the scaffold SQLite test
  environment and verifies converted `ZSFLIGHT` rows through `zcl_gg_host`.
- Report-only implicit-header-table loops and unsupported function modules now
  receive targeted method-legality diagnostics instead of a false supported
  capability; regression fixtures are listed in `converter/test/fixtures/REGRESSIONS.md`.
- The strict numbered matrix now supplies its declared external metadata for
  examples `020`, `032`, and `058`; `check:matrix` reports 58/58
  strict-supported rows with no deferred specimens.

Structured local types, statically representable table/reference declarations,
and declaration-marker collision handling are covered by converter unit tests.
Supported WRITE operand emission preserves source order without duplicating
expressions, and unchanged boolean conditions retain short-circuit semantics.
The declaration-shape regression fixture also passes generated-source lint and
open-abap transpilation.
Method-safe `TRY`/`CATCH`/`CLEANUP` blocks are preserved through explicit control
flow rules and a generated exception-block regression fixture.
The pass-coverage unit suite directly exercises every report-IR collector and
every registered lowering rule, including their method-safe and diagnostic
boundaries.
The exported read-only workbench preview contract requires an explicit target,
blocks unconfirmed collisions, exposes diagnostics before generated source,
and accepts only a repository `getProgram` adapter with no mutation method.
The dedicated workbench service keeps mutation behind separate `save` and
`create` hooks; both require explicit authorization, CSRF validation, and a
matching repository revision before an adapter writer is called. Display-only
repositories return a visible capability diagnostic instead of mutating state.
Partial-mode lowering now emits a deterministic `TODO GGCONV-E501` marker for
every statement without a lowering rule, preventing unsupported statements from
silently disappearing from generated methods.
Dynamic `WRITE` operands now use a single-evaluation dispatch over known global
and selection targets. Balanced variable-offset/slice expressions are accepted
when they remain in the method-safe grammar; dynamic function calls and other
unsupported expressions receive a source-located `GGCONV-E501` diagnostic
before generated-source validation. Unit, transpile, and host behavior coverage
exercise both paths.

The converter validation gate covers all 149 repository fixture sources.
Report behavioral parity is green, dynpro behavioral parity for module-pool
example `058` is green when its explicit screen/flow/status metadata is supplied,
and the generated
058 class passes both ABAP Unit and the real HTTP/Playwright browser boundary.
The remaining release checks are unsafe or global field-symbol variants.
Supported lowered expressions and parser-representable unsupported dynamic
operands are evaluated once in their source exception scope. A partial-mode
dynamic field-symbol fallback preserves that evaluation before guarded output;
parser-unrepresentable dynamic calls keep an explicit diagnostic.

## Final verification run

- `npm --prefix converter test` - green with network-enabled dependency resolution:
  66 converter unit tests, 58/58 strict matrix rows, 149 fixture conversions,
  58 structural snapshots, warning/hardening/coverage checks, 1,604 transpiled
  objects, and 57 report plus dynpro behavioral parity.
- `npm --prefix converter run browser` - green: a disposable generated 058 class passed
  its generated ABAP Unit transitions and independent browser `NEXT`/`BACK`
  navigation through the HTTP host.
- `npm test` - green: 0 abaplint issues, ABAP Unit completed, and 214 browser
  tests passed.
- All converter JavaScript files pass `node --check`; generated validation
  directories and temporary converter artifacts are absent after the run.

## Workbench preview integration

- The workbench Tools menu now opens `/converter/preview` through a Node HTTP
  adapter backed by the read-only ABAP system repository.
- The adapter lists authorized programs, requires an explicit target class and
  collision confirmation, shows diagnostics before source, and exposes an
  explicit source download. It never replaces source or offers save/activation.
- When a host supplies a repository writer plus authorization and CSRF callbacks,
  the same adapter exposes an explicit save action after revision validation;
  the shipped display-only host intentionally does not supply those callbacks.
- The workbench HTML ABAP Unit test covers the registration link; Playwright
  coverage exercises navigation, diagnostics, collision confirmation, source
  inspection, download, and the visible read-only save boundary.
- Repository persistence and activation remain intentionally open until a
  dedicated writer/compiler contract is available.
