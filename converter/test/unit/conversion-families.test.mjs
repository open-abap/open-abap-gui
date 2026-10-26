import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { convertProgram, generatedValidationDiagnostic } from "../../src/api.mjs";
import { replaceIdentifiers } from "../../src/passes/replace-identifiers.mjs";
import { withoutHeaderLines } from "../../src/passes/header-lines.mjs";
import { repositoryRoot } from "../repository.mjs";

// The three most frequent error families of a conversion run: GGCONV-E202
// (generated source fails parser validation), GGCONV-E515 (field symbols
// without a convertible binding) and GGCONV-E516 (WRITE ... UNIT, implicit
// header-line LOOP). See GGCONV-REG-018 to 022 in fixtures/REGRESSIONS.md.

const fixture = (name) => fs.readFile(path.join(repositoryRoot, "converter", "test", "fixtures", name), "utf8");
const errors = (result, ...codes) => result.diagnostics.filter((item) => codes.includes(item.code));
const method = (source, name) => new RegExp(`METHOD ${name.replace(/[~]/g, "\\~")}\\.[\\s\\S]*?ENDMETHOD\\.`).exec(source)?.[0] ?? "";

// GGCONV-REG-018: a carried-over statement got the rename of a global, a
// parameter or an owner member wherever the name appeared, also where it is a
// component, a table key or an attribute. In a local class's helper,
// get( )-shipment_ref became get( )-mo_owner->shipment_ref and
// ct_values[ name = ... ] became ct_values[ mo_owner->name = ... ].
test("names a global shares with a component, table key or attribute are left alone", async () => {
  const result = await convertProgram({
    source: await fixture("regression_conversion_families.prog.abap.txt"),
    filename: "zreg_families.prog.abap",
    transactionCode: "ZREGFAM",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E202", "GGCONV-E205"), []);
  const helper = result.helperSources.map((item) => item.source).join("\n");
  assert.match(helper, /lv_shipment_ref = lo_asn_clone->get\( \)-shipment_ref\./);
  assert.match(helper, /rs_data-shipment_ref = 'ASN-1'\./);
  assert.match(helper, /IF ct_values\[ name = 'P_BASUNI' \]-value <> mv_p_basuni\.\n\s+ct_values\[ name = 'P_BASUNI' \]-value = \|\{ mv_p_basuni \}\|\.\n\s+ENDIF\.\n\s+RETURN\./);
  assert.doesNotMatch(helper, /-mo_owner->|mo_owner->name =/);
});

test("the write-back of a selection parameter and RETURN pass validation in events and FORMs", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_return.",
      "PARAMETERS p_basuni TYPE c LENGTH 3.",
      "DATA value TYPE string.",
      "DATA name TYPE string.",
      "AT SELECTION-SCREEN.",
      "  IF p_basuni IS INITIAL.",
      "    RETURN.",
      "  ENDIF.",
      "  p_basuni = 'KG'.",
      "START-OF-SELECTION.",
      "  PERFORM run.",
      "  RETURN.",
      "FORM run.",
      "  IF p_basuni = 'KG'.",
      "    RETURN.",
      "  ENDIF.",
      "  WRITE p_basuni.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zreg_return.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E202"), []);
  const event = method(result.classSource, "zif_gg_report_v1~at_selection_screen");
  assert.match(event, /IF mv_p_basuni IS INITIAL\.\n\s+RETURN\.\n\s+ENDIF\./);
  assert.match(event, /IF ct_values\[ name = 'P_BASUNI' \]-value <> mv_p_basuni\.\n\s+ct_values\[ name = 'P_BASUNI' \]-value = \|\{ mv_p_basuni \}\|\.\n\s+ENDIF\./);
  assert.match(method(result.classSource, "form_run"), /IF mv_p_basuni = 'KG'\.\n\s+RETURN\.\n\s+ENDIF\./);
});

