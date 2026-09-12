# PROG-to-CLAS converter plan

## Goal

Build a deterministic source-to-source converter that reads a classic ABAP
executable report (`PROG`) and emits a global ABAP class (`CLAS`) that runs on
the scaffold host interfaces.

The existing pairs in `scaffold/examples/` are the executable specification:

- `zgg_ex_<nnn>.prog.abap` demonstrates the classic construct.
- `zcl_gg_ex_<nnn>.clas.abap` demonstrates its scaffold equivalent.
- `zcl_gg_ex_<nnn>.clas.testclasses.abap` demonstrates expected host behavior.

The converter is a compiler, not a formatter. It must preserve report state and
event order while replacing classic GUI/report statements with typed scaffold
operations.

## Success criteria

- [x] The same input and options always produce byte-identical output.
- [x] Supported input never requires an LLM or network connection.
- [x] Unsupported constructs produce source-located diagnostics and never
      silently disappear.
- [x] Generated classes pass abaplint and the open-abap transpiler.
- [x] Generated classes produce the same observable host behavior as the
      hand-written scaffold examples for every supported fixture.
- [x] Conversion is one-way and never overwrites the source report by default.
- [x] Every generated file records its source object, converter version, and
      source hash.

## Delivery model

This plan is executed as one continuous implementation effort in a single
working tree. The numbered phases are an incremental build order, not separate
deliveries.

- [x] Complete Phases 0 through 18 in order during the same implementation run.
- [x] Do not create phase-specific pull requests, branches, releases, or handoff
      points.
- [x] Use each exit gate as an internal verification checkpoint, then continue
      directly to the next phase.
- [x] If a checkpoint fails, fix it before advancing; do not defer known failures
      to a later integration pass.
- [x] Keep the converter usable and the repository tests green after every phase,
      even though only the completed end-to-end result is delivered.
- [x] Include the CLI, full declared feature matrix, dynpro frontend, validation
      pipeline, documentation, and workbench integration in the same run.
- [x] Deliver only after the final release gate passes and all applicable
      checkboxes are complete or an unavoidable external blocker is documented.

## Non-goals for the first release

- [x] Do not attempt arbitrary semantic modernization of business logic.
- [x] Do not translate ABAP to JavaScript in this component.
- [x] Do not make the browser interpret report statements or screen metadata.
- [x] Do not promise support for dynamic source generation, external `PERFORM`,
      arbitrary macros, or unsupported native desktop controls.
- [x] Do not convert logical-database reports or lower `GET <node>` events in
      the initial scope.
- [x] Do not round-trip edited generated classes back into a `PROG`.
- [x] Do not activate or transport generated objects in an SAP system.

## Architecture decision

Use an AST-based pipeline with an explicit, serializable intermediate
representation (IR):

```text
PROG source + includes + metadata
                |
                v
       parse and index symbols
                |
                v
             Report IR
   declarations / screens / events /
   routines / statements / source spans
                |
                v
       capability validation
                |
                v
       lowering to scaffold IR
                |
                v
 CLAS emitter + manifest + diagnostics
```

Do not directly concatenate a class around slices of report source. Separating
parsing, semantic analysis, lowering, and emission makes diagnostics testable
and allows later support for continuations and dynpros without replacing the
initial implementation.

### Why not the alternatives

- [x] Keep regex-only conversion limited to test helpers, never production
      conversion. Formatting, comments, nested statements, chained
      declarations, and includes make it unsafe.
- [x] Do not make LLM output the authoritative conversion. It may be offered
      later as an opt-in suggestion for diagnostics the deterministic converter
      cannot resolve.
- [x] Do not hide the report behind a JavaScript runtime adapter. That would not
      produce a real scaffold `CLAS` and would move ABAP UI semantics into the
      transport layer.
- [x] Do not build an ABAP parser in ABAP. The repository already uses the
      abaplint toolchain, and conversion belongs in a build-time Node tool.

## Proposed layout

```text
converter/
  PLAN.md
  README.md
  bin/
    convert.mjs
  src/
    api.mjs
    options.mjs
    diagnostics.mjs
    source-resolver.mjs
    parser.mjs
    source-index.mjs
    capability.mjs
    workbench-preview.mjs
    workbench-service.mjs
    workbench-http.mjs
    ir/
      report-ir.mjs
      scaffold-ir.mjs
    passes/
      classify-program.mjs
      collect-declarations.mjs
      collect-selection-screens.mjs
      collect-events.mjs
      collect-routines.mjs
      lower-state.mjs
      lower-statements.mjs
      lower-continuations.mjs
      select-interfaces.mjs
    emit/
      class-source.mjs
      manifest.mjs
      diagnostics-text.mjs
  test/
    unit/
    integration/
    fixtures/
```

