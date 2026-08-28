# Transpiler anomalies

Record every transpiler statement or construct gap here, including the
affected plan feature, exact source statement, error text, and date observed.

## AN-001 — `RESERVE` statement unsupported (resolved)

- Feature: 08, `NEW-PAGE` / `RESERVE` / `SET BLANK LINES`
- Report: `scaffold/examples/zgg_ex_08.prog.abap`
- Statement: `RESERVE 5 LINES.`
- Error: `Statement Reserve not supported, RESERVE 5 LINES.`
- Observed: 2026-08-28
- Resolved: 2026-08-28; the updated transpiler accepts the statement.

## AN-007 — `NEW-PAGE` statement unsupported

- Feature: 08, `NEW-PAGE` / `RESERVE` / `SET BLANK LINES`
- Report: `scaffold/examples/zgg_ex_08.prog.abap`
- Statement: `NEW-PAGE NO-TITLE LINE-SIZE 80.`
- Error: `Statement NewPage not supported, NEW-PAGE NO-TITLE LINE-SIZE 80.`
- Observed: 2026-08-28
- Status: The report remains excluded from `abap_transpile.json`; the scaffold
  counterpart and host test remain available.

## AN-002 — `HIDE` statement unsupported

- Feature: 43, `HIDE` and `AT LINE-SELECTION`
- Report: `scaffold/examples/zgg_ex_43.prog.abap`
- Statement: `HIDE gv_id.`
- Error: `Statement Hide not supported, HIDE gv_id.`
- Observed: 2026-08-28
- Status: The report remains excluded from `abap_transpile.json`; interactive
  list processing also requires host support.

## AN-003 — `AT USER-COMMAND` statement unsupported

- Feature: 44, `SET PF-STATUS` and `AT USER-COMMAND`
- Report: `scaffold/examples/zgg_ex_44.prog.abap`
- Statement: `AT USER-COMMAND.`
- Error: `Statement AtUserCommand not supported, AT USER-COMMAND.`
- Observed: 2026-08-28
- Status: The report remains excluded from `abap_transpile.json`; interactive
  list processing also requires host support.

## AN-004 — `AT PFnn` statement unsupported

- Feature: 49, `AT PFnn`
- Report: `scaffold/examples/zgg_ex_49.prog.abap`
- Statement: `AT PF5.`
- Error: `Statement AtPF not supported, AT pf5.`
- Observed: 2026-08-28
- Status: The report remains excluded from `abap_transpile.json`; interactive
  list processing also requires host support.

## AN-005 — `CALL SELECTION-SCREEN` statement unsupported

- Feature: 51, `CALL SELECTION-SCREEN`
- Report: `scaffold/examples/zgg_ex_51.prog.abap`
- Statement: `CALL SELECTION-SCREEN 500 STARTING AT 10 5.`
- Error: `Statement CallSelectionScreen not supported, CALL SELECTION-SCREEN 500 STARTING AT 10 5.`
- Observed: 2026-08-28
- Status: The report remains excluded from `abap_transpile.json`; navigation
  and resumable continuation also require host support.

## AN-006 — Positional multi-parameter calls fail at runtime

- Scope: Transpiler calling convention used by the plan examples
- Statement: A method call with more than one parameter passed positionally
- Error: Positional passing is not resolved reliably; the call fails at runtime
  instead of producing a lint diagnostic.
- Observed: 2026-08-28
- Status: Plan examples use named parameters whenever a call has more than one
  parameter; this is a documented workaround rather than an excluded report.
