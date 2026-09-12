# Converter feature matrix

This matrix is checked in with the converter so fixture coverage is visible
without treating a hand-written counterpart as an implementation. `partial`
means the source is parsed and every unsupported construct is diagnosed and
marked in generated output; it is not a claim of behavioral parity.

| Examples | Feature | Passes | Milestone | Current status |
| --- | --- | --- | --- | --- |
| 001-010 | classic list output and page settings | `lower-statements`, `class-source` | 6 | behavioral parity |
| 011-014 | report lifecycle and STOP | `collect-events`, `lower-statements` | 7 | behavioral parity |
| 015-027 | selection declarations | `collect-selection-screens`, `class-source` | 8 | behavioral parity with supplied text/DDIC metadata |
| 028-038 | selection events and screen state | `collect-events`, `lower-statements` | 9 | behavioral parity with supplied text/DDIC metadata |
| 039-042 | messages | `lower-statements` | 10 | behavioral parity |
| 043-050 | interactive lists | `capability`, `lower-statements` | 11 | behavioral parity with supplied GUI status metadata |
| 051-057 | continuations and navigation | `lower-continuations`, `class-source` | 12 | behavioral parity |
| 058 | dynpro frontend | `classify-program`, `class-source` | 14 | behavioral parity with supplied screen/flow/status metadata |

The strict check matrix supplies the external DDIC metadata required by
examples `020` and `032`, and the explicit dynpro screen/flow/status metadata
required by `058`; all 58 numbered rows are currently strict-supported.

The integration smoke test enumerates every report fixture from `001` through
`058`, checks the manifest and diagnostics contract, and reparses generated
source. The report behavioral gate covers `001` through `057`; the behavioral
gate also compares generated and hand-written dynpro transitions for `058`.

Composite hardening fixtures are also checked independently of the numbered
examples:

| Fixture | Coverage | Validation |
| --- | --- | --- |
| `composite_nested_includes.abap.txt` | nested include order, shared global state, FORM/PERFORM | lint, transpile, host behavior |
| `composite_selection_form.abap.txt` | selection state passed through reusable FORM logic | lint, transpile, host behavior |
| `composite_sql_form.abap.txt` | static Open SQL, internal-table loop, reusable FORM | lint, transpile, seeded SQLite host behavior |
| `composite_local_class.abap.txt` | local-class boundary | targeted `GGCONV-E305` partial conversion |
| `regression_declaration_shapes.abap.txt` | structured, table, reference, and elementary type declarations | unit, lint, transpile |
| `regression_exception_block.abap.txt` | method-safe `TRY`/`CATCH`/`CLEANUP` control flow | unit, lint, transpile |
| `regression_dynamic_write.abap.txt` | dynamic `WRITE` substring expression lowering | unit, lint, transpile |
| `regression_dynamic_write_call.abap.txt` | unsupported call-like dynamic `WRITE` diagnostic and partial-mode marker | unit, lint, transpile |
| `regression_dynamic_write_fallback.abap.txt` | single-evaluation dynamic `WRITE` field-symbol fallback with visible partial marker | unit, lint, transpile |
| inline dynamic-WRITE behavior fixture | single-evaluation dispatch for known global target names | unit, lint, transpile, host behavior |

## Deliberate differences and skipped specimens

The numbered strict matrix has no skipped rows when its declared metadata is
provided. The repository-wide partial sweep intentionally leaves these
metadata-dependent specimens marked rather than inventing types or screens:

| Specimen | Reference | Difference |
| --- | --- | --- |
| `zgg_ex_072`, `073`, `074`, `078`, `080` | `GGCONV-E301` | `TABLES zsflight` and its selection fields need caller-supplied DDIC metadata |
| `zgg_ex_058` without dynpro metadata | `GGCONV-E502` | `PROGRAM` input needs caller-supplied screen, flow-logic, and status metadata |
| local-class composite | `GGCONV-E305` | local classes remain a marked partial-conversion boundary until separately mapped |

These references are also recorded in each partial result's manifest and
diagnostic list; no specimen is silently omitted.