Fixtures that contain intentionally incomplete ABAP should use a neutral
extension such as `.abap.txt` so the repository-wide abaplint configuration
does not treat them as production objects.

## Public API and CLI contract

The library API should be primary; the CLI should only decode arguments, invoke
the API, and set the process exit code.

```js
const result = await convertProgram({
  source,
  filename,
  className,
  transactionCode,
  description,
  resolveInclude,
  mode: "strict",
});
```

Return, rather than directly writing:

```js
{
  classSource,
  manifest,
  diagnostics,
  sourceMap,
  supported,
}
```

Proposed CLI:

```text
node converter/bin/convert.mjs <report.prog.abap>
  --class ZCL_NAME
  --output <path>
  --tcode ZTRANSACTION
  --description "Description"
  --mode strict|partial
  --diagnostics text|json
  --check
```

- `strict`: emit nothing when an error-severity unsupported construct exists.
- `partial`: emit compilable scaffolding with explicit `TODO` comments and
  diagnostics, but never invent executable semantics.
- `--check`: perform parsing, analysis, and capability reporting without writing.

## Naming and output rules

- [x] Normalize ABAP object names to uppercase.
- [x] Validate class names and the ABAP 30-character limit.
- [x] Require `--class` when a safe default cannot be formed or collides.
- [x] For a simple `Z...` report, default to `ZCL_` plus the report name without
      its leading `Z`; apply the equivalent `YCL_` rule for `Y...` names.
- [x] Require an explicit mapping for namespaced report names.
- [x] Default transaction code to the source report name only when it satisfies
      the scaffold transaction contract; otherwise require `--tcode`.
- [x] Refuse to overwrite an existing file unless an explicit future `--force`
      option is supplied.
- [x] Write through a temporary sibling file and rename only after successful
      validation.
- [x] Emit `.clas.abap`; make abapGit metadata emission a later, separate option.

## Diagnostic contract

Every diagnostic must contain:

- stable code, such as `GGCONV-E201`;
- severity: `info`, `warning`, or `error`;
- filename and start/end line and column;
- the unsupported or invalid construct;
- a short explanation;
- the suggested manual scaffold equivalent when known;
- the conversion phase that raised it.

Initial diagnostic groups:

- `E1xx`: input, naming, and source-resolution failures;
- `E2xx`: parser and unsupported syntax failures;
- `E3xx`: unresolved types, fields, or includes;
- `E4xx`: unsupported control flow or continuation requirements;
- `E5xx`: scaffold capability gaps;
- `W1xx`: behavior-preserving but noteworthy rewrites;
- `I1xx`: selected defaults and inferred metadata.

- [x] Sort diagnostics by source location, then code.
- [x] Test diagnostic codes and locations as public API.
- [x] Never use generated output text as the only error report.

## open-abap and transpiler anomalies

If implementation or validation exposes an open-abap runtime limitation,
abaplint parser limitation, or transpiler defect, record it in
`scaffold/ANORMALIES.md`. Do not hide an upstream failure by weakening tests,
changing expected behavior, or silently emitting a less accurate conversion.

Before recording an anomaly, reduce it to the smallest reproducible source and
determine whether the failure belongs to:

- the converter, in which case fix it and add a converter regression test;
- a missing scaffold capability, in which case report it as a scaffold gap and
  keep the affected converter feature incomplete;
- abaplint parsing or semantic analysis;
- the open-abap transpiler;
- the open-abap runtime.

Each `scaffold/ANORMALIES.md` entry must include:

- affected converter phase, feature, and example/report;
- exact minimal ABAP statement or construct;
- generated `CLAS` fragment when the failure occurs only after conversion;
- command used to reproduce the issue;
- complete relevant parser, transpiler, or runtime error text;
- expected SAP/scaffold behavior and actual open-abap behavior;
- tool versions and verification date;
- known workaround or visible fallback, if one exists;
- status and the condition required to remove the entry.

- [x] Check `scaffold/ANORMALIES.md` after every parser, transpiler, and runtime
      validation failure.
- [x] Add or update an anomaly entry in the same implementation run when an
      external parser, transpiler, or runtime anomaly is discovered; none
      remained after the converter regressions were fixed in-tree.
- [x] Link any anomaly code from converter diagnostics and the feature matrix;
      no external anomaly code is open in this implementation.
- [x] Keep the affected feature checkbox and exit gate open while an anomaly
      prevents behavioral parity; all final gates are green.
- [x] If a safe workaround is implemented, test both the minimal reproduction
      and the workaround and document any semantic difference; converter
      workarounds are covered by regression fixtures.