test("identifier replacement leaves components, keys, formal parameters, field symbols and columns alone", () => {
  const cases = [
    ["lv = lo->get( )-value.", "lv = lo->get( )-value."],
    ["value = ls-value.", "mo->value = ls-value."],
    ["lv = itab[ value = value ]-value.", "lv = itab[ value = mo->value ]-value."],
    ["ls = VALUE #( value = value ).", "ls = VALUE #( value = mo->value )."],
    ["ls = VALUE #( ( value = value ) ).", "ls = VALUE #( ( value = mo->value ) )."],
    ["lo->set( value = value ).", "lo->set( value = mo->value )."],
    ["lv = xsdbool( value = 1 ).", "lv = xsdbool( mo->value = 1 )."],
    ["lv = COND #( WHEN value = 1 THEN 2 ).", "lv = COND #( WHEN mo->value = 1 THEN 2 )."],
    ["IF value = 1.", "IF mo->value = 1."],
    ["CALL FUNCTION 'Z' EXPORTING value = value.", "CALL FUNCTION 'Z' EXPORTING value = mo->value."],
    ["READ TABLE itab INTO ls WITH KEY value = value.", "READ TABLE itab INTO ls WITH KEY value = mo->value."],
    ["LOOP AT itab INTO ls WHERE value = value AND ( value > 1 ).", "LOOP AT itab INTO ls WHERE value = mo->value AND ( value > 1 )."],
    ["SORT itab BY value.", "SORT itab BY value."],
    ["SELECT value FROM value INTO TABLE itab WHERE value = value.", "SELECT value FROM value INTO TABLE itab WHERE value = mo->value."],
    ["ASSIGN value TO <value>.", "ASSIGN mo->value TO <value>."],
    ["lv = |value { value }| && 'value' && `value`. \" value", "lv = |value { mo->value }| && 'value' && `value`. \" value"],
    ["lv = lcl=>value + zif~value.", "lv = lcl=>value + zif~value."],
  ];
  for (const [input, expected] of cases) assert.equal(replaceIdentifiers(input, [["value", "mo->value"]]), expected, input);
  // A keyword spelled like the global stays a keyword.
  assert.equal(replaceIdentifiers("READ TABLE itab INTO ls INDEX index.", [["index", "mo->index"]]), "READ TABLE itab INTO ls INDEX mo->index.");
  assert.equal(replaceIdentifiers("index + 1", [["index", "mo->index"]]), "mo->index + 1");
});

test("a local class reading a global named like a keyword keeps the keyword", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_keyword.",
      "DATA index TYPE i VALUE 1.",
      "DATA value TYPE string VALUE 'x'.",
      "CLASS lcl_reader DEFINITION.",
      "  PUBLIC SECTION.",
      "    METHODS read RETURNING VALUE(rv_line) TYPE string.",
      "ENDCLASS.",
      "CLASS lcl_reader IMPLEMENTATION.",
      "  METHOD read.",
      "    DATA lt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.",
      "    lt_lines = VALUE #( ( value ) ).",
      "    READ TABLE lt_lines INTO rv_line INDEX index.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  DATA(lo_reader) = NEW lcl_reader( ).",
      "  WRITE lo_reader->read( ).",
    ].join("\n"),
    filename: "zreg_keyword.prog.abap",
  });
  assert.deepEqual(errors(result, "GGCONV-E202"), []);
  const helper = result.helperSources.map((item) => item.source).join("\n");
  assert.match(helper, /lt_lines = VALUE #\( \( mo_owner->value \) \)\./);
  assert.match(helper, /READ TABLE lt_lines INTO rv_line INDEX mo_owner->index\./);
});

