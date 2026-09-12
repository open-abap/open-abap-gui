const SECTION_NAMES = new Set(["EXPORTING", "IMPORTING", "TABLES", "CHANGING", "EXCEPTIONS"]);

const ADAPTERS = new Map([
  ["POPUP_TO_CONFIRM", { family: "popup", method: "popup_to_confirm" }],
  ["POPUP_TO_INFORM", { family: "popup", method: "popup_to_inform" }],
  ["POPUP_GET_VALUES", { family: "popup", method: "popup_get_values" }],
  ["POPUP_WITH_TABLE_DISPLAY", { family: "popup", method: "popup_with_table_display" }],
  ["POPUP_TO_SELECT_MONTH", { family: "popup", method: "popup_to_select_month" }],
  ["F4IF_INT_TABLE_VALUE_REQUEST", { family: "f4", method: "f4_table_value_request" }],
  ["VRM_SET_VALUES", { family: "dynamic-selection", method: "set_selection_list_values" }],
  ["CONVERSION_EXIT_ALPHA_INPUT", { family: "frontend", method: "alpha_input" }],
  ["CONVERSION_EXIT_ALPHA_OUTPUT", { family: "frontend", method: "alpha_output" }],
  ["LVC_FIELDCATALOG_MERGE", { family: "classic-alv", method: "alv_fieldcatalog_merge" }],
  ["REUSE_ALV_FIELDCATALOG_MERGE", { family: "classic-alv", method: "alv_fieldcatalog_merge" }],
  ["REUSE_ALV_GRID_DISPLAY", { family: "classic-alv", method: "alv_display" }],
  ["REUSE_ALV_LIST_DISPLAY", { family: "classic-alv", method: "alv_display" }],
  ["REUSE_ALV_HIERSEQ_LIST_DISPLAY", { family: "classic-alv", method: "alv_display_hierseq" }],
  ["REUSE_ALV_BLOCK_LIST_INIT", { family: "classic-alv", method: "alv_block_init" }],
  ["REUSE_ALV_BLOCK_LIST_APPEND", { family: "classic-alv", method: "alv_block_append" }],
  ["REUSE_ALV_BLOCK_LIST_DISPLAY", { family: "classic-alv", method: "alv_block_display" }],
  ["REUSE_ALV_POPUP_TO_SELECT", { family: "classic-alv", method: "alv_popup_to_select" }],
  ["REUSE_ALV_EVENTS_GET", { family: "classic-alv", method: "alv_events_get" }],
  ["REUSE_ALV_VARIANT_F4", { family: "classic-alv", method: "alv_variant_f4" }],
  ["REUSE_ALV_COMMENTARY_WRITE", { family: "classic-alv", method: "alv_commentary_write" }],
  ["SELECT_OPTIONS_RESTRICT", { family: "dynamic-selection", method: "select_options_restrict" }],
  ["FREE_SELECTIONS_INIT", { family: "dynamic-selection", method: "free_selections_init" }],
  ["FREE_SELECTIONS_DIALOG", { family: "dynamic-selection", method: "free_selections_dialog" }],
  ["FREE_SELECTIONS_RANGE_2_WHERE", { family: "dynamic-selection", method: "free_selections_range_to_where" }],
  ["RS_REFRESH_FROM_SELECTOPTIONS", { family: "variant", method: "variant_refresh" }],
  ["RS_VARIANT_CATALOG", { family: "variant", method: "variant_catalog" }],
  ["RS_VARIANT_CONTENTS", { family: "variant", method: "variant_contents" }],
  ["RS_CREATE_VARIANT", { family: "variant", method: "variant_create" }],
  ["RS_CHANGE_CREATED_VARIANT", { family: "variant", method: "variant_change" }],
  ["RS_VARIANT_DELETE", { family: "variant", method: "variant_delete" }],
  ["SCMS_XSTRING_TO_BINARY", { family: "frontend", method: "xstring_to_binary" }],
  ["DP_CREATE_URL", { family: "frontend", method: "create_url" }],
  ["DP_PUBLISH_WWW_URL", { family: "frontend", method: "publish_url" }],
]);

