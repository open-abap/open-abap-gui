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

- [ ] Define the integration-test scope and naming convention.
- [ ] Identify the existing host, session, database, and assertion helpers to reuse.
- [ ] Add a dedicated integration-test fixture dataset for `ZSFLIGHT`.
- [ ] Add fixture rows for multiple carriers.
- [ ] Add fixture rows covering multiple dates and boundary dates.
- [ ] Add fixture rows with different numeric values, including zero and large values.
- [ ] Add an empty-result fixture case.
- [ ] Add a helper that resets the database and runtime state before each scenario.
- [ ] Add a helper for asserting screen transitions.
- [ ] Add a helper for asserting list contents and list metadata.
- [ ] Add a helper for asserting transaction calls and leave behavior.
- [ ] Document how to run the integration tests locally and in CI.

## 2. Database-backed flight report

- [ ] Add a report scenario that reads `ZSFLIGHT` with Open SQL.
- [ ] Assert that all expected fixture rows are returned.
- [ ] Assert filtering by carrier.
- [ ] Assert filtering by a single date.
- [ ] Assert filtering by an inclusive date range.
- [ ] Assert filtering by multiple carriers.
- [ ] Assert the defined result ordering.
- [ ] Assert the no-result behavior.
- [ ] Assert the report output for multiple result rows.
- [ ] Assert the report output for a single result row.
- [ ] Assert that numeric fields are formatted correctly.
- [ ] Assert that date fields are formatted correctly.
- [ ] Assert that long text and wide rows do not corrupt the list output.

## 3. Selection-screen lifecycle

- [ ] Add a scenario that starts with the default selection-screen values.
- [ ] Assert that default values are applied before selection processing.
- [ ] Add a required-field success scenario.
- [ ] Add a required-field failure scenario.
- [ ] Assert that an empty required field displays an error.
- [ ] Assert that invalid input returns to the selection screen.
- [ ] Add a range-selection scenario.
- [ ] Assert that range values become the expected database filter.
- [ ] Add a multiple-selection scenario.
- [ ] Assert that multiple selections become the expected database filter.
- [ ] Add a selection-screen restart scenario after an error.
- [ ] Assert that valid values are retained after an error.

## 4. Value requests and input assistance

- [ ] Add a value-request scenario for a carrier field.
- [ ] Assert that the value request returns the expected `ZSFLIGHT` values.
- [ ] Assert that selecting a value-request result updates the requested field.
- [ ] Add a value-request scenario for a date or range field.
- [ ] Assert that a cancelled value request leaves the field unchanged.
- [ ] Assert that invalid value-request input is handled consistently.

## 5. Interactive list processing

- [ ] Add a scenario that renders a flight list from `ZSFLIGHT`.
- [ ] Assert the initial list contents.
- [ ] Add a line-selection scenario.
- [ ] Assert the selected line text (`sy-lisel`).
- [ ] Assert the selected cursor position.
- [ ] Assert hidden field values after line selection.
- [ ] Assert the list index (`sy-lsind`) after entering a detail list.
- [ ] Add an `AT LINE-SELECTION` detail-list scenario.
- [ ] Assert that the detail list contains the selected flight.
- [ ] Add a function-code list interaction scenario.
- [ ] Assert the function code received by the host.
- [ ] Add a `HIDE` value retrieval scenario.
- [ ] Assert that hidden values are scoped to the correct list line.
- [ ] Add a line-format scenario using color or intensified output.
- [ ] Assert that line-format metadata is preserved.
- [ ] Add a back-navigation scenario from a detail list.
- [ ] Assert that the previous list level is restored correctly.

## 6. Transaction and dynpro navigation

- [ ] Add a `CALL TRANSACTION` scenario.
- [ ] Assert the called transaction name and parameters.
- [ ] Add a `LEAVE TO TRANSACTION` scenario.
- [ ] Assert that control does not return to the calling report.
- [ ] Add a `SET SCREEN` followed by `LEAVE SCREEN` scenario.
- [ ] Assert the resulting screen sequence.
- [ ] Add a dynpro PBO/PAI scenario.
- [ ] Assert that PBO runs when the screen is entered.
- [ ] Assert that PAI runs when the screen is left.
- [ ] Add a dynpro back-navigation scenario.
- [ ] Assert that screen state is retained or cleared according to the scenario.
- [ ] Add a scenario that combines list processing with dynpro navigation.
- [ ] Assert that navigation does not leak stale selection or screen state.

## 7. Variants and runtime memory

- [ ] Add a variant-save scenario.
- [ ] Assert that all selected values are persisted.
- [ ] Add a variant-load scenario.
- [ ] Assert that loaded values are applied before selection processing.
- [ ] Add a variant-overwrite scenario.
- [ ] Assert that the latest values replace the previous variant values.
- [ ] Add a variant-delete scenario.
- [ ] Assert that deleted variants cannot be loaded.
- [ ] Add a missing-variant scenario.
- [ ] Assert that missing variants produce the expected result.
- [ ] Add a repeated-report-execution scenario.
- [ ] Assert that state from the previous execution does not leak unexpectedly.
- [ ] Add a multi-level-list memory scenario.
- [ ] Assert that list state is restored at each list level.

## 8. Failure and boundary behavior

- [ ] Add an empty-database scenario.
- [ ] Assert the user-visible no-data behavior.
- [ ] Add an invalid-carrier scenario.
- [ ] Assert the validation or no-result behavior.
- [ ] Add an invalid-date-range scenario.
- [ ] Assert that reversed ranges are handled correctly.
- [ ] Add a numeric-zero scenario.
- [ ] Assert that zero values are displayed and processed correctly.
- [ ] Add a large-number scenario.
- [ ] Assert that numeric overflow is handled without corrupting output.
- [ ] Add a rounding scenario.
- [ ] Assert the expected internal and external numeric values.
- [ ] Add a simulated database-failure scenario.
- [ ] Assert that the failure is surfaced without leaving stale state.
- [ ] Add a simulated authorization-failure scenario if the host supports it.
- [ ] Assert the expected authorization-failure behavior.
- [ ] Add a recovery scenario after a failed execution.
- [ ] Assert that a subsequent valid execution succeeds.

## 9. Verification and CI

- [ ] Run the focused integration-test suite.
- [ ] Run ABAP linting.
- [ ] Run transpilation.
- [ ] Run the complete runtime test suite.
- [ ] Run whitespace and diff validation.
- [ ] Add the integration suite to the standard verification command.
- [ ] Add CI coverage for the complete integration suite.
- [ ] Review failures for deterministic fixtures and remove timing dependence.
- [ ] Document known differences between the host runtime and SAP behavior.
- [ ] Mark this plan complete only when every checkbox above is checked.