// GGCONV-REG-019: the generated class was parsed with the project's release.
// A project on 7.02 rejected the converter's own VALUE #, so every report
// failed GGCONV-E202, and an IF the release could not classify kept its
// ENDIF, which unbalanced the method.
test("generated classes are validated for the release the scaffold needs", async () => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), "ggconv-release-"));
  try {
    const configPath = path.join(root, "abaplint.jsonc");
    const config = JSON.parse(await fs.readFile(path.join(repositoryRoot, "abaplint.jsonc"), "utf8"));
    config.syntax.version = { release: "v702", language: "Normal" };
    await fs.writeFile(configPath, JSON.stringify(config));
    const result = await convertProgram({
      source: [
        "REPORT zreg_release.",
        "DATA gv_value TYPE string.",
        "START-OF-SELECTION.",
        "  gv_value = 'A'.",
        "  IF gt_values[ name = 'P_BASUNI' ]-value <> gv_value.",
        "    WRITE gv_value.",
        "  ENDIF.",
        "  WRITE / gv_value.",
      ].join("\n"),
      filename: "zreg_release.prog.abap",
      configPath,
      mode: "partial",
    });
    assert.deepEqual(errors(result, "GGCONV-E202"), []);
    // 7.02 has no table expressions: the IF is the report's own GGCONV-E201,
    // and its block goes with it.
    assert.ok(errors(result, "GGCONV-E201").some((item) => /IF gt_values\[/.test(item.construct)));
    const start = method(result.classSource, "zif_gg_report_v1~start_of_selection");
    assert.match(start, /\* TODO GGCONV-E201[^\n]*\n\* WRITE gv_value\.\n\* ENDIF\./);
    assert.doesNotMatch(start, /^\s+ENDIF\./m);
  } finally {
    await fs.rm(root, { recursive: true, force: true });
  }
});

test("GGCONV-E202 names the generated method and the statement it rejected", () => {
  const item = generatedValidationDiagnostic({
    code: "GGCONV-E201",
    filename: "ZCL_X.clas.abap",
    start: { line: 4, column: 5 },
    end: { line: 4, column: 5 },
    construct: "lv = x TO y.",
    message: "abaplint could not classify this statement",
  }, { source: "CLASS zcl_x IMPLEMENTATION.\n  METHOD form_run.\n    lv = 1.\n    lv = x TO y.\n  ENDMETHOD.\nENDCLASS." });
  assert.equal(item.code, "GGCONV-E202");
  assert.equal(item.message, "generated class failed parser validation (ZCL_X.clas.abap line 4, METHOD form_run): abaplint could not classify this statement: lv = x TO y.");
});

test("titlebar text keeps template characters as text", async () => {
  const result = await convertProgram({
    source: "REPORT zreg_title.\nDATA gv_count TYPE i.\nSTART-OF-SELECTION.\n  SET TITLEBAR 'MAIN' WITH gv_count.\n  WRITE gv_count.",
    filename: "zreg_title.prog.abap",
    screenMetadata: { screens: [], titlebars: { MAIN: { text: "Set {a|b} \\ &1" } } },
  });
  assert.deepEqual(errors(result, "GGCONV-E202"), []);
  assert.ok(result.classSource.includes("set_title( |Set \\{a\\|b\\} \\\\ { gv_count }| )"), result.classSource);
});