export const COMPATIBILITY_FUNCTION_MODULES = Object.freeze(
  Object.fromEntries([...ADAPTERS].map(([name, value]) => [name, Object.freeze({ ...value })]))
);

export function functionModuleName(raw) {
  return /CALL\s+FUNCTION\s+'([^']+)'/i.exec(raw)?.[1]?.toUpperCase();
}

export function compatibilityAdapter(rawOrName) {
  const name = String(rawOrName ?? "").includes("CALL FUNCTION")
    ? functionModuleName(rawOrName)
    : String(rawOrName).toUpperCase();
  return name ? ADAPTERS.get(name) : undefined;
}

function scanParameterEnd(raw, start) {
  let depth = 0;
  let quoted = false;
  for (let index = start; index < raw.length; index++) {
    const char = raw[index];
    if (char === "'" && quoted && raw[index + 1] === "'") {
      index++;
      continue;
    }
    if (char === "'") {
      quoted = !quoted;
      continue;
    }
    if (quoted) continue;
    if (char === "(") {
      depth++;
      continue;
    }
    if (char === ")") {
      depth = Math.max(0, depth - 1);
      continue;
    }
    if (depth === 0 && /\s/.test(char)) {
      const next = raw.slice(index).match(/^\s+([A-Z][A-Z0-9_]*)\s*=/i);
      if (next && !SECTION_NAMES.has(next[1].toUpperCase())) return index;
      const section = raw.slice(index).match(/^\s+(EXPORTING|IMPORTING|TABLES|CHANGING|EXCEPTIONS)\b/i);
      if (section) return index;
    }
  }
  return raw.length;
}

export function functionParameter(raw, name) {
  const match = new RegExp(`\\b${String(name).replace(/[.*+?^${}()|[\\]\\\\]/g, "\\\\$&")}\\s*=\\s*`, "i").exec(raw);
  if (!match) return undefined;
  const start = match.index + match[0].length;
  return raw.slice(start, scanParameterEnd(raw, start)).trim().replace(/\.\s*$/, "");
}

function field(name, value, outputName = name) {
  return value === undefined ? undefined : `${outputName} = ${value}`;
}

function request(fields) {
  return `VALUE #( ${fields.filter(Boolean).join(" ")} )`;
}

function call(method, args = "") {
  return `io_session->get_compatibility( )->${method}( ${args} ).`;
}

function returningCall(target, method, args) {
  return target ? `${target} = io_session->get_compatibility( )->${method}( ${args} ).`
    : `DATA(lv_ggconv_fm_result) = io_session->get_compatibility( )->${method}( ${args} ).`;
}

function requestFields(raw, mapping) {
  return request(Object.entries(mapping).map(([output, input]) => field(input, functionParameter(raw, input), output)));
}