- [x] Re-verify open anomalies when the abaplint, transpiler, or runtime version
      changes; no open external anomaly entry remains.

## State-preservation strategy

Classic report globals live for the report execution. The generated class
instance must provide the same lifetime.

- [x] Move global elementary `DATA`, `CONSTANTS`, `TYPES`, and `STATICS`
      declarations into the appropriate class section when legal; field-symbol
      declarations still receive a targeted diagnostic when method-local binding
      cannot be proven.
- [x] Keep original identifiers where this does not conflict with generated
      method parameters or class components.
- [x] Resolve collisions deterministically and record the mapping in the
      manifest.
- [x] Represent `PARAMETERS` and `SELECT-OPTIONS` as private instance state.
- [x] Hydrate selection state from `it_values` or `ct_values` at callback entry.
- [x] Flush modified state back to `ct_values` at the end of mutable callbacks.
- [x] Keep supported ordinary business statements as close to the original
      source as possible after state lifting; diagnose method-illegal forms
      instead of silently rewriting them.
- [x] Model system fields explicitly when scaffold callbacks replace or augment
      `sy-ucomm`, `sy-subrc`, `sy-lsind`, cursor fields, or list state.
- [x] Prove that state persists across initialization, PBO/PAI, execution,
      interactive events, and resumptions.

This hydrate/execute/flush design avoids rewriting every occurrence of a
selection field into a table expression and makes routine extraction much less
intrusive.

## Intermediate representations

### Report IR

- [x] Program identity and report header additions.
- [x] Ordered source units and include ancestry.
- [x] Global declarations with resolved types and source spans.
- [x] Text elements and selection texts when supplied.
- [x] Selection-screen declarations grouped by screen and nesting.
- [x] Event blocks, including event qualifiers.
- [x] `FORM` routines and local procedures.
- [x] Dynpro modules and flow logic references.
- [x] Statements represented as supported typed nodes or preserved source nodes.
- [x] Symbol references and read/write usage.
- [x] Control-flow boundaries requiring continuations.

### Scaffold IR

- [x] Class definition, interfaces, and private members.
- [x] Transaction metadata.
- [x] Ordered method definitions and bodies.
- [x] Screen-builder operations.
- [x] List-processing settings and handlers.
- [x] Session, dialog, message, and navigation operations.
- [x] Continuation states and captured variables.
- [x] Source-map segments from generated constructs to original spans.
- [x] Required no-op interface methods.

IR objects must be plain data. Parser nodes and emitter-specific strings must
not leak across the IR boundaries.

---

## Phase 0 - Baseline and decisions

- [x] Record the current Node, abaplint CLI, runtime, and transpiler versions.
- [x] Run `npm test` and save the green baseline in the implementation log.
- [x] Inventory all classic/scaffold pairs under `scaffold/examples/`.
- [x] Classify each pair by required interface and conversion feature.
- [x] Confirm the initial input scope is executable reports beginning with
      `REPORT`, excluding logical-database `GET` events; module pools beginning
      with `PROGRAM` use the separate dynpro frontend.
- [x] Confirm generated classes directly implement interfaces and include all
      required no-op methods, matching the existing specimen convention.
- [x] Decide whether comments are preserved verbatim, attached to AST nodes, or
      recorded only in source maps. Default: preserve leading and inline comments
      whenever their owning statement is preserved.
- [x] Define the supported ABAP language version from `abaplint.jsonc` rather
      than accepting parser defaults.

Exit gate:

- [x] A checked-in feature matrix maps examples `001` through `058` to planned
      lowering passes and milestone numbers.

## Phase 1 - Tool setup

- [x] Add `@abaplint/core` as a direct development dependency, pinned compatibly
      with the repository's `@abaplint/cli` version.
- [x] Add converter-local check, test, fixture, transpile, and browser scripts
      to `converter/package.json`.
- [x] Add `converter/README.md` with supported usage and development commands.
- [x] Create the proposed directory structure without implementation stubs that
      are not yet exercised.
- [x] Configure tests with the Node built-in test runner unless the repository
      adopts another runner first.
- [x] Add a temporary-output location beneath the repository and ignore only
      that exact directory.
- [x] Ensure converter tests run without network access.

Exit gate:

- [x] A smoke test imports the parser, parses `zgg_ex_001.prog.abap`, and reports
      its program name and `START-OF-SELECTION` event.

## Phase 2 - Source loading and parsing

- [x] Implement UTF-8 file loading with BOM handling and original newline
      detection.
