import "../output/init.mjs";
import { ltcl_gg_integration_flights } from "../output/zcl_gg_integration_flights.clas.testclasses.mjs";
import { ltcl_gg_integration_selection } from "../output/zcl_gg_integration_selection.clas.testclasses.mjs";
import { ltcl_gg_integration_int } from "../output/zcl_gg_integration_interactive.clas.testclasses.mjs";
import { ltcl_gg_integration_nav } from "../output/zcl_gg_integration_navigation.clas.testclasses.mjs";
import { ltcl_gg_integration_dyn } from "../output/zcl_gg_integration_dynpro.clas.testclasses.mjs";
import { ltcl_gg_integration_var } from "../output/zcl_gg_integration_variants.clas.testclasses.mjs";
import { ltcl_gg_integration_fail } from "../output/zcl_gg_integration_failure.clas.testclasses.mjs";
import assert from "node:assert/strict";

import { resetScenario } from "./harness.mjs";

async function runReport(mode) {
  const report = await new abap.Classes["ZCL_GG_INTEGRATION_FLIGHTS"]().constructor_({
    iv_mode: mode,
  });
  return await abap.Classes["ZCL_GG_HOST"].run({ io_report: report.me });
}

const METHODS = [
  "returns_all_fixture_rows",
  "filters_by_carrier",
  "filters_by_single_date",
  "filters_by_date_range",
  "rejects_reversed_date_range",
  "filters_by_multiple_carriers",
  "preserves_fixture_order",
  "returns_no_result_message",
  "renders_multiple_rows",
  "renders_single_row",
  "renders_numeric_fields",
  "renders_zero_value",
  "renders_large_value",
  "preserves_rounding_output",
  "renders_date_fields",
  "renders_wide_text_fields",
];

const SELECTION_METHODS = [
  "applies_default",
  "accepts_required_field",
  "rejects_missing_required_field",
  "reports_empty_required_field",
  "rejects_invalid_input",
  "returns_to_selection_screen",
  "restarts_after_error",
  "filters_by_range",
  "filters_by_multiple_selection",
  "retains_values_after_error",
  "requests_carrier_values",
  "applies_value_selection",
  "requests_date_values",
  "cancelled_request_keeps_value",
  "handles_unknown_request",
];

const INTERACTIVE_METHODS = [
  "renders_flight_list",
  "asserts_initial_contents",
  "selects_line",
  "reports_selected_line_text",
  "reports_cursor_position",
  "reports_hidden_values",
  "reports_detail_list_index",
  "renders_detail_list",
  "detail_has_flight",
  "runs_function_code",
  "reports_function_code",
  "retrieves_line_hidden_values",
  "scopes_hidden_values_to_line",
  "preserves_line_format",
  "runs_pf_interaction",
  "restores_list_level",
];

const NAVIGATION_METHODS = [
  "calls_transaction",
  "records_transaction_params",
  "resumes_call",
  "leaves_transaction",
  "does_not_return_after_leave",
];

const DYNPRO_METHODS = [
  "calls_next_screen",
  "asserts_screen_sequence",
  "runs_pbo_on_entry",
  "runs_pai_on_leave",
  "handles_back_navigation",
  "retains_back_state",
  "combines_list_navigation",
  "isolates_list_state",
];

const VARIANT_METHODS = [
  "saves_values",
  "loads_values_before_run",
  "overwrites_values",
  "deletes_values",
  "reports_missing_variant",
  "repeats_without_leak",
  "isolates_memory_list",
  "restores_memory_level",
];

const FAILURE_METHODS = [
  "handles_empty_database",
  "handles_invalid_carrier",
  "handles_reversed_range",
  "handles_database_failure",
  "reports_database_failure",
  "handles_authorization_failure",
  "reports_authorization_failure",
  "recovers_after_failure",
];

for (const method of METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_flights().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

for (const method of SELECTION_METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_selection().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

for (const method of INTERACTIVE_METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_int().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

for (const method of NAVIGATION_METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_nav().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

for (const method of DYNPRO_METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_dyn().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

for (const method of VARIANT_METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_var().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

for (const method of FAILURE_METHODS) {
  await resetScenario();
  const test = await new ltcl_gg_integration_fail().constructor_();
  console.log(`INTEGRATION: ${method}`);
  await test.FRIENDS_ACCESS_INSTANCE[method]();
}

await resetScenario({ empty: true });
const emptyResult = await runReport("NONE");
assert.deepEqual(
  emptyResult.value.lines.array().map((line) => line.get()),
  ["No flights found"],
  "empty database result",
);
await resetScenario();
console.log("INTEGRATION: empty_database");

console.log(`Integration scenarios passed: ${METHODS.length + SELECTION_METHODS.length + INTERACTIVE_METHODS.length + NAVIGATION_METHODS.length + DYNPRO_METHODS.length + VARIANT_METHODS.length + FAILURE_METHODS.length + 1}`);