function lowerPopup(raw, name) {
  if (name === "POPUP_TO_CONFIRM") {
    const target = functionParameter(raw, "answer");
    const args = requestFields(raw, {
      titlebar: "titlebar", text_question: "text_question", text_button_1: "text_button_1",
      icon_button_1: "icon_button_1", text_button_2: "text_button_2", icon_button_2: "icon_button_2",
      default_button: "default_button", display_cancel_button: "display_cancel_button",
      start_column: "start_column", start_row: "start_row",
    });
    return `${returningCall(target, "popup_to_confirm", args)}\n`;
  }
  if (name === "POPUP_TO_INFORM") {
    return call("popup_to_inform", `is_request = ${requestFields(raw, {
      title: "titel", text1: "txt1", text2: "txt2", text3: "txt3", text4: "txt4",
    })}`);
  }
  if (name === "POPUP_GET_VALUES") {
    const target = functionParameter(raw, "returncode");
    const fields = functionParameter(raw, "fields");
    const args = `EXPORTING is_request = ${requestFields(raw, {
      title: "popup_title", no_value_check: "no_value_check", start_column: "start_column", start_row: "start_row",
    })} CHANGING ct_fields = ${fields ?? "VALUE #( )"}`;
    return returningCall(target, "popup_get_values", args);
  }
  if (name === "POPUP_WITH_TABLE_DISPLAY") {
    const target = functionParameter(raw, "choise") ?? functionParameter(raw, "choice");
    const values = functionParameter(raw, "valuetab");
    const args = `EXPORTING is_request = ${requestFields(raw, {
      title: "titletext", start_column: "startpos_col", start_row: "startpos_row",
      end_column: "endpos_col", end_row: "endpos_row",
    })} CHANGING ct_values = ${values ?? "VALUE #( )"}`;
    return returningCall(target, "popup_with_table_display", args);
  }
  const returnCode = functionParameter(raw, "return_code");
  const selected = functionParameter(raw, "selected_month");
  return call("popup_to_select_month", `EXPORTING is_request = ${requestFields(raw, {
    actual_month: "actual_month", language: "language", start_column: "start_column", start_row: "start_row",
  })}${returnCode || selected ? ` CHANGING${returnCode ? ` cv_return_code = ${returnCode}` : ""}${selected ? ` cv_selected_month = ${selected}` : ""}` : ""}`);
}

function lowerAlv(raw, name) {
  if (name === "LVC_FIELDCATALOG_MERGE" || name === "REUSE_ALV_FIELDCATALOG_MERGE") {
    const fieldcat = functionParameter(raw, "ct_fieldcat");
    return call("alv_fieldcatalog_merge", `EXPORTING is_request = ${requestFields(raw, {
      callback_program: "i_program_name", tabname_header: "i_internal_tabname", title: "i_structure_name",
    })}${fieldcat ? ` CHANGING ct_fieldcat = ${fieldcat}` : ""}`);
  }
  if (name === "REUSE_ALV_BLOCK_LIST_INIT") return call("alv_block_init", `is_request = ${requestFields(raw, { callback_program: "i_callback_program" })}`);
  if (name === "REUSE_ALV_BLOCK_LIST_DISPLAY") return call("alv_block_display", `is_request = ${requestFields(raw, {})}`);
  if (name === "REUSE_ALV_BLOCK_LIST_APPEND") {
    const table = functionParameter(raw, "t_outtab");
    return call("alv_block_append", `EXPORTING is_request = ${requestFields(raw, {
      callback_program: "i_tabname", title: "i_tabname",
    })}${table ? ` CHANGING ct_outtab = ${table}` : ""}`);
  }
  if (name === "REUSE_ALV_EVENTS_GET") {
    const events = functionParameter(raw, "et_events");
    return call("alv_events_get", `EXPORTING is_request = ${requestFields(raw, { list_type: "i_list_type" })}${events ? ` CHANGING ct_events = ${events}` : ""}`);
  }
  if (name === "REUSE_ALV_VARIANT_F4") {
    const variant = functionParameter(raw, "es_variant");
    const exit = functionParameter(raw, "e_exit");
    const report = variant ? `${variant}-report` : undefined;
    return call("alv_variant_f4", `EXPORTING is_request = ${request([field("report", report)])}${variant || exit ? " CHANGING" : ""}${variant ? ` cs_variant = ${variant}` : ""}${exit ? ` cv_exit = ${exit}` : ""}`);
  }
  if (name === "REUSE_ALV_COMMENTARY_WRITE") {
    const commentary = functionParameter(raw, "it_list_commentary");
    return call("alv_commentary_write", commentary ? `CHANGING ct_list_commentary = ${commentary}` : "");
  }
  if (name === "REUSE_ALV_POPUP_TO_SELECT") {
    const table = functionParameter(raw, "t_outtab");
    const selfield = functionParameter(raw, "es_selfield");
    const exit = functionParameter(raw, "e_exit");
    return call("alv_popup_to_select", `EXPORTING is_request = ${requestFields(raw, {
      title: "i_title", callback_program: "i_callback_program",
    })}${table || selfield || exit ? " CHANGING" : ""}${table ? ` ct_outtab = ${table}` : ""}${selfield ? ` cs_selfield = ${selfield}` : ""}${exit ? ` cv_exit = ${exit}` : ""}`);
  }
  if (name === "REUSE_ALV_HIERSEQ_LIST_DISPLAY") {
    const header = functionParameter(raw, "t_outtab_header");
    const item = functionParameter(raw, "t_outtab_item");
    return call("alv_display_hierseq", `EXPORTING is_request = ${requestFields(raw, {
      callback_program: "i_callback_program", callback_user_command: "i_callback_user_command",
      tabname_header: "i_tabname_header", tabname_item: "i_tabname_item",
    })} CHANGING ct_header = ${header ?? "VALUE #( )"} ct_item = ${item ?? "VALUE #( )"}`);
  }
  const table = functionParameter(raw, "t_outtab");
  return call("alv_display", `EXPORTING is_request = ${requestFields(raw, {
    callback_program: "i_callback_program", callback_pf_status_set: "i_callback_pf_status_set",
    callback_user_command: "i_callback_user_command", callback_top_of_page: "i_callback_top_of_page",
    grid_title: "i_grid_title", title: "i_save",
  })}${table ? ` CHANGING ct_outtab = ${table}` : ""}`);
}

