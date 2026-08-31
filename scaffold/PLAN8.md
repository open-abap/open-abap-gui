# System transaction plan

This plan adds first-class system and workbench transactions, not numbered
examples, and does not consume or renumber the `059`–`150` catalog. Their ABAP
implementations,
ABAP Unit companions, and transaction-specific services live under
`scaffold/system/`; Playwright specs remain under `test/specs/`. Implement one
executable class and one Playwright spec per transaction. Reuse small named
fixture objects in focused tests; do not duplicate the complete repository,
transport, or transaction catalog as an expected-value fixture.

## Shared workbench foundation

- [x] Create `scaffold/system/` and document ownership, naming, test placement,
  fixture limits, and the ban on fake backend success for this transaction
  family.
- [ ] Register exact, case-insensitive `SE01`, `SE09`, `SE11`, `SE16`, and
  `SE38` tcodes as separate `zif_gg_transaction_v1` applications. Model each
  transaction as a server-owned dynpro flow; SE38 hands executable reports to
  the existing report runtime instead of interpreting ABAP in JavaScript.
- [ ] Add typed transport, Dictionary, table-data, and program-repository
  service boundaries behind the transactions. Keep lookup, authorization,
  persistence, activation, release/export, and execution out of renderers and
  browser code.
- [ ] Reproduce the recognizable initial-screen hierarchy, labels, tab order,
  Enter/F4/F8 behavior, status actions, Back/Exit/Cancel semantics, messages,
  keyboard focus, and responsive browser fallback without copying SAP GUI
  bitmap assets.
- [ ] Resolve every submitted request, task, transport object, Dictionary
  object, table, field, program, variant, and row from server-owned metadata.
  Reject unknown, unauthorized, stale, and cross-session identifiers while
  leaving the current screen usable.
- [ ] Expose capabilities explicitly. Display-only deployments disable
  Change/Create/Save/Activate/Release/Export/Debug with an honest visible
  explanation; they never report a successful repository, database, or
  transport mutation that did not occur.

## `SE01` — Transport Organizer (Extended View)

- [ ] Build five separate selection tabs for standard requests, piece lists,
  client transports, delivery transports, and individual display. Preserve
  each tab's criteria and validate request-number conventions by transport type.
- [ ] Reuse the transport request/task hierarchy and request editor from SE09,
  while retaining extended request type, source/target system, owner, status,
  attributes, object list, documentation, and logs.
- [ ] Implement direct individual-request display and navigation from SE09's
  Extended View action without trusting a browser-supplied request identity.
- [ ] Keep special request creation, object-list changes, release, export, and
  transport actions disabled until a real CTS-compatible backend provides
  naming, route, lock, authorization, logging, and failure semantics.

## `SE09` — Transport Organizer

- [ ] Build the initial owner/request/task selection screen with request types,
  request and task statuses, Display, Create, and navigation to SE01 Extended
  View. Retain criteria after empty results or validation errors.
- [ ] Render a hierarchical request → task overview from server-owned transport
  metadata. Include type, owner, short text, status, target, and task assignment
  without inferring hierarchy from request-number text.
- [ ] Open a request/task editor with distinct Properties, Objects,
  Documentation, and Logs views. Resolve object links through repository
  services and escape all descriptions, documentation, and log text.
- [ ] Add Create/Change/Check/Release only through a real transport backend that
  enforces authorization, ownership, task-before-request release order, object
  locks, consistency checks, export results, and immutable released state.
  Until then, provide complete display behavior and explicit disabled actions.

## `SE11` — ABAP Dictionary

- [ ] Build the initial object chooser with independent name/value-help input
  per supported Dictionary object type and Display, Change, and Create actions.
  Preserve the selected object type and value after lookup errors.
- [ ] Implement read-only detail screens from actual Dictionary metadata. Start
  with database tables, structures, data elements, domains, and views, then add
  search helps, lock objects, table types, and type groups without flattening
  unlike object kinds into one generic property dump.
- [ ] For tables and views, render stable tabs for attributes, fields, keys,
  data types, lengths/decimals, descriptions, checks/entry help, and technical
  settings. Link Table Contents to `SE16` with validated server-owned context.