// GGCONV-REG-020: APPEND, INSERT and COLLECT ... ASSIGNING bind a field
// symbol as much as LOOP AT and READ TABLE do, but only those counted, so the
// FORM's declarations and every statement using them were omitted (GGCONV-E515).
test("FORM field symbols bound by APPEND INITIAL LINE ... ASSIGNING stay in the FORM's method", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_fs_form.",
      "START-OF-SELECTION.",
      "  PERFORM get_costcenter.",
      "FORM get_costcenter.",
      "  DATA: lt_fields  TYPE TABLE OF rfc_db_fld,",
      "        lt_options TYPE TABLE OF rfc_db_opt.",
      "  FIELD-SYMBOLS: <ls_field>  LIKE LINE OF lt_fields,",
      "                 <ls_option> LIKE LINE OF lt_options.",
      "",
      "  APPEND INITIAL LINE TO lt_options ASSIGNING <ls_option>.",
      "  <ls_option>-text = '...'.",
      "  APPEND INITIAL LINE TO lt_fields ASSIGNING <ls_field>.",
      "  <ls_field>-fieldname = 'KOSTL'.",
      "  WRITE <ls_field>-fieldname.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zreg_fs_form.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E515", "GGCONV-E202", "GGCONV-E205"), []);
  assert.deepEqual(result.reportIR.safeFieldSymbols, ["LS_FIELD", "LS_OPTION"]);
  const form = method(result.classSource, "form_get_costcenter");
  // The tables come first, as the field symbols are typed from them, even
  // though the WRITE gives the method a writer declaration.
  assert.match(form, /METHOD form_get_costcenter\.\n\s+DATA lt_fields TYPE TABLE OF rfc_db_fld\.\n\s+DATA lt_options TYPE TABLE OF rfc_db_opt\.\n\s+FIELD-SYMBOLS <ls_field> LIKE LINE OF lt_fields\.\n\s+FIELD-SYMBOLS <ls_option> LIKE LINE OF lt_options\./);
  assert.match(form, /APPEND INITIAL LINE TO lt_options ASSIGNING <ls_option>\.\n\s+<ls_option>-text = '\.\.\.'\.\n\s+APPEND INITIAL LINE TO lt_fields ASSIGNING <ls_field>\.\n\s+<ls_field>-fieldname = 'KOSTL'\./);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
  // Nothing outside the FORM's method declares or uses them.
  assert.equal(result.classSource.match(/<ls_field>/g).length, form.match(/<ls_field>/g).length);
});

test("INSERT and COLLECT ... ASSIGNING bind a FORM's field symbol too", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_fs_insert.",
      "START-OF-SELECTION.",
      "  PERFORM run.",
      "FORM run.",
      "  DATA lt_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.",
      "  FIELD-SYMBOLS: <lv_first> LIKE LINE OF lt_rows,",
      "                 <lv_second> LIKE LINE OF lt_rows.",
      "  INSERT INITIAL LINE INTO lt_rows INDEX 1 ASSIGNING <lv_first>.",
      "  <lv_first> = 'a'.",
      "  COLLECT `b` INTO lt_rows ASSIGNING <lv_second>.",
      "  <lv_second> = 'c'.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zreg_fs_insert.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(result.reportIR.safeFieldSymbols, ["LV_FIRST", "LV_SECOND"]);
  assert.doesNotMatch(result.classSource, /TODO GGCONV/);
});

