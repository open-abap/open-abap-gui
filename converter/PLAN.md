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

- [ ] The same input and options always produce byte-identical output.
- [ ] Supported input never requires an LLM or network connection.
- [ ] Unsupported constructs produce source-located diagnostics and never
      silently disappear.
- [ ] Generated classes pass abaplint and the open-abap transpiler.
- [ ] Generated classes produce the same observable host behavior as the
      hand-written scaffold examples for every supported fixture.
- [ ] Conversion is one-way and never overwrites the source report by default.
- [ ] Every generated file records its source object, converter version, and
      source hash.

## Delivery model

This plan is executed as one continuous implementation effort in a single
working tree. The numbered phases are an incremental build order, not separate
deliveries.

- [ ] Complete Phases 0 through 19 in order during the same implementation run.
- [ ] Do not create phase-specific pull requests, branches, releases, or handoff
      points.
- [ ] Use each exit gate as an internal verification checkpoint, then continue
      directly to the next phase.
- [ ] If a checkpoint fails, fix it before advancing; do not defer known failures
      to a later integration pass.
- [ ] Keep the converter usable and the repository tests green after every phase,
      even though only the completed end-to-end result is delivered.
- [ ] Include the CLI, full declared feature matrix, dynpro frontend, validation
      pipeline, documentation, and workbench integration in the same run.
- [ ] Deliver only after the final release gate passes and all applicable
      checkboxes are complete or an unavoidable external blocker is documented.

## Non-goals for the first release

- [ ] Do not attempt arbitrary semantic modernization of business logic.
- [ ] Do not translate ABAP to JavaScript in this component.
- [ ] Do not make the browser interpret report statements or screen metadata.
- [ ] Do not promise support for dynamic source generation, external `PERFORM`,
      arbitrary macros, or unsupported native desktop controls.
- [ ] Do not round-trip edited generated classes back into a `PROG`.
- [ ] Do not activate or transport generated objects in an SAP system.

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

- [ ] Keep regex-only conversion limited to test helpers, never production
      conversion. Formatting, comments, nested statements, chained
      declarations, and includes make it unsafe.
- [ ] Do not make LLM output the authoritative conversion. It may be offered
      later as an opt-in suggestion for diagnostics the deterministic converter
      cannot resolve.
- [ ] Do not hide the report behind a JavaScript runtime adapter. That would not
      produce a real scaffold `CLAS` and would move ABAP UI semantics into the
      transport layer.
- [ ] Do not build an ABAP parser in ABAP. The repository already uses the
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

- [ ] Normalize ABAP object names to uppercase.
- [ ] Validate class names and the ABAP 30-character limit.
- [ ] Require `--class` when a safe default cannot be formed or collides.
- [ ] For a simple `Z...` report, default to `ZCL_` plus the report name without
      its leading `Z`; apply the equivalent `YCL_` rule for `Y...` names.
- [ ] Require an explicit mapping for namespaced report names.
- [ ] Default transaction code to the source report name only when it satisfies
      the scaffold transaction contract; otherwise require `--tcode`.
- [ ] Refuse to overwrite an existing file unless an explicit future `--force`
      option is supplied.
- [ ] Write through a temporary sibling file and rename only after successful
      validation.
- [ ] Emit `.clas.abap`; make abapGit metadata emission a later, separate option.

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

- [ ] Sort diagnostics by source location, then code.
- [ ] Test diagnostic codes and locations as public API.
- [ ] Never use generated output text as the only error report.

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

- [ ] Check `scaffold/ANORMALIES.md` after every parser, transpiler, and runtime
      validation failure.
- [ ] Add or update the anomaly entry in the same implementation run that
      discovers the issue.
- [ ] Link the anomaly code from converter diagnostics and the feature matrix.
- [ ] Keep the affected feature checkbox and exit gate open while the anomaly
      prevents behavioral parity.
- [ ] If a safe workaround is implemented, test both the minimal reproduction
      and the workaround and document any semantic difference.
- [ ] Re-verify open anomalies when the abaplint, transpiler, or runtime version
      changes; close only those no longer reproducible.

## State-preservation strategy

Classic report globals live for the report execution. The generated class
instance must provide the same lifetime.