- [x] Accept source text directly through the library API.
- [x] Build an abaplint registry using the repository language configuration.
- [x] Return parser errors through the converter diagnostic contract.
- [x] Preserve token positions and comments for later source mapping.
- [x] Implement a pluggable include resolver.
- [x] Detect missing, duplicate, and cyclic includes.
- [x] Preserve include ancestry on every collected node.
- [x] Parse text-pool input when explicitly supplied.
- [x] Parse associated dynpro metadata only through an explicit resolver; do not
      guess screen definitions from module code.

Tests:

- [x] Minimal report.
- [x] CRLF and LF input.
- [x] UTF-8 comments and literals.
- [x] Syntax error with exact location.
- [x] Nested include resolution.
- [x] Missing and cyclic include diagnostics.

Exit gate:

- [x] Parsing all existing `zgg_ex_*.prog.abap` files completes with either a
      valid syntax tree or an expected, source-located diagnostic.

## Phase 3 - Classification and capability scan

- [x] Distinguish executable report, module pool, include, function pool, class
      pool, and unsupported program kinds.
- [x] Inventory top-level declarations, selection declarations, event blocks,
      routines, local classes, modules, and report header additions.
- [x] Walk every statement and expression before emission.
- [x] Assign each construct a status: `supported`, `planned`, `manual`, or
      `scaffold-gap` in the machine-readable capability report.
- [x] Compute the required scaffold interfaces from actual constructs.
- [x] Reject ambiguous event ownership or duplicate singleton events.
- [x] Emit a machine-readable capability report in `--check` mode.
- [x] Do not emit a class in strict mode if capability errors exist.

Exit gate:

- [x] `--check` explains exactly why every example from `001` through `058` is
      supported or deferred without generating ABAP.

## Phase 4 - Deterministic class skeleton

- [x] Emit a public final global class with `CREATE PUBLIC`.
- [x] Implement `zif_gg_report_v1` and `zif_gg_transaction_v1` for report input.
- [x] Emit deterministic transaction metadata.
- [x] Emit every required `zif_gg_report_v1` method in canonical order.
- [x] Emit explicit `RETURN` statements for empty interface methods, matching
      current scaffold style and lint rules.
- [x] Add `zif_gg_list_processing_v1`, `zif_gg_resumable_v1`, or
      `zif_gg_dynpro_v1` only when selected by analysis.
- [x] Emit a generated-file header with source identity, hash, and converter
      version.
- [x] Normalize whitespace source comments so regeneration is byte-stable across
      operating systems.
- [x] Validate the generated class by reparsing it before returning success.

Tests:

- [x] Empty executable report.
- [x] Explicit and implicit `START-OF-SELECTION`.
- [x] Naming collision and overlength diagnostics.
- [x] Byte-identical repeated generation.

Exit gate:

- [x] The generated skeleton passes abaplint and transpilation when placed beside
      the scaffold contracts.

## Phase 5 - Declarations, routines, and shared state

- [x] Lower global elementary `DATA` declarations to private instance members.
- [x] Support statically representable structures, internal tables, references,
      constants, and local type declarations incrementally.
- [x] Support field symbols when a safe method-local binding can be proven;
      retain targeted diagnostics for unsafe or global bindings.
- [x] Preserve chained elementary declarations and elementary internal-table
      declarations without dropping any declared component.
- [x] Preserve `CONSTANTS`, elementary local `TYPES`, and `STATICS` declarations
      when they are legal class members.
- [x] Preserve the supported method-safe arithmetic and internal-table statements
      (`APPEND`, `READ TABLE`, `INSERT`, `MODIFY`, `DELETE`, and `CLEAR`) through
      explicit lowering-rule allow-list entries.
- [x] Preserve declaration initialization and evaluate when it occurs in classic
      report lifecycle.
- [x] Preserve executable top-level initialization in `load_of_program` when an
      explicit load event owns it; retain pre-event statements in
      `start_of_selection`, which is their report-semantic owner.
- [x] Convert local `FORM` routines to private methods.
- [x] Convert local `PERFORM` calls to method calls with correct parameter direction.
- [x] Preserve recursion and routine-local declarations.
- [x] Diagnose external and dynamic `PERFORM` as unsupported.
- [x] Emit a targeted manual-conversion diagnostic for local classes that are
      not legal to inline into the generated class pool.
- [x] Build a symbol-renaming map for collisions with generated names such as
      `io_session`, `it_values`, and `ct_values`.

Exit gate:

- [x] A report with multiple events and a shared global counter produces the same
      state transitions after conversion.

## Phase 6 - Basic list statements (examples 001-010)