// GGCONV-REG-021: WRITE ... TO went down the list-output path and came out as
// format_value( iv_value = x TO y ), which no release parses (GGCONV-E202),
// and with UNIT it was rejected (GGCONV-E516).
test("WRITE ... TO is carried over as the formatting statement it is, UNIT included", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_write_to.",
      "TYPES: BEGIN OF ty_summary, weight_unit TYPE c LENGTH 3, currency TYPE c LENGTH 5, END OF ty_summary.",
      "DATA ls_summary TYPE ty_summary.",
      "DATA lv_weight TYPE p LENGTH 13 DECIMALS 3.",
      "DATA lv_formatted_weight TYPE c LENGTH 20.",
      "PARAMETERS p_unit TYPE c LENGTH 3 DEFAULT 'KG'.",
      "START-OF-SELECTION.",
      "  WRITE lv_weight TO lv_formatted_weight UNIT ls_summary-weight_unit.",
      "  WRITE lv_weight TO lv_formatted_weight UNIT p_unit.",
      "  WRITE: lv_weight TO lv_formatted_weight DECIMALS 1, sy-datum TO lv_formatted_weight DD/MM/YYYY.",
      "  WRITE lv_weight TO lv_formatted_weight CURRENCY ls_summary-currency NO-GROUPING.",
      "  WRITE / lv_formatted_weight.",
      "  WRITE / lv_weight UNIT ls_summary-weight_unit.",
      "  HIDE lv_weight.",
    ].join("\n"),
    filename: "zreg_write_to.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E202", "GGCONV-E516"), []);
  const start = method(result.classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /^\s+WRITE lv_weight TO lv_formatted_weight UNIT ls_summary-weight_unit\.$/m);
  assert.match(start, /^\s+WRITE lv_weight TO lv_formatted_weight UNIT mv_p_unit\.$/m);
  assert.match(start, /^\s+WRITE lv_weight TO lv_formatted_weight DECIMALS 1\.$/m);
  assert.match(start, /^\s+WRITE sy-datum TO lv_formatted_weight DD\/MM\/YYYY\.$/m);
  assert.match(start, /^\s+WRITE lv_weight TO lv_formatted_weight CURRENCY ls_summary-currency NO-GROUPING\.$/m);
  // A list WRITE hands its unit to the writer; HIDE stays with the last list line.
  assert.match(start, /write_field\( VALUE #\( text = lo_writer->format_value\( iv_value = lv_weight \) placement = VALUE #\( new_line = abap_true \) write_format = VALUE #\( unit = \|\{ ls_summary-weight_unit \}\| \) hide = VALUE #\( \( name = 'LV_WEIGHT'/);

  const obsolete = await convertProgram({
    source: "REPORT zreg_write_index.\nDATA gt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.\nDATA gv_value TYPE i.\nSTART-OF-SELECTION.\n  WRITE gv_value TO gt_lines INDEX 1.",
    filename: "zreg_write_index.prog.abap",
    mode: "partial",
  });
  assert.ok(errors(obsolete, "GGCONV-E516").some((item) => /WRITE \.\.\. TO itab INDEX/.test(item.message)));
  assert.deepEqual(errors(obsolete, "GGCONV-E202"), []);
});