- [ ] Add Change/Create only through a real repository write, validation,
  transport/package, syntax/check, and activation pipeline. Until that pipeline
  exists, keep those actions visibly unavailable and test the rejection.

## `SE16` — Data Browser

- [ ] Build the Table Name initial screen with F4 help and Table Contents.
  Resolve only Dictionary tables/views allowed by the data-access policy and
  report unknown or forbidden objects without leaking metadata.
- [ ] Generate the selection screen from actual field metadata, including
  typed single/range criteria, include/exclude operators, output-field choice,
  maximum-hit limit, and retained criteria after Back or validation errors.
- [ ] Execute a parameterized, server-built query. Never accept SQL, arbitrary
  field names, an unbounded row count, or browser-owned sort/filter expressions;
  enforce authorization and a hard maximum before reading data.
- [ ] Render a deterministic typed result table with field labels, formatted
  values, row count/truncation feedback, empty results, and navigation back to
  the same criteria. Keep the first delivery read-only; mutation requires a
  separate explicit plan and authorization model.

## `SE38` — ABAP Editor

- [ ] Build the initial Program/subobject screen with F4 help and
  Display/Change/Create. Preserve the selected program and subobject across
  errors and distinguish missing, inactive, non-executable, and unauthorized
  programs.
- [ ] Implement read-only Source Code, Attributes, Documentation, Text Elements,
  and Variants views from the repository service. Source display preserves
  line numbers and text while escaping every repository value at the HTML
  boundary.
- [ ] Route Execute/F8 through the existing report runtime. Show the program's
  selection screen when present, support direct execution when absent, and
  return list/navigation/messages through the normal host session.
- [ ] Implement With Variant as program → variant selection → populated
  selection screen → execution. Unknown or incompatible variants are rejected
  without losing the initial program context.
- [ ] Add Change/Create, syntax check, Save, and Activate only when edits persist
  to the repository and activation has a real compiler result. Debugging stays
  disabled with a documented capability message until a genuine debugger
  contract exists.

## Verification

- [ ] Add focused ABAP Unit tests for each transaction and its service adapter,
  using one small Dictionary table/data fixture and one executable report with
  a selection screen and variant, plus one request with one task, object, and
  log fixture. Avoid a hand-maintained full inventory.
- [ ] Keep one browser spec per transaction:
  `zcl_gg_se01.spec.mjs`, `zcl_gg_se09.spec.mjs`,
  `zcl_gg_se11.spec.mjs`, `zcl_gg_se16.spec.mjs`, and
  `zcl_gg_se38.spec.mjs`. Add only narrowly scoped cross-transaction coverage
  for SE09 → SE01, SE11 → SE16, and SE38 → report execution.
- [ ] Prove positive and negative paths through Express, the ICF shim, the real
  HTTP handler, and host runtime: valid display/execute, unknown request/object,
  unauthorized access/release, malformed criteria, row cap, stale action,
  unsafe source/log text, and disabled mutation/export/debugging.
- [ ] Update the workbench inventory and capability documentation once after
  all five tcodes are registered, then pass `npm run lint`, `npm run unit`, and
  `npm run test:html-e2e`.

## Implementation order

1. Add the shared read-only transport/repository/data foundation.
2. Implement SE09 transport display and its request editor.
3. Implement SE01 extended transport selection and display.
4. Implement SE11 Dictionary display.
5. Implement SE16 bounded read-only queries.
6. Implement SE38 repository display and report execution.
7. Add mutation only after real persistence, authorization, activation,
   release, export, locking, and logging contracts exist.

Do not implement all transactions as one change. Each completed step must leave
the registered transaction inventory exact and all existing applications
runnable.

## Final verification ledger

- [ ] `SE01`, `SE09`, `SE11`, `SE16`, and `SE38` match the researched SAP screen
  flows for every enabled capability and visibly reject every unsupported
  capability.
- [ ] Every system transaction has one executable class, focused ABAP Unit
  coverage, and one Playwright spec.
- [ ] The complete clean-checkout CI suite passes on Linux.