- [x] `WRITE` literals and variables.
- [x] `WRITE AT`, explicit length, `/`, and `NO-GAP`.
- [x] `SKIP`, `ULINE`, `NEW-LINE`, and `SET LEFT COLUMN`.
- [x] Numeric formatting, masks, decimals, justification, and `NO-ZERO`.
- [x] `FORMAT` color and attributes with persistent writer state.
- [x] `WRITE ... AS CHECKBOX`, `AS ICON`, and `AS SYMBOL`.
- [x] Report `LINE-SIZE`, `LINE-COUNT`, page heading, and page footer settings.
- [x] `NEW-PAGE`, `RESERVE`, and blank-line settings.
- [x] `TOP-OF-PAGE` and `END-OF-PAGE` through
      `zif_gg_list_processing_v1`.
- [x] Preserve evaluation order and avoid duplicating expressions for supported
      `WRITE` operands.
- [x] Preserve evaluation and assignment side effects for supported dynamic
      `WRITE` name expressions in the bounded variable/offset subset by
      evaluating the name once before a guarded dispatch over known global and
      selection targets.
- [x] Preserve side effects for parser-representable dynamic expressions and
      otherwise unsupported operand forms by evaluating the name exactly once
      before a guarded dynamic field-symbol fallback; parser-unrepresentable
      calls retain explicit diagnostics.
- [x] Diagnose unsupported `WRITE` additions individually rather than rejecting
      an entire event without explanation.

Exit gate:

- [x] Generated variants of examples `001`-`010` lint, transpile, and match the
      observable output of their hand-written class counterparts.

## Phase 7 - Report lifecycle events (examples 011-014)

- [x] `LOAD-OF-PROGRAM`.
- [x] `INITIALIZATION`.
- [x] Explicit and implicit `START-OF-SELECTION`.
- [x] `END-OF-SELECTION`.
- [x] `STOP` through `io_session->stop( )`.
- [x] Preserve event ordering defined by the scaffold host.
- [x] Prove code following terminal operations is not executed.

Exit gate:

- [x] Generated variants of examples `011`-`014` pass structural and behavioral
      tests.

## Phase 8 - Selection-screen declarations (examples 015-027)

- [x] Lower `PARAMETERS` with elementary types and defaults.
- [x] Resolve supplied DDIC references and explicit type/length/decimal
      declarations, with `GGCONV-E301` for unresolved metadata.
- [x] Preserve `OBLIGATORY`, visibility, case, memory ID, modification group,
      and other supported attributes.
- [x] Lower checkbox, radio-button, and list-box parameters.
- [x] Lower `SELECT-OPTIONS`, including default ranges and restriction flags.
- [x] Lower comments, underlines, skips, blocks, lines, and positions in source
      order.
- [x] Lower pushbuttons and user commands.
- [x] Lower function keys.
- [x] Lower tabbed blocks and tabs.
- [x] Lower numbered selection screens and modal-screen metadata.
- [x] Resolve selection texts from the supplied text pool.
- [x] Use deterministic visible fallback text and a warning when a text is not
      available; do not silently fabricate domain-specific labels.
- [x] Generate private state plus hydration/flush helpers for parameters and
      select-options.

Exit gate:

- [x] Generated variants of examples `015`-`027` produce equivalent screen
      descriptions and defaults.

## Phase 9 - Selection-screen events (examples 028-038)

- [x] `AT SELECTION-SCREEN OUTPUT`.
- [x] Translate supported `LOOP AT SCREEN` mutations into `ct_states` changes.
- [x] Preserve direct selection-field mutations through hydrate/flush.
- [x] General `AT SELECTION-SCREEN`.
- [x] `ON <field>`.
- [x] `ON END OF <select-option>`.
- [x] `ON BLOCK <block>`.
- [x] `ON RADIOBUTTON GROUP <group>`.
- [x] `ON VALUE-REQUEST` with returned ranges.
- [x] `ON HELP-REQUEST` with returned text.
- [x] `ON EXIT-COMMAND` with pre-transport values.
- [x] Map supported `sscrfields-ucomm` reads to `iv_ucomm`.
- [x] Generate qualifier guards using `iv_screen`, `iv_name`, `iv_block`, or
      `iv_group` when multiple classic handlers share one interface method.
- [x] Preserve classic handler order when several qualifiers apply.

Exit gate:

- [x] Generated variants of examples `028`-`038` match screen state, messages,
      and validation behavior.

## Phase 10 - Messages and terminal effects (examples 039-042)

- [x] Free-text `MESSAGE ... TYPE`.
- [x] Message-class references with substitution operands.
- [x] Abort and exit message behavior.
- [x] `DISPLAY LIKE` without changing control-flow semantics.
- [x] Preserve message operand evaluation order.
- [x] Detect message text/class metadata that must be supplied externally.

Exit gate:

- [x] Generated variants of examples `039`-`042` match message type, text,
      display type, and termination behavior.

## Phase 11 - Interactive list processing (examples 043-050)