function lowerDynamicSelection(raw, name) {
  if (name === "SELECT_OPTIONS_RESTRICT") return call("select_options_restrict", `is_restriction = ${functionParameter(raw, "restriction") ?? "VALUE #( )"}`);
  if (name === "FREE_SELECTIONS_RANGE_2_WHERE") {
    return call("free_selections_range_to_where", `EXPORTING it_field_ranges = ${functionParameter(raw, "field_ranges") ?? "VALUE #( )"} CHANGING ct_where_clauses = ${functionParameter(raw, "where_clauses") ?? "VALUE #( )"}`);
  }
  if (name === "FREE_SELECTIONS_DIALOG") {
    return call("free_selections_dialog", `EXPORTING is_request = ${requestFields(raw, {
      selection_id: "selection_id", title: "title", as_window: "as_window", start_row: "start_row",
      start_column: "start_col", tree_visible: "tree_visible",
    })} CHANGING ct_where_clauses = ${functionParameter(raw, "where_clauses") ?? "VALUE #( )"} cs_expressions = ${functionParameter(raw, "expressions") ?? "VALUE #( )"} ct_field_ranges = ${functionParameter(raw, "field_ranges") ?? "VALUE #( )"} cv_active_fields = ${functionParameter(raw, "number_of_active_fields") ?? "VALUE #( )"} ct_fields = ${functionParameter(raw, "fields_tab") ?? "VALUE #( )"}`);
  }
  return call("free_selections_init", `EXPORTING is_request = ${requestFields(raw, { kind: "kind" })} CHANGING cv_selection_id = ${functionParameter(raw, "selection_id") ?? "VALUE #( )"} ct_field_ranges = ${functionParameter(raw, "field_ranges_int") ?? "VALUE #( )"} ct_tables = ${functionParameter(raw, "tables_tab") ?? "VALUE #( )"} ct_fields = ${functionParameter(raw, "fields_tab") ?? "VALUE #( )"}`);
}