- [ ] Move global `DATA`, `CONSTANTS`, `TYPES`, `STATICS`, and field-symbol
      declarations into the appropriate class section when legal.
- [ ] Keep original identifiers where this does not conflict with generated
      method parameters or class components.
- [ ] Resolve collisions deterministically and record the mapping in the
      manifest.
- [ ] Represent `PARAMETERS` and `SELECT-OPTIONS` as private instance state.
- [ ] Hydrate selection state from `it_values` or `ct_values` at callback entry.
- [ ] Flush modified state back to `ct_values` at the end of mutable callbacks.
- [ ] Keep ordinary business statements as close to the original source as
      possible after state lifting.
- [ ] Model system fields explicitly when scaffold callbacks replace or augment
      `sy-ucomm`, `sy-subrc`, `sy-lsind`, cursor fields, or list state.
- [ ] Prove that state persists across initialization, PBO/PAI, execution,
      interactive events, and resumptions.

This hydrate/execute/flush design avoids rewriting every occurrence of a
selection field into a table expression and makes routine extraction much less
intrusive.

## Intermediate representations

### Report IR

- [ ] Program identity and report header additions.
- [ ] Ordered source units and include ancestry.
- [ ] Global declarations with resolved types and source spans.
- [ ] Text elements and selection texts when supplied.
- [ ] Selection-screen declarations grouped by screen and nesting.
- [ ] Event blocks, including event qualifiers.
- [ ] `FORM` routines and local procedures.
- [ ] Dynpro modules and flow logic references.
- [ ] Statements represented as supported typed nodes or preserved source nodes.
- [ ] Symbol references and read/write usage.
- [ ] Control-flow boundaries requiring continuations.

### Scaffold IR

- [ ] Class definition, interfaces, and private members.
- [ ] Transaction metadata.
- [ ] Ordered method definitions and bodies.
- [ ] Screen-builder operations.
- [ ] List-processing settings and handlers.
- [ ] Session, dialog, message, and navigation operations.
- [ ] Continuation states and captured variables.
- [ ] Source-map segments from generated constructs to original spans.
- [ ] Required no-op interface methods.

IR objects must be plain data. Parser nodes and emitter-specific strings must
not leak across the IR boundaries.

---

## Phase 0 - Baseline and decisions

- [ ] Record the current Node, abaplint CLI, runtime, and transpiler versions.
- [ ] Run `npm test` and save the green baseline in the implementation log.
- [ ] Inventory all classic/scaffold pairs under `scaffold/examples/`.
- [ ] Classify each pair by required interface and conversion feature.
- [ ] Confirm the initial input scope is executable reports beginning with
      `REPORT`, not module pools beginning with `PROGRAM`.
- [ ] Confirm generated classes directly implement interfaces and include all
      required no-op methods, matching the existing specimen convention.
- [ ] Decide whether comments are preserved verbatim, attached to AST nodes, or
      recorded only in source maps. Default: preserve leading and inline comments
      whenever their owning statement is preserved.
- [ ] Define the supported ABAP language version from `abaplint.jsonc` rather
      than accepting parser defaults.

Exit gate:

- [ ] A checked-in feature matrix maps examples `001` through `058` to planned
      lowering passes and milestone numbers.

## Phase 1 - Tool setup

- [ ] Add `@abaplint/core` as a direct development dependency, pinned compatibly
      with the repository's `@abaplint/cli` version.
- [ ] Add `converter:check`, `converter:test`, and `converter:fixtures` scripts
      to `package.json`.
- [ ] Add `converter/README.md` with supported usage and development commands.
- [ ] Create the proposed directory structure without implementation stubs that
      are not yet exercised.
- [ ] Configure tests with the Node built-in test runner unless the repository
      adopts another runner first.
- [ ] Add a temporary-output location beneath the repository and ignore only
      that exact directory.
- [ ] Ensure converter tests run without network access.

Exit gate:

- [ ] A smoke test imports the parser, parses `zgg_ex_001.prog.abap`, and reports
      its program name and `START-OF-SELECTION` event.

## Phase 2 - Source loading and parsing

- [ ] Implement UTF-8 file loading with BOM handling and original newline
      detection.