// GGCONV-REG-022: a LOOP without a target reads the table's header line, which
// a class cannot have; it was dropped with its body (GGCONV-E516), and the
// header-line declarations it relied on were copied, or lost, as written.
test("an implicit header-line LOOP gets the table's work area as its target", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_header_line.",
      "TYPES: BEGIN OF ty_row, id TYPE i, qty TYPE i, END OF ty_row.",
      "DATA: BEGIN OF gt_items OCCURS 0,",
      "        id  TYPE i,",
      "        qty TYPE i,",
      "      END OF gt_items.",
      "DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH HEADER LINE.",
      "DATA gv_id TYPE i.",
      "RANGES r_id FOR gv_id.",
      "START-OF-SELECTION.",
      "  gt_items-id = 1.",
      "  APPEND gt_items.",
      "  LOOP AT gt_items WHERE id > 0.",
      "    gt_items-qty = gt_items-qty + 1.",
      "    MODIFY gt_items.",
      "  ENDLOOP.",
      "  r_id-sign = 'I'.",
      "  r_id-option = 'EQ'.",
      "  r_id-low = 1.",
      "  APPEND r_id.",
      "  LOOP AT gt_items.",
      "    CHECK gt_items-id IN r_id.",
      "    MOVE-CORRESPONDING gt_items TO gt_rows.",
      "    APPEND gt_rows.",
      "  ENDLOOP.",
      "  PERFORM show TABLES gt_rows.",
      "FORM show TABLES pt_rows STRUCTURE gt_rows.",
      "  DATA: BEGIN OF lt_local OCCURS 0,",
      "          id TYPE i,",
      "        END OF lt_local.",
      "  LOOP AT pt_rows.",
      "    lt_local-id = pt_rows-id.",
      "    APPEND lt_local.",
      "  ENDLOOP.",
      "  LOOP AT lt_local.",
      "    WRITE / lt_local-id.",
      "  ENDLOOP.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zreg_header_line.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E516", "GGCONV-E202", "GGCONV-E205"), []);
  const source = result.classSource;
  assert.doesNotMatch(source, /HEADER LINE|OCCURS/);
  assert.match(source, /DATA: BEGIN OF gt_items_header, id TYPE i, qty TYPE i, END OF gt_items_header\.\n\s+DATA gt_items LIKE STANDARD TABLE OF gt_items_header WITH DEFAULT KEY\./);
  assert.match(source, /DATA gt_rows TYPE STANDARD TABLE OF ty_row\.\n\s+DATA gt_rows_header LIKE LINE OF gt_rows\./);
  assert.match(source, /DATA r_id LIKE RANGE OF gv_id\.\n\s+DATA r_id_header LIKE LINE OF r_id\./);
  const start = method(source, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /gt_items_header-id = 1\.\n\s+APPEND gt_items_header TO gt_items\.\n\s+LOOP AT gt_items INTO gt_items_header WHERE id > 0\.\n\s+gt_items_header-qty = gt_items_header-qty \+ 1\.\n\s+MODIFY gt_items FROM gt_items_header\.\n\s+ENDLOOP\./);
  assert.match(start, /APPEND r_id_header TO r_id\./);
  assert.match(start, /LOOP AT gt_items INTO gt_items_header\.\n\s+CHECK gt_items_header-id IN r_id\.\n\s+MOVE-CORRESPONDING gt_items_header TO gt_rows_header\.\n\s+APPEND gt_rows_header TO gt_rows\./);
  assert.match(start, /pt_rows\s+= gt_rows \)\./);
  const form = method(source, "form_show");
  assert.match(form, /DATA pt_rows_header LIKE LINE OF gt_rows\./);
  assert.match(form, /DATA BEGIN OF lt_local_header\./);
  assert.match(form, /DATA END OF lt_local_header\.\n\s+DATA lt_local LIKE STANDARD TABLE OF lt_local_header WITH DEFAULT KEY\./);
  assert.match(form, /LOOP AT pt_rows INTO pt_rows_header\.\n\s+lt_local_header-id = pt_rows_header-id\.\n\s+APPEND lt_local_header TO lt_local\./);
  assert.match(form, /LOOP AT lt_local INTO lt_local_header\./);

  // An untyped TABLES parameter has no line type for its work area.
  const untyped = await convertProgram({
    source: "REPORT zreg_untyped.\nSTART-OF-SELECTION.\nFORM show TABLES pt_rows.\n  LOOP AT pt_rows.\n  ENDLOOP.\nENDFORM.",
    filename: "zreg_untyped.prog.abap",
    mode: "partial",
  });
  assert.ok(errors(untyped, "GGCONV-E516").some((item) => item.message.includes("implicit-header-table LOOP")));
});

// LIKE a header-line table names its header line; the class's table of that
// name has no line type to be LIKE, and TYPE ... OF names no type at all.
test("LIKE a header-line table OCCURS n is a table of its work area", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_like_header_line.",
      "DATA: BEGIN OF bufline OCCURS 10,",
      "        line(5000),",
      "      END OF bufline.",
      "DATA i_batch LIKE bufline OCCURS 10 WITH HEADER LINE.",
      "START-OF-SELECTION.",
      "  APPEND i_batch.",
    ].join("\n"),
    filename: "zreg_like_header_line.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const source = result.classSource;
  assert.match(source, /DATA: BEGIN OF bufline_header, line TYPE c LENGTH 5000, END OF bufline_header\./);
  assert.match(source, /DATA i_batch LIKE STANDARD TABLE OF bufline_header WITH DEFAULT KEY\.\n\s+DATA i_batch_header LIKE LINE OF i_batch\./);
});

// Indentation does not make a declaration local; SELECT-OPTIONS FOR an indented
// global is LIKE RANGE OF its member, as for one in column 1.
test("SELECT-OPTIONS FOR an indented global is a range of that global", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zreg_indented_global.",
      "DATA gv_flat TYPE c LENGTH 4.",
      "   DATA gv_indented TYPE c LENGTH 4.",
      "SELECT-OPTIONS: s_flat FOR gv_flat,",
      "                s_ind  FOR gv_indented.",
      "START-OF-SELECTION.",
      "  WRITE / 'hello'.",
    ].join("\n"),
    filename: "zreg_indented_global.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /DATA mv_s_flat LIKE RANGE OF gv_flat\./);
  assert.match(result.classSource, /DATA mv_s_ind LIKE RANGE OF gv_indented\./);
});