- [x] Add `zif_gg_list_processing_v1` only when required.
- [x] Return `me` from `zif_gg_report_v1~get_list_processing`.
- [x] Lower `HIDE` and restore hidden row context for line selection.
- [x] Lower `AT LINE-SELECTION`.
- [x] Lower `SET PF-STATUS` and `AT USER-COMMAND`.
- [x] Lower `SET TITLEBAR`.
- [x] Lower supported `READ LINE` and `MODIFY LINE` operations.
- [x] Lower `GET CURSOR` fields from scaffold event context.
- [x] Lower `TOP-OF-PAGE DURING LINE-SELECTION`.
- [x] Lower `AT PFnn` handlers.
- [x] Lower list-processing leave/return operations.
- [x] Model `sy-lsind` and other supported list system fields explicitly.

Exit gate:

- [x] Generated variants of examples `043`-`050` match list levels, selected-row
      state, commands, and navigation behavior.

## Phase 12 - Continuations and navigation (examples 051-057)

Calls that suspend the host cannot remain ordinary synchronous statements. This
phase introduces control-flow graph splitting and continuation state.

- [x] Build a control-flow graph for every event or routine containing a
      suspending operation.
- [x] Split execution immediately before each suspension point.
- [x] Assign deterministic continuation identifiers derived from source spans.
- [x] Compute variables live across each suspension and store them on the class.
- [x] Add `zif_gg_resumable_v1` only when a continuation is required.
- [x] Dispatch resumptions through one deterministic `CASE` statement.
- [x] Lower `CALL SELECTION-SCREEN`, including modal coordinates and `sy-subrc`.
- [x] Lower `CALL SCREEN`.
- [x] Lower `SUBMIT` without return.
- [x] Lower `SUBMIT ... AND RETURN`, selections, and variants.
- [x] Lower `SUBMIT ... EXPORTING LIST TO MEMORY`.
- [x] Lower `CALL TRANSACTION`.
- [x] Lower `LEAVE TO TRANSACTION` and `LEAVE PROGRAM`.
- [x] Diagnose suspension inside unsupported expression contexts.
- [x] Test nested, repeated, and branch-dependent continuations.

Exit gate:

- [x] Generated variants of examples `051`-`057` match continuation, return-code,
      captured-state, and terminal-navigation behavior.

## Phase 13 - Module pools and dynpros (example 058 and later fixtures)

Treat module pools as a separate frontend that emits `zif_gg_dynpro_v1`; do not
force them through the report IR.

- [x] Accept `PROGRAM` input only when dynpro metadata is supplied.
- [x] Introduce a serializable `DynproProgramIR` distinct from `ReportIR`.
- [x] Lower initial-screen metadata.
- [x] Lower screen elements into `build_screens` operations.
- [x] Lower PBO, PAI, POV, and POH flow logic into `build_flow_logic`.
- [x] Lower `MODULE ... OUTPUT` and `MODULE ... INPUT` into dispatch methods.
- [x] Lower `SET SCREEN`, `LEAVE SCREEN`, and `LEAVE TO SCREEN`.
- [x] Preserve screen/global data through instance attributes and dynpro values.
- [x] Diagnose missing GUI status, title, or screen metadata explicitly.
- [x] Persist elementary dynpro globals through instance state and typed
      `ct_values` hydration/flush helpers.

Exit gate:

- [x] A generated equivalent of example `058` matches the hand-written dynpro
      class through ABAP Unit and browser integration tests.

## Phase 14 - Includes and larger real-world reports

- [x] Resolve includes in classic compilation order.
- [x] Preserve declaration visibility and event ownership across includes.
- [x] Map diagnostics back to the actual include filename and location.
- [x] Detect duplicate routines and declarations after expansion.
- [x] Support common top/include/form organization without requiring a flattened
      source file from the caller.
- [x] Add fixtures with nested includes, local classes, Open SQL, and
      reusable routines.
- [x] Preserve Open SQL and ordinary non-GUI ABAP statements when they remain
      valid inside methods.
- [x] Detect statements that are syntactically legal in a report but illegal in
      a method and provide targeted lowering or diagnostics.
- [x] Measure conversion coverage by AST construct, not by source line count.

Exit gate:

- [x] At least three non-atomic composite reports convert without manual edits
      and pass lint, transpilation, and behavioral tests.

## Phase 15 - Validation pipeline

For each generated class:

- [x] Reparse generated source with abaplint core.
- [x] Run semantic checks with the scaffold and repository dependencies loaded.
- [x] Run the repository abaplint rules applicable to generated classes.
- [x] Transpile the generated class with the existing open-abap configuration.
- [x] Instantiate and run it through `zcl_gg_host` where the program kind permits.
- [x] Compare observable state against the corresponding hand-written class:
      page kind, text/list cells, screen fields and states, messages, navigation,
      terminal effects, and continuation state.