function lowerVariants(raw, name) {
  const report = functionParameter(raw, "report") ?? functionParameter(raw, "curr_report");
  const variant = functionParameter(raw, "variant") ?? functionParameter(raw, "curr_variant");
  const reportParameter = functionParameter(raw, "report") !== undefined ? "report" : "curr_report";
  const variantParameter = functionParameter(raw, "variant") !== undefined ? "variant" : "curr_variant";
  const requestArg = requestFields(raw, { report: reportParameter, variant: variant ? variantParameter : undefined, title: "new_title" });
  if (name === "RS_REFRESH_FROM_SELECTOPTIONS") return call("variant_refresh", `EXPORTING is_request = ${requestFields(raw, { report: "curr_report" })} CHANGING ct_selection = ${functionParameter(raw, "selection_table") ?? "VALUE #( )"}`);
  if (name === "RS_VARIANT_CATALOG") return returningCall(functionParameter(raw, "sel_variant"), "variant_catalog", `is_request = ${requestArg}`);
  if (name === "RS_VARIANT_CONTENTS") return call("variant_contents", `EXPORTING is_request = ${requestArg} CHANGING ct_contents = ${functionParameter(raw, "valutab") ?? "VALUE #( )"}`);
  if (name === "RS_CREATE_VARIANT") return call("variant_create", `EXPORTING is_request = ${requestArg} CHANGING ct_contents = ${functionParameter(raw, "vari_contents") ?? "VALUE #( )"} ct_text = ${functionParameter(raw, "vari_text") ?? "VALUE #( )"}`);
  if (name === "RS_CHANGE_CREATED_VARIANT") return call("variant_change", `EXPORTING is_request = ${requestArg} CHANGING ct_contents = ${functionParameter(raw, "vari_contents") ?? "VALUE #( )"} ct_text = ${functionParameter(raw, "vari_text") ?? "VALUE #( )"}`);
  return call("variant_delete", `is_request = ${requestArg}`);
}

function lowerFrontend(raw, name) {
  if (name === "CONVERSION_EXIT_ALPHA_INPUT" || name === "CONVERSION_EXIT_ALPHA_OUTPUT") {
    const input = functionParameter(raw, "input");
    return returningCall(functionParameter(raw, "output"), name.endsWith("INPUT") ? "alpha_input" : "alpha_output", input ?? "''");
  }
  if (name === "SCMS_XSTRING_TO_BINARY") return call("xstring_to_binary", `EXPORTING iv_buffer = ${functionParameter(raw, "buffer") ?? "VALUE #( )"} CHANGING cv_output_length = ${functionParameter(raw, "output_length") ?? "VALUE #( )"} ct_binary = ${functionParameter(raw, "binary_tab") ?? "VALUE #( )"}`);
  if (name === "DP_CREATE_URL") return call("create_url", `EXPORTING is_request = ${requestFields(raw, { type: "type", subtype: "subtype", size: "size", lifetime: "lifetime" })} CHANGING cv_url = ${functionParameter(raw, "url") ?? "VALUE #( )"} ct_data = ${functionParameter(raw, "data") ?? "VALUE #( )"}`);
  return returningCall(functionParameter(raw, "url"), "publish_url", `iv_object = ${functionParameter(raw, "objid") ?? "''"} iv_lifetime = ${functionParameter(raw, "lifetime") ?? "''"}`);
}

export function lowerCompatibilityFunction(raw) {
  const name = functionModuleName(raw);
  const adapter = name ? ADAPTERS.get(name) : undefined;
  if (!adapter) return undefined;
  if (adapter.family === "popup" || adapter.family === "f4") return adapter.family === "f4"
    ? call("f4_table_value_request", `EXPORTING is_request = ${requestFields(raw, { retfield: "retfield", dynpprog: "dynpprog", dynpnr: "dynpnr", dynprofield: "dynprofield", value_org: "value_org" })} CHANGING ct_value_tab = ${functionParameter(raw, "value_tab") ?? "VALUE #( )"} ct_return_tab = ${functionParameter(raw, "return_tab") ?? "VALUE #( )"}`)
    : lowerPopup(raw, name);
  if (adapter.family === "classic-alv") return lowerAlv(raw, name);
  if (adapter.family === "dynamic-selection") return name === "VRM_SET_VALUES"
    ? call("set_selection_list_values", `iv_id = ${functionParameter(raw, "id") ?? "''"} it_values = ${functionParameter(raw, "values") ?? "VALUE #( )"}`)
    : lowerDynamicSelection(raw, name);
  if (adapter.family === "variant") return lowerVariants(raw, name);
  return lowerFrontend(raw, name);
}