test("header-line statements name the table or its work area as the statement means", () => {
  const cases = [
    ["LOOP AT itab FROM 2 WHERE id = 1.", "LOOP AT itab INTO itab_header FROM 2 WHERE id = 1."],
    ["LOOP AT itab INTO ls.", "LOOP AT itab INTO ls."],
    ["APPEND itab SORTED BY id.", "APPEND itab_header TO itab SORTED BY id."],
    ["APPEND itab TO lt_other.", "APPEND itab_header TO lt_other."],
    ["APPEND LINES OF itab TO lt_other.", "APPEND LINES OF itab TO lt_other."],
    ["INSERT itab INDEX 1.", "INSERT itab_header INTO itab INDEX 1."],
    ["INSERT TABLE itab.", "INSERT itab_header INTO TABLE itab."],
    ["COLLECT itab.", "COLLECT itab_header INTO itab."],
    ["MODIFY itab INDEX 2 TRANSPORTING qty.", "MODIFY itab FROM itab_header INDEX 2 TRANSPORTING qty."],
    ["DELETE TABLE itab.", "DELETE TABLE itab FROM itab_header."],
    ["DELETE itab WHERE id = 1.", "DELETE itab WHERE id = 1."],
    ["READ TABLE itab WITH KEY id = 1 BINARY SEARCH.", "READ TABLE itab WITH KEY id = 1 BINARY SEARCH INTO itab_header."],
    ["READ TABLE itab INDEX 1 TRANSPORTING qty.", "READ TABLE itab INDEX 1 INTO itab_header TRANSPORTING qty."],
    ["READ TABLE itab.", "READ TABLE itab FROM itab_header INTO itab_header."],
    ["READ TABLE itab WITH KEY id = itab-id TRANSPORTING NO FIELDS.", "READ TABLE itab WITH KEY id = itab_header-id TRANSPORTING NO FIELDS."],
    ["CLEAR itab.", "CLEAR itab_header."],
    ["CLEAR itab[].", "CLEAR itab."],
    ["IF itab IS INITIAL.", "IF itab_header IS INITIAL."],
    ["IF itab[] IS INITIAL.", "IF itab IS INITIAL."],
    ["DESCRIBE TABLE itab LINES lv.", "DESCRIBE TABLE itab LINES lv."],
    ["SORT itab BY id.", "SORT itab BY id."],
    ["lv = lines( itab ) + itab[ 1 ]-id.", "lv = lines( itab ) + itab[ 1 ]-id."],
    ["SELECT SINGLE * FROM mara INTO itab WHERE matnr = itab-matnr.", "SELECT SINGLE * FROM mara INTO itab_header WHERE matnr = itab_header-matnr."],
    ["SELECT * FROM mara INTO TABLE lt FOR ALL ENTRIES IN itab WHERE matnr = itab-matnr.", "SELECT * FROM mara INTO TABLE lt FOR ALL ENTRIES IN itab WHERE matnr = itab-matnr."],
    ["PERFORM x TABLES itab USING itab.", "PERFORM x TABLES itab USING itab_header."],
    ["CALL FUNCTION 'X' EXPORTING is = itab TABLES t = itab.", "CALL FUNCTION 'X' EXPORTING is = itab_header TABLES t = itab."],
    ["DATA ls LIKE itab.", "DATA ls LIKE itab_header."],
    ["DATA ls LIKE LINE OF itab.", "DATA ls LIKE LINE OF itab."],
    ["ls-itab = 1.", "ls-itab = 1."],
  ];
  for (const [input, expected] of cases) assert.equal(withoutHeaderLines(input, { ITAB: "itab_header" }), expected, input);
});