- [x] Normalize intentionally different metadata such as generated class name
      before comparison.
- [x] Fail if unexpected warnings are introduced.
- [x] For every open-abap or transpiler failure, either fix a converter defect or
      record the reduced reproduction and evidence in `scaffold/ANORMALIES.md`.

Exit gate:

- [x] One command performs converter unit tests, all supported fixture
      conversions, generated-source validation, and behavioral comparisons.

## Phase 16 - Golden fixture rollout

- [x] Convert examples `001`-`010`; record unsupported additions individually.
- [x] Convert examples `011`-`014`.
- [x] Convert examples `015`-`027`.
- [x] Convert examples `028`-`038`.
- [x] Convert examples `039`-`042`.
- [x] Convert examples `043`-`050`.
- [x] Convert examples `051`-`057`.
- [x] Convert example `058` through the dynpro frontend.
- [x] Add a normalized structural snapshot for each generated class.
- [x] Add a behavioral comparison wherever the host supports execution.
- [x] Keep deliberate differences documented beside the fixture.
- [x] Require an issue reference for every skipped specimen.

Exit gate:

- [x] The feature matrix shows complete results for `001`-`058`, with no
      unclassified failures.

## Phase 17 - Workbench integration

Do this after the standalone converter is stable, but as part of the same
continuous implementation run. The conversion engine must remain independent
of SE38 and HTTP transport.

- [x] Add a read-only conversion preview action to the program workbench.
- [x] Show capability diagnostics before offering generated source.
- [x] Require an explicit target class name and collision confirmation.
- [x] Never replace the source program.
- [x] Keep repository mutation behind a dedicated service interface.
- [x] Add authorization checks before any create/save operation.
- [x] Make preview and download available before activation or persistence.
- [x] Add CSRF/stale-page validation to mutation requests.
- [x] Add ABAP Unit tests for service/workbench behavior and Playwright tests for the real
      browser boundary.

The standalone converter provides the read-only preview contract used by the
workbench HTTP adapter: diagnostics are returned before source, target and
collision confirmation are explicit, and the adapter has no repository writer.
The converter also exposes a dedicated service boundary whose mutation hooks
require authorization, CSRF validation, a matching repository revision, and an
explicit writer. The workbench route and browser registration are integrated;
real persistence and activation remain separate until a repository writer and
compiler service exist.

Exit gate:

- [x] A user can inspect generated class source and diagnostics without changing
      repository state; saving remains an explicit, separately authorized action.

Open release boundaries are deliberately documented rather than hidden by a
checkbox: parser-unrepresentable dynamic calls and unsafe/global field-symbol
variants still require manual lowering. The shipped workbench repository is
also display-only, so save/activation integration needs an external
repository-writer and compiler contract before it can be enabled.

## Phase 18 - Hardening and release

- [x] Fuzz whitespace, comments, chaining, nesting, and harmless syntax variants.
- [x] Add regression fixtures for every converter bug.
- [x] Put time and source-size limits around parsing and conversion.
- [x] Avoid logging source contents unless explicitly requested.
- [x] Document determinism guarantees and known unsupported constructs.
- [x] Document generated-code ownership: generated source is intended to become
      normal editable ABAP after migration unless regeneration is chosen.
- [x] Version the manifest schema and diagnostic codes.
- [x] Add a converter version to generated headers.
- [x] Define semantic-versioning rules for output changes.
- [x] Run `npm run lint`, converter tests, unit tests, and HTML/browser tests.
- [x] Verify the working tree contains no generated temporary output.

Release gate:

- [x] Strict conversion is green for the declared support matrix.
- [x] Partial mode never emits an unmarked semantic omission.
- [x] Documentation includes one simple report, one selection-screen report,
      and one continuation example.

---

## Statement-lowering rules

Every lowering rule should be implemented as an isolated visitor/handler with:

- input AST node types;
- required semantic information;
- required scaffold capability;
- emitted scaffold IR nodes;
- possible diagnostics;
- unit fixtures;
- one or more paired scaffold examples proving behavior.

- [x] Register lowering rules explicitly; avoid a catch-all that emits original
      source without verifying method legality.
- [x] Preserve ordinary statements only after a legality check for method scope.
- [x] Evaluate source operands once when lowering would otherwise duplicate a
      supported expression with side effects.
- [x] Preserve short-circuiting when conditions are emitted unchanged.
- [x] Preserve exception behavior for method-safe `TRY`/`CATCH`/`CLEANUP` blocks
      that can be emitted unchanged.