- [ ] Accept source text directly through the library API.
- [ ] Build an abaplint registry using the repository language configuration.
- [ ] Return parser errors through the converter diagnostic contract.
- [ ] Preserve token positions and comments for later source mapping.
- [ ] Implement a pluggable include resolver.
- [ ] Detect missing, duplicate, and cyclic includes.
- [ ] Preserve include ancestry on every collected node.
- [ ] Parse text-pool input when explicitly supplied.
- [ ] Parse associated dynpro metadata only through an explicit resolver; do not
      guess screen definitions from module code.

Tests:

- [ ] Minimal report.
- [ ] CRLF and LF input.
- [ ] UTF-8 comments and literals.
- [ ] Syntax error with exact location.
- [ ] Nested include resolution.
- [ ] Missing and cyclic include diagnostics.

Exit gate:

- [ ] Parsing all existing `zgg_ex_*.prog.abap` files completes with either a
      valid syntax tree or an expected, source-located diagnostic.

## Phase 3 - Classification and capability scan

- [ ] Distinguish executable report, module pool, include, function pool, class
      pool, and unsupported program kinds.
- [ ] Inventory top-level declarations, selection declarations, event blocks,
      routines, local classes, modules, and report header additions.
- [ ] Walk every statement and expression before emission.
- [ ] Assign each construct a status: `supported`, `planned`, `manual`, or
      `scaffold-gap`.
- [ ] Compute the required scaffold interfaces from actual constructs.
- [ ] Reject ambiguous event ownership or duplicate singleton events.
- [ ] Emit a machine-readable capability report in `--check` mode.
- [ ] Do not emit a class in strict mode if capability errors exist.

Exit gate:

- [ ] `--check` explains exactly why every example from `001` through `058` is
      supported or deferred without generating ABAP.

## Phase 4 - Deterministic class skeleton

- [ ] Emit a public final global class with `CREATE PUBLIC`.
- [ ] Implement `zif_gg_report_v1` and `zif_gg_transaction_v1` for report input.
- [ ] Emit deterministic transaction metadata.
- [ ] Emit every required `zif_gg_report_v1` method in canonical order.
- [ ] Emit explicit `RETURN` statements for empty interface methods, matching
      current scaffold style and lint rules.
- [ ] Add `zif_gg_list_processing_v1`, `zif_gg_resumable_v1`, or
      `zif_gg_dynpro_v1` only when selected by analysis.
- [ ] Emit a generated-file header with source identity, hash, and converter
      version.
- [ ] Normalize whitespace source comments so regeneration is byte-stable across
      operating systems.
- [ ] Validate the generated class by reparsing it before returning success.

Tests:

- [ ] Empty executable report.
- [ ] Explicit and implicit `START-OF-SELECTION`.
- [ ] Naming collision and overlength diagnostics.
- [ ] Byte-identical repeated generation.

Exit gate:

- [ ] The generated skeleton passes abaplint and transpilation when placed beside
      the scaffold contracts.

## Phase 5 - Declarations, routines, and shared state

- [ ] Lower global elementary `DATA` declarations to private instance members.
- [ ] Support structures, internal tables, references, field symbols, constants,
      and local types incrementally.
- [ ] Preserve declaration initialization and evaluate when it occurs in classic
      report lifecycle.
- [ ] Move executable top-level initialization into `load_of_program` when that
      matches report semantics.
- [ ] Convert `FORM` routines to private methods.
- [ ] Convert `PERFORM` calls to method calls with correct parameter direction.
- [ ] Preserve recursion and routine-local declarations.
- [ ] Diagnose external and dynamic `PERFORM` as unsupported.
- [ ] Preserve local classes when legal inside the generated class pool, or emit
      a targeted manual-conversion diagnostic.
- [ ] Build a symbol-renaming map for collisions with generated names such as
      `io_session`, `it_values`, and `ct_values`.

Exit gate:

- [ ] A report with multiple events and a shared global counter produces the same
      state transitions after conversion.

## Phase 6 - Basic list statements (examples 001-010)

