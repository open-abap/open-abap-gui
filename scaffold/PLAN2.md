# Deeper SAP Integration Test Plan

This plan adds end-to-end tests for realistic ABAP report scenarios using the
custom `ZSFLIGHT` table. Complete the tasks in order and check each box only
after the associated test and verification pass.

When the transpiler does not support a statement or construct, record the gap
in `scaffold/ANORMALIES.md`. Include the feature/report, the exact
statement, the transpiler error, and the verification date. Keep the related
checklist item open until the report passes the runtime gate, unless the plan
explicitly documents a different host or scaffold blocker.

## 1. Test foundation

- [x] Define the integration-test scope and naming convention.
- [x] Identify the existing host, session, database, and assertion helpers to reuse.
- [x] Add a dedicated integration-test fixture dataset for `ZSFLIGHT`.
- [x] Add fixture rows for multiple carriers.
- [x] Add fixture rows covering multiple dates and boundary dates.
- [x] Add fixture rows with different numeric values, including zero and large values.
- [x] Add an empty-result fixture case.
- [x] Add a helper that resets the database and runtime state before each scenario.
- [x] Add a helper for asserting screen transitions.
- [x] Add a helper for asserting list contents and list metadata.
- [x] Add a helper for asserting transaction calls and leave behavior.
- [x] Document how to run the integration tests locally and in CI.

## 2. Database-backed flight report

- [x] Add a report scenario that reads `ZSFLIGHT` with Open SQL.
- [x] Assert that all expected fixture rows are returned.
- [x] Assert filtering by carrier.
- [x] Assert filtering by a single date.
- [x] Assert filtering by an inclusive date range.
- [x] Assert filtering by multiple carriers.
- [x] Assert the defined result ordering.
- [x] Assert the no-result behavior.
- [x] Assert the report output for multiple result rows.
- [x] Assert the report output for a single result row.
- [x] Assert that numeric fields are formatted correctly.
- [x] Assert that date fields are formatted correctly.
- [x] Assert that long text and wide rows do not corrupt the list output.

## 3. Selection-screen lifecycle

- [x] Add a scenario that starts with the default selection-screen values.
- [x] Assert that default values are applied before selection processing.
- [x] Add a required-field success scenario.
- [x] Add a required-field failure scenario.
- [x] Assert that an empty required field displays an error.
- [x] Assert that invalid input returns to the selection screen.
- [x] Add a range-selection scenario.
- [x] Assert that range values become the expected database filter.
- [x] Add a multiple-selection scenario.
- [x] Assert that multiple selections become the expected database filter.
- [x] Add a selection-screen restart scenario after an error.
- [x] Assert that valid values are retained after an error.

## 4. Value requests and input assistance

- [x] Add a value-request scenario for a carrier field.
- [x] Assert that the value request returns the expected `ZSFLIGHT` values.
- [x] Assert that selecting a value-request result updates the requested field.
- [x] Add a value-request scenario for a date or range field.
- [x] Assert that a cancelled value request leaves the field unchanged.
- [x] Assert that invalid value-request input is handled consistently.

## 5. Interactive list processing

- [x] Add a scenario that renders a flight list from `ZSFLIGHT`.
- [x] Assert the initial list contents.
- [x] Add a line-selection scenario.
- [x] Assert the selected line text (`sy-lisel`).
- [x] Assert the selected cursor position.
- [x] Assert hidden field values after line selection.
- [x] Assert the list index (`sy-lsind`) after entering a detail list.
- [x] Add an `AT LINE-SELECTION` detail-list scenario.
- [x] Assert that the detail list contains the selected flight.
- [x] Add a function-code list interaction scenario.
- [x] Assert the function code received by the host.
- [x] Add a `HIDE` value retrieval scenario.
- [x] Assert that hidden values are scoped to the correct list line.
- [x] Add a line-format scenario using color or intensified output.
- [x] Assert that line-format metadata is preserved.
- [x] Add a back-navigation scenario from a detail list.
- [x] Assert that the previous list level is restored correctly.

## 6. Transaction and dynpro navigation

- [x] Add a `CALL TRANSACTION` scenario.
- [x] Assert the called transaction name and parameters.
- [x] Add a `LEAVE TO TRANSACTION` scenario.
- [x] Assert that control does not return to the calling report.
- [x] Add a `SET SCREEN` followed by `LEAVE SCREEN` scenario.
- [x] Assert the resulting screen sequence.
- [x] Add a dynpro PBO/PAI scenario.
- [x] Assert that PBO runs when the screen is entered.
- [x] Assert that PAI runs when the screen is left.
- [x] Add a dynpro back-navigation scenario.
- [x] Assert that screen state is retained or cleared according to the scenario.
- [x] Add a scenario that combines list processing with dynpro navigation.
- [x] Assert that navigation does not leak stale selection or screen state.

## 7. Variants and runtime memory

- [x] Add a variant-save scenario.
- [x] Assert that all selected values are persisted.
- [x] Add a variant-load scenario.
- [x] Assert that loaded values are applied before selection processing.
- [x] Add a variant-overwrite scenario.
- [x] Assert that the latest values replace the previous variant values.
- [x] Add a variant-delete scenario.
- [x] Assert that deleted variants cannot be loaded.
- [x] Add a missing-variant scenario.
- [x] Assert that missing variants produce the expected result.
- [x] Add a repeated-report-execution scenario.
- [x] Assert that state from the previous execution does not leak unexpectedly.
- [x] Add a multi-level-list memory scenario.
- [x] Assert that list state is restored at each list level.

## 8. Failure and boundary behavior

- [x] Add an empty-database scenario.
- [x] Assert the user-visible no-data behavior.
- [x] Add an invalid-carrier scenario.
- [x] Assert the validation or no-result behavior.
- [x] Add an invalid-date-range scenario.
- [x] Assert that reversed ranges are handled correctly.
- [x] Add a numeric-zero scenario.
- [x] Assert that zero values are displayed and processed correctly.
- [x] Add a large-number scenario.
- [x] Assert that numeric overflow is handled without corrupting output.
- [x] Add a rounding scenario.
- [x] Assert the expected internal and external numeric values.
- [x] Add a simulated database-failure scenario.
- [x] Assert that the failure is surfaced without leaving stale state.
- [x] Add a simulated authorization-failure scenario if the host supports it.
- [x] Assert the expected authorization-failure behavior.
- [x] Add a recovery scenario after a failed execution.
- [x] Assert that a subsequent valid execution succeeds.

## 9. Verification and CI

- [x] Run the focused integration-test suite.
- [x] Run ABAP linting.
- [x] Run transpilation.
- [x] Run the complete runtime test suite.
- [x] Run whitespace and diff validation.
- [x] Add the integration suite to the standard verification command.
- [x] Add CI coverage for the complete integration suite.
- [x] Review failures for deterministic fixtures and remove timing dependence.
- [x] Document known differences between the host runtime and SAP behavior.
- [x] Mark this plan complete only when every checkbox above is checked.

## 10. Consolidate database isolation in ABAP Unit

- [x] Confirm that `open-abap-core` provides the SQLite-backed OSQL test-double framework.
- [x] Add a shared typed `ZSFLIGHT` fixture using `CL_OSQL_TEST_ENVIRONMENT`.
- [x] Add ABAP Unit lifecycle hooks for database setup, reset, and teardown.
- [x] Reduce the JavaScript setup to schema bootstrap only.
- [x] Remove the duplicate JavaScript integration scenario runner.
- [x] Update package scripts and integration documentation to use ABAP Unit as the single test entry point.
- [x] Run linting, transpilation, unit tests, and repository validation.