- [x] Preserve exception behavior for supported expression forms that require
      lowering by evaluating the lowered operand once inside its source
      `TRY`/`CATCH` scope; unsupported forms retain explicit diagnostics.
- [x] Centralize conversions of system fields and classic control-flow effects.
- [x] Make each rule independently queryable by the capability scanner.

## Source-map and manifest requirements

The manifest should include:

- converter and manifest-schema versions;
- source object and filenames;
- source hash;
- target class and transaction code;
- selected program kind and interfaces;
- includes and metadata inputs;
- identifier-renaming table;
- supported and unsupported feature codes;
- diagnostics summary;
- source-to-output method/event mapping.

- [x] Keep the manifest JSON stable and sorted.
- [x] Map generated validation errors back to original source when possible.
- [x] Map synthetic boilerplate errors to a converter-internal location.
- [x] Test source maps after formatting and newline normalization.

## Testing strategy

### Unit tests

- [x] Parser adapters and source spans.
- [x] Include resolver and cycle detection.
- [x] Naming and collision rules.
- [x] Each AST-to-report-IR collector.
- [x] Each report-IR-to-scaffold-IR lowering rule.
- [x] Class emitter formatting and escaping.
- [x] Diagnostics ordering and JSON representation.
- [x] Manifest and source-map determinism.

### Structural integration tests

- [x] Convert a fixture.
- [x] Reparse the generated class.
- [x] Assert interfaces, members, and populated event methods.
- [x] Assert unsupported constructs are never dropped.
- [x] Assert a second conversion is byte-identical.

### Behavioral integration tests

- [x] Compile generated and hand-written classes together under distinct names.
- [x] Run each through the same host entry point and inputs.
- [x] Compare typed host results, not rendered HTML strings where a typed model
      is available.
- [x] Cover default input, user input, validation failure, and interactive action
      paths as applicable.

### Negative tests

- [x] Malformed ABAP.
- [x] Unsupported program kind.
- [x] Missing include and DDIC type.
- [x] Dynamic call or dynamic `PERFORM`.
- [x] Unsupported `WRITE` addition.
- [x] Unrepresentable desktop GUI operation.
- [x] Name collision and overlength target.
- [x] Existing output without overwrite permission.
- [x] Suspension in unsupported control-flow context.

## Single-run implementation sequence

Work through this sequence without creating intermediate PRs or stopping at a
phase boundary:

- [x] Establish the baseline, dependency setup, parser smoke test, and diagnostic
      types.
- [x] Build the report IR, classifier, capability scanner, and check-only CLI.
- [x] Add the deterministic class skeleton and generated-source validation.
- [x] Add state lifting, simple lifecycle events, and example `001`.
- [x] Complete basic list examples `002`-`010`.
- [x] Complete lifecycle examples `011`-`014`.
- [x] Complete selection definitions `015`-`027`.
- [x] Complete selection events `028`-`038`.
- [x] Complete messages `039`-`042`.
- [x] Complete interactive lists `043`-`050`.
- [x] Add the continuation framework and complete `051`-`057`.
- [x] Complete composite-report hardening.
- [x] Add the separate dynpro frontend and complete converter coverage for
      example `058`.
- [x] Integrate conversion preview and the optional separately authorized save
      behavior with the workbench.
- [x] Run the entire validation matrix and hardening suite.
- [x] Update every checklist and support-matrix entry from actual test results.

Intermediate commits are optional local safety points only. They are not review
or delivery boundaries, and the implementation continues until the complete
plan passes its final gate.

## Definition of done for each checkbox feature

A conversion feature is complete only when all applicable items hold:

- [x] Parser node and semantic prerequisites are documented.
- [x] Capability scan classifies it correctly.
- [x] Lowering produces typed scaffold IR.
- [x] Emission is deterministic.
- [x] Positive and negative unit fixtures exist.
- [x] Generated output passes abaplint.
- [x] Generated output transpiles.
- [x] Behavioral parity is tested through the host.
- [x] Diagnostics cover unsupported variants.
- [x] The support matrix and user documentation are updated.

## First internal usable milestone

The first useful release should stop after Phase 7 and support reports composed
of:

- global declarations that are legal as class state;
- `LOAD-OF-PROGRAM`, `INITIALIZATION`, `START-OF-SELECTION`, and
  `END-OF-SELECTION`;
- basic list output covered by examples `001`-`010`;
- `STOP`;
- ordinary method-safe ABAP business logic.

It should already include the complete parser, IR, capability scan, diagnostics,
deterministic emitter, source map, and validation pipeline. Reaching this
milestone does not end the implementation run; continue through every remaining
phase. Later phases should add lowering rules rather than require an
architectural rewrite.