- [ ] `WRITE` literals and variables.
- [ ] `WRITE AT`, explicit length, `/`, and `NO-GAP`.
- [ ] `SKIP`, `ULINE`, `NEW-LINE`, and `SET LEFT COLUMN`.
- [ ] Numeric formatting, masks, decimals, justification, and `NO-ZERO`.
- [ ] `FORMAT` color and attributes with persistent writer state.
- [ ] `WRITE ... AS CHECKBOX`, `AS ICON`, and `AS SYMBOL`.
- [ ] Report `LINE-SIZE`, `LINE-COUNT`, page heading, and page footer settings.
- [ ] `NEW-PAGE`, `RESERVE`, and blank-line settings.
- [ ] `TOP-OF-PAGE` and `END-OF-PAGE` through
      `zif_gg_list_processing_v1`.
- [ ] Preserve evaluation order and side effects of every `WRITE` operand.
- [ ] Diagnose unsupported `WRITE` additions individually rather than rejecting
      an entire event without explanation.

Exit gate:

- [ ] Generated variants of examples `001`-`010` lint, transpile, and match the
      observable output of their hand-written class counterparts.

## Phase 7 - Report lifecycle events (examples 011-014)

- [ ] `LOAD-OF-PROGRAM`.
- [ ] `INITIALIZATION`.
- [ ] Explicit and implicit `START-OF-SELECTION`.
- [ ] `END-OF-SELECTION`.
- [ ] `STOP` through `io_session->stop( )`.
- [ ] Preserve event ordering defined by the scaffold host.
- [ ] Prove code following terminal operations is not executed.

Exit gate:

- [ ] Generated variants of examples `011`-`014` pass structural and behavioral
      tests.

## Phase 8 - Selection-screen declarations (examples 015-027)

- [ ] Lower `PARAMETERS` with elementary types and defaults.
- [ ] Resolve DDIC references and explicit type/length/decimal declarations.
- [ ] Preserve `OBLIGATORY`, visibility, case, memory ID, modification group,
      and other supported attributes.
- [ ] Lower checkbox, radio-button, and list-box parameters.
- [ ] Lower `SELECT-OPTIONS`, including default ranges and restriction flags.
- [ ] Lower comments, underlines, skips, blocks, lines, and positions in source
      order.
- [ ] Lower pushbuttons and user commands.
- [ ] Lower function keys.
- [ ] Lower tabbed blocks and tabs.
- [ ] Lower numbered selection screens and modal-screen metadata.
- [ ] Resolve selection texts from the supplied text pool.
- [ ] Use deterministic visible fallback text and a warning when a text is not
      available; do not silently fabricate domain-specific labels.
- [ ] Generate private state plus hydration/flush helpers for parameters and
      select-options.

Exit gate:

- [ ] Generated variants of examples `015`-`027` produce equivalent screen
      descriptions and defaults.

## Phase 9 - Selection-screen events (examples 028-038)

- [ ] `AT SELECTION-SCREEN OUTPUT`.
- [ ] Translate supported `LOOP AT SCREEN` mutations into `ct_states` changes.
- [ ] Preserve direct selection-field mutations through hydrate/flush.
- [ ] General `AT SELECTION-SCREEN`.
- [ ] `ON <field>`.
- [ ] `ON END OF <select-option>`.
- [ ] `ON BLOCK <block>`.
- [ ] `ON RADIOBUTTON GROUP <group>`.
- [ ] `ON VALUE-REQUEST` with returned ranges.
- [ ] `ON HELP-REQUEST` with returned text.
- [ ] `ON EXIT-COMMAND` with pre-transport values.
- [ ] Map supported `sscrfields-ucomm` reads to `iv_ucomm`.
- [ ] Generate qualifier guards using `iv_screen`, `iv_name`, `iv_block`, or
      `iv_group` when multiple classic handlers share one interface method.
- [ ] Preserve classic handler order when several qualifiers apply.

Exit gate:

- [ ] Generated variants of examples `028`-`038` match screen state, messages,
      and validation behavior.

## Phase 10 - Messages and terminal effects (examples 039-042)

- [ ] Free-text `MESSAGE ... TYPE`.
- [ ] Message-class references with substitution operands.
- [ ] Abort and exit message behavior.
- [ ] `DISPLAY LIKE` without changing control-flow semantics.
- [ ] Preserve message operand evaluation order.
- [ ] Detect message text/class metadata that must be supplied externally.

Exit gate:

- [ ] Generated variants of examples `039`-`042` match message type, text,
      display type, and termination behavior.

## Phase 11 - Interactive list processing (examples 043-050)

- [ ] Add `zif_gg_list_processing_v1` only when required.
- [ ] Return `me` from `zif_gg_report_v1~get_list_processing`.
- [ ] Lower `HIDE` and restore hidden row context for line selection.
- [ ] Lower `AT LINE-SELECTION`.
- [ ] Lower `SET PF-STATUS` and `AT USER-COMMAND`.
- [ ] Lower `SET TITLEBAR`.
- [ ] Lower supported `READ LINE` and `MODIFY LINE` operations.
- [ ] Lower `GET CURSOR` fields from scaffold event context.
- [ ] Lower `TOP-OF-PAGE DURING LINE-SELECTION`.
- [ ] Lower `AT PFnn` handlers.
- [ ] Lower list-processing leave/return operations.
- [ ] Model `sy-lsind` and other supported list system fields explicitly.

Exit gate:

- [ ] Generated variants of examples `043`-`050` match list levels, selected-row
      state, commands, and navigation behavior.

## Phase 12 - Continuations and navigation (examples 051-057)

Calls that suspend the host cannot remain ordinary synchronous statements. This
phase introduces control-flow graph splitting and continuation state.

- [ ] Build a control-flow graph for every event or routine containing a
      suspending operation.
- [ ] Split execution immediately before each suspension point.
- [ ] Assign deterministic continuation identifiers derived from source spans.
- [ ] Compute variables live across each suspension and store them on the class.
- [ ] Add `zif_gg_resumable_v1` only when a continuation is required.
- [ ] Dispatch resumptions through one deterministic `CASE` statement.
- [ ] Lower `CALL SELECTION-SCREEN`, including modal coordinates and `sy-subrc`.
- [ ] Lower `CALL SCREEN`.
- [ ] Lower `SUBMIT` without return.
- [ ] Lower `SUBMIT ... AND RETURN`, selections, and variants.
- [ ] Lower `SUBMIT ... EXPORTING LIST TO MEMORY`.
- [ ] Lower `CALL TRANSACTION`.
- [ ] Lower `LEAVE TO TRANSACTION` and `LEAVE PROGRAM`.
- [ ] Diagnose suspension inside unsupported expression contexts.
- [ ] Test nested, repeated, and branch-dependent continuations.

Exit gate:

- [ ] Generated variants of examples `051`-`057` match continuation, return-code,
      captured-state, and terminal-navigation behavior.

## Phase 13 - Logical databases

- [ ] Read the logical-database assignment from report metadata.
- [ ] Implement `get_logical_database`.
- [ ] Lower `GET <node>` with a guarded node dispatch.
- [ ] Lower `GET <node> LATE`.
- [ ] Bind the supplied record reference to the expected node type.
- [ ] Preserve state shared with start/end-of-selection.
- [ ] Diagnose logical-database metadata or node types that cannot be resolved.

Exit gate:

- [ ] All logical-database specimens in the existing plan pass host tests.

## Phase 14 - Module pools and dynpros (example 058 and later fixtures)

Treat module pools as a separate frontend that emits `zif_gg_dynpro_v1`; do not
force them through the report IR.

- [ ] Accept `PROGRAM` input only when dynpro metadata is supplied.
- [ ] Introduce a `DynproProgramIR` distinct from `ReportIR`.
- [ ] Lower initial-screen metadata.
- [ ] Lower screen elements into `build_screens` operations.
- [ ] Lower PBO, PAI, POV, and POH flow logic into `build_flow_logic`.
- [ ] Lower `MODULE ... OUTPUT` and `MODULE ... INPUT` into dispatch methods.
- [ ] Lower `SET SCREEN`, `LEAVE SCREEN`, and `LEAVE TO SCREEN`.
- [ ] Preserve screen/global data through instance attributes and dynpro values.
- [ ] Diagnose missing GUI status, title, or screen metadata explicitly.

Exit gate:

- [ ] A generated equivalent of example `058` matches the hand-written dynpro
      class through ABAP Unit and browser integration tests.

## Phase 15 - Includes and larger real-world reports

- [ ] Resolve includes in classic compilation order.
- [ ] Preserve declaration visibility and event ownership across includes.
- [ ] Map diagnostics back to the actual include filename and location.
- [ ] Detect duplicate routines and declarations after expansion.
- [ ] Support common top/include/form organization without requiring a flattened
      source file from the caller.
- [ ] Add fixtures with nested includes, local classes, database access, and
      reusable routines.
- [ ] Preserve Open SQL and ordinary non-GUI ABAP statements when they remain
      valid inside methods.
- [ ] Detect statements that are syntactically legal in a report but illegal in
      a method and provide targeted lowering or diagnostics.
- [ ] Measure conversion coverage by AST construct, not by source line count.

Exit gate:

- [ ] At least three non-atomic composite reports convert without manual edits
      and pass lint, transpilation, and behavioral tests.

## Phase 16 - Validation pipeline

For each generated class:

- [ ] Reparse generated source with abaplint core.
- [ ] Run semantic checks with the scaffold and repository dependencies loaded.
- [ ] Run the repository abaplint rules applicable to generated classes.
- [ ] Transpile the generated class with the existing open-abap configuration.
- [ ] Instantiate and run it through `zcl_gg_host` where the program kind permits.
- [ ] Compare observable state against the corresponding hand-written class:
      page kind, text/list cells, screen fields and states, messages, navigation,
      terminal effects, and continuation state.
- [ ] Normalize intentionally different metadata such as generated class name
      before comparison.
- [ ] Fail if unexpected warnings are introduced.
- [ ] For every open-abap or transpiler failure, either fix a converter defect or
      record the reduced reproduction and evidence in `scaffold/ANORMALIES.md`.

Exit gate:

- [ ] One command performs converter unit tests, all supported fixture
      conversions, generated-source validation, and behavioral comparisons.

## Phase 17 - Golden fixture rollout

- [ ] Convert examples `001`-`010`; record unsupported additions individually.
- [ ] Convert examples `011`-`014`.
- [ ] Convert examples `015`-`027`.
- [ ] Convert examples `028`-`038`.
- [ ] Convert examples `039`-`042`.
- [ ] Convert examples `043`-`050`.
- [ ] Convert examples `051`-`057`.
- [ ] Convert example `058` through the dynpro frontend.
- [ ] Add a normalized structural snapshot for each generated class.
- [ ] Add a behavioral comparison wherever the host supports execution.
- [ ] Keep deliberate differences documented beside the fixture.
- [ ] Require an issue reference for every skipped specimen.

Exit gate:

- [ ] The feature matrix shows complete results for `001`-`058`, with no
      unclassified failures.

## Phase 18 - Workbench integration

Do this after the standalone converter is stable, but as part of the same
continuous implementation run. The conversion engine must remain independent
of SE38 and HTTP transport.

- [ ] Add a read-only conversion preview action to the program workbench.
- [ ] Show capability diagnostics before offering generated source.
- [ ] Require an explicit target class name and collision confirmation.
- [ ] Never replace the source program.
- [ ] Keep repository mutation behind a dedicated service interface.
- [ ] Add authorization checks before any create/save operation.
- [ ] Make preview and download available before activation or persistence.
- [ ] Add CSRF/stale-page validation to mutation requests.
- [ ] Add ABAP Unit tests for service behavior and Playwright tests for the real
      browser boundary.

Exit gate:

- [ ] A user can inspect generated class source and diagnostics without changing
      repository state; saving remains an explicit, separately authorized action.

## Phase 19 - Hardening and release

- [ ] Fuzz whitespace, comments, chaining, nesting, and harmless syntax variants.
- [ ] Add regression fixtures for every converter bug.
- [ ] Put time and source-size limits around parsing and conversion.
- [ ] Avoid logging source contents unless explicitly requested.
- [ ] Document determinism guarantees and known unsupported constructs.
- [ ] Document generated-code ownership: generated source is intended to become
      normal editable ABAP after migration unless regeneration is chosen.
- [ ] Version the manifest schema and diagnostic codes.
- [ ] Add a converter version to generated headers.
- [ ] Define semantic-versioning rules for output changes.
- [ ] Run `npm run lint`, converter tests, unit tests, and HTML/browser tests.
- [ ] Verify the working tree contains no generated temporary output.

Release gate:

- [ ] Strict conversion is green for the declared support matrix.
- [ ] Partial mode never emits an unmarked semantic omission.
- [ ] Documentation includes one simple report, one selection-screen report,
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

- [ ] Register lowering rules explicitly; avoid a catch-all that emits original
      source without verifying method legality.
- [ ] Preserve ordinary statements only after a legality check for method scope.
- [ ] Evaluate source operands once when lowering would otherwise duplicate an
      expression with side effects.
- [ ] Preserve short-circuiting and exception behavior.
- [ ] Centralize conversions of system fields and classic control-flow effects.
- [ ] Make each rule independently queryable by the capability scanner.

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

- [ ] Keep the manifest JSON stable and sorted.
- [ ] Map generated validation errors back to original source when possible.
- [ ] Map synthetic boilerplate errors to a converter-internal location.
- [ ] Test source maps after formatting and newline normalization.

## Testing strategy

### Unit tests

- [ ] Parser adapters and source spans.
- [ ] Include resolver and cycle detection.
- [ ] Naming and collision rules.
- [ ] Each AST-to-report-IR collector.
- [ ] Each report-IR-to-scaffold-IR lowering rule.
- [ ] Class emitter formatting and escaping.
- [ ] Diagnostics ordering and JSON representation.
- [ ] Manifest and source-map determinism.

### Structural integration tests

- [ ] Convert a fixture.
- [ ] Reparse the generated class.
- [ ] Assert interfaces, members, and populated event methods.
- [ ] Assert unsupported constructs are never dropped.
- [ ] Assert a second conversion is byte-identical.

### Behavioral integration tests

- [ ] Compile generated and hand-written classes together under distinct names.
- [ ] Run each through the same host entry point and inputs.
- [ ] Compare typed host results, not rendered HTML strings where a typed model
      is available.
- [ ] Cover default input, user input, validation failure, and interactive action
      paths as applicable.

### Negative tests

- [ ] Malformed ABAP.
- [ ] Unsupported program kind.
- [ ] Missing include and DDIC type.
- [ ] Dynamic call or dynamic `PERFORM`.
- [ ] Unsupported `WRITE` addition.
- [ ] Unrepresentable desktop GUI operation.
- [ ] Name collision and overlength target.
- [ ] Existing output without overwrite permission.
- [ ] Suspension in unsupported control-flow context.

## Single-run implementation sequence

Work through this sequence without creating intermediate PRs or stopping at a
phase boundary:

- [ ] Establish the baseline, dependency setup, parser smoke test, and diagnostic
      types.
- [ ] Build the report IR, classifier, capability scanner, and check-only CLI.
- [ ] Add the deterministic class skeleton and generated-source validation.
- [ ] Add state lifting, simple lifecycle events, and example `001`.
- [ ] Complete basic list examples `002`-`010`.
- [ ] Complete lifecycle examples `011`-`014`.
- [ ] Complete selection definitions `015`-`027`.
- [ ] Complete selection events `028`-`038`.
- [ ] Complete messages `039`-`042`.
- [ ] Complete interactive lists `043`-`050`.
- [ ] Add the continuation framework and complete `051`-`057`.
- [ ] Complete logical databases and composite-report hardening.
- [ ] Add the separate dynpro frontend and complete example `058`.
- [ ] Integrate conversion preview and save behavior with the workbench.
- [ ] Run the entire validation matrix and hardening suite.
- [ ] Update every checklist and support-matrix entry from actual test results.

Intermediate commits are optional local safety points only. They are not review
or delivery boundaries, and the implementation continues until the complete
plan passes its final gate.

## Definition of done for each checkbox feature

A conversion feature is complete only when all applicable items hold:

- [ ] Parser node and semantic prerequisites are documented.
- [ ] Capability scan classifies it correctly.
- [ ] Lowering produces typed scaffold IR.
- [ ] Emission is deterministic.
- [ ] Positive and negative unit fixtures exist.
- [ ] Generated output passes abaplint.
- [ ] Generated output transpiles.
- [ ] Behavioral parity is tested through the host.
- [ ] Diagnostics cover unsupported variants.
- [ ] The support matrix and user documentation are updated.

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
