import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../../src/api.mjs";
import { repositoryRoot } from "../repository.mjs";

// GGCONV-REG-024 to 035 in fixtures/REGRESSIONS.md: classic report
// declarations and statements that came out of the converter as class source
// abaplint rejects. Each has an example program, examples/zgg_ex_177 to 187,
// whose converted copy npm test also lints and transpiles.

const errors = (result, ...codes) => result.diagnostics.filter((item) => codes.includes(item.code));
const method = (source, name) => new RegExp(`METHOD ${name.replace(/[~]/g, "\\~")}\\.[\\s\\S]*?ENDMETHOD\\.`).exec(source)?.[0] ?? "";

async function example(number) {
  const filename = path.join(repositoryRoot, "examples", `zgg_ex_${number}.prog.abap`);
  const result = await convertProgram({ source: await fs.readFile(filename, "utf8"), filename, className: `ZCL_GG_EX_${number}` });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(errors(result, "GGCONV-E202"), []);
  return result;
}

async function convert(lines, options = {}) {
  return convertProgram({ source: lines.join("\n"), filename: "zreg_decl.prog.abap", ...options });
}

// GGCONV-REG-024: the helper class's PUBLIC SECTION was found only as written
// PUBLIC SECTION., so PUBLIC SECTION . got a second one ahead of it.
test("a local class's PUBLIC SECTION . gets the helper's members once", async () => {
  const result = await example(177);
  const helper = result.helperSources[0].source;
  assert.equal(helper.match(/SECTION/g).length, 1, helper);
  assert.match(helper, /^ {2}PUBLIC SECTION\.\n {4}METHODS constructor\n/m);
  assert.match(helper, /METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid/);
});

// GGCONV-REG-025: abaplint splits a chained BEGIN OF ... OCCURS into one
// statement per component, so text(100) TYPE c became a screen field of a
// global named text that does not exist.
test("components of a BEGIN OF ... OCCURS structure are no screen fields", async () => {
  const result = await example(178);
  assert.doesNotMatch(result.classSource, /'TEXT'|'MATNR'|^\s*(?:text|matnr) = /m);
  assert.match(result.classSource, /DATA: BEGIN OF gt_list_header, matnr TYPE matnr, text\(100\) TYPE c, END OF gt_list_header\./);
});

// GGCONV-REG-026: TYPES came before the TABLES work areas, so LIKE dbtab-field
// named a member not declared yet.
test("TYPES LIKE a TABLES work area's component is typed by the table", async () => {
  const result = await example(179);
  assert.match(result.classSource, /TYPES: BEGIN OF ty_row, msgnr TYPE t100-msgnr, text TYPE t100-text, END OF ty_row\./);
});

// GGCONV-REG-027: LIKE a dictionary structure, table or component is a report
// form; in a class LIKE names a data object.
test("LIKE a dictionary type becomes TYPE, LIKE a data object stays", async () => {
  const result = await example(180);
  assert.match(result.classSource, /DATA gv_text TYPE t100-text\./);
  assert.match(result.classSource, /DATA gt_return TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY\.\n\s+DATA gt_return_header LIKE LINE OF gt_return\./);
  assert.match(result.classSource, /DATA gs_line LIKE LINE OF gt_lines\./);
  const form = method(result.classSource, "form_show");
  assert.match(form, /DATA lv_class TYPE symsg-msgid VALUE 'ZGG'\./);
  assert.match(form, /DATA ls_client TYPE t000\./);
});

test("LIKE keeps naming locals, FORM parameters, globals and system fields", async () => {
  const result = await convert([
    "REPORT zreg_decl.",
    "DATA gv_count TYPE i.",
    "DATA gv_ucomm LIKE sy-ucomm.",
    "DATA gv_flag LIKE abap_true.",
    "DATA gt_count LIKE RANGE OF gv_count.",
    "DATA gt_text LIKE RANGE OF t100-text.",
    "FORM run USING iv_value TYPE i.",
    "  DATA lv_value LIKE iv_value.",
    "  DATA lv_copy LIKE lv_value.",
    "  DATA lv_count LIKE gv_count.",
    "  lv_copy = lv_value + lv_count + iv_value.",
    "  WRITE: / lv_copy, gv_ucomm, gv_flag, lines( gt_count ), lines( gt_text ).",
    "ENDFORM.",
    "START-OF-SELECTION.",
    "  PERFORM run USING 1.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /DATA gv_ucomm LIKE sy-ucomm\./);
  assert.match(result.classSource, /DATA gv_flag LIKE abap_true\./);
  assert.match(result.classSource, /DATA gt_count LIKE RANGE OF gv_count\./);
  assert.match(result.classSource, /DATA gt_text TYPE RANGE OF t100-text\./);
  const form = method(result.classSource, "form_run");
  assert.match(form, /DATA lv_value LIKE iv_value\./);
  assert.match(form, /DATA lv_copy LIKE lv_value\./);
  assert.match(form, /DATA lv_count LIKE gv_count\./);
});

// GGCONV-REG-028: a parameter's member is mv_<name>, but LIKE <name> was
// copied as written. The component of the same name stays, see REG-018.
test("LIKE a parameter names its member, declared before it", async () => {
  const result = await example(181);
  const member = result.classSource.indexOf("DATA mv_p_dir TYPE c LENGTH 132.");
  assert.ok(member > 0, result.classSource);
  assert.ok(result.classSource.indexOf("DATA: BEGIN OF gt_hist_header, p_dir LIKE mv_p_dir, END OF gt_hist_header.") > member);
  assert.ok(result.classSource.indexOf("DATA gt_hist LIKE STANDARD TABLE OF gt_hist_header WITH DEFAULT KEY.") > member);
  assert.ok(result.classSource.indexOf("DATA gv_dir LIKE mv_p_dir.") > member);
});

// GGCONV-REG-029: TABLES *dbtab was dropped, and every use of *dbtab with it.
test("TABLES *dbtab is a second work area of dbtab", async () => {
  const result = await example(182);
  assert.match(result.classSource, /DATA t100 TYPE t100\.\n\s+DATA star_t100 TYPE t100\./);
  assert.match(result.classSource, /DATA gv_text TYPE t100-text\./);
  const start = method(result.classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /CLEAR star_t100\./);
  assert.match(start, /SELECT SINGLE \* FROM t100 INTO star_t100 WHERE arbgb = '00'\./);
  assert.match(start, /IF star_t100-arbgb = '00'\./);
  assert.match(start, /gv_text = star_t100-text\./);
  assert.match(start, /t100 = star_t100\./);
  assert.doesNotMatch(result.classSource, /\*t100/i);
});

// GGCONV-REG-030: the INTO of a SELECT without one went right after FROM
// dbtab, ahead of CLIENT SPECIFIED and the FROM clause's other additions.
test("the INTO of a SELECT into the TABLES work area follows the FROM clause", async () => {
  const start = method((await example(183)).classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /SELECT SINGLE \* FROM varid CLIENT SPECIFIED INTO varid WHERE report = 'ZGG_EX_183'\./);
  const result = await convert([
    "REPORT zreg_decl.",
    "TABLES t100.",
    "START-OF-SELECTION.",
    "  SELECT SINGLE * FROM t100 BYPASSING BUFFER.",
    "  SELECT * FROM t100 UP TO 2 ROWS ORDER BY PRIMARY KEY.",
    "    WRITE t100-text.",
    "  ENDSELECT.",
  ]);
  assert.deepEqual(errors(result, "GGCONV-E202"), []);
  assert.match(result.classSource, /SELECT SINGLE \* FROM t100 BYPASSING BUFFER INTO t100\./);
  assert.match(result.classSource, /SELECT \* FROM t100 INTO t100 UP TO 2 ROWS ORDER BY PRIMARY KEY\./);
});

// GGCONV-REG-031: PERFORM form(prog) became form_form(prog)( ). with its
// arguments dropped, as did any PERFORM of a FORM the program does not define.
test("PERFORM form(prog) calls the FORM of the other program", async () => {
  const start = method((await example(184)).classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /PERFORM p6_to_date_time_tz IN PROGRAM rstr0400 IF FOUND USING gv_time CHANGING gv_out\./);
});

test("PERFORM of a FORM the program does not define is reported", async () => {
  const result = await convert([
    "REPORT zreg_decl.",
    "DATA gv_value TYPE i.",
    "START-OF-SELECTION.",
    "  PERFORM missing USING gv_value.",
  ], { mode: "partial" });
  assert.equal(result.supported, false);
  assert.match(errors(result, "GGCONV-E516")[0]?.message ?? "", /PERFORM missing names a FORM the program does not define/);
  assert.match(result.classSource, /\* TODO GGCONV-E516: PERFORM of a FORM the program does not define/);
  assert.doesNotMatch(result.classSource, /form_missing/);
});

// GGCONV-REG-032: a function module call's last parameter ran to the
// statement's period, which stood on a line of its own after commented-out
// parameters, so es_variant = gs_variant became gs_variant -report.
test("a function module call's period on a line of its own ends the last parameter", async () => {
  const start = method((await example(185)).classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /is_request = VALUE #\( report = gs_variant-report \)/);
  assert.match(start, /cs_variant = gs_variant\n\s+cv_exit\s+= gv_exit \)\./);
  // The adapters share the parameter scan.
  const result = await convert([
    "REPORT zreg_decl.",
    "DATA gv_answer TYPE c LENGTH 1.",
    "START-OF-SELECTION.",
    "  CALL FUNCTION 'POPUP_TO_CONFIRM'",
    "    EXPORTING",
    "      text_question = 'Continue?'",
    "    IMPORTING",
    "      answer        = gv_answer",
    "*    EXCEPTIONS",
    "*      text_not_found = 1",
    "    .",
    "  WRITE gv_answer.",
  ]);
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /gv_answer = io_session->get_compatibility\( \)->popup_to_confirm\(/);
});

// GGCONV-REG-033: a PARAMETER without a type was c of length 8; ABAP makes it
// c of length 1, which a typed FORM or method parameter requires.
test("a PARAMETER without a type or length is c of length 1", async () => {
  const result = await example(186);
  assert.match(result.classSource, /DATA mv_p_flag TYPE c LENGTH 1\./);
});

// GGCONV-REG-034: DATA ... VALUE sy-repid was copied; in a class a start value
// is a literal or a constant, and sy-repid would be the class's name.
test("a start value read from sy-repid is assigned after the declaration", async () => {
  const result = await example(187);
  assert.match(result.classSource, /DATA gv_prog TYPE progname\./);
  assert.match(method(result.classSource, "zif_gg_report_v1~load_of_program"), /gv_prog = io_session->get_context\( \)-program-program\./);
  assert.match(method(result.classSource, "form_get_prog"), /DATA lv_prog TYPE progname\.[\s\S]*lv_prog = io_session->get_context\( \)-program-program\.\n\s+lo_writer->/);
  assert.doesNotMatch(result.classSource, /^\s*DATA [^\n]*VALUE sy-repid/im);
});

// GGCONV-REG-035: strict mode wrote a class that failed the converter's own
// parser validation, GGCONV-E202, although it returns no class source for an
// error diagnostic.
test("strict mode returns no class whose generated source fails validation", async () => {
  const lines = [
    "REPORT zreg_decl.",
    "INTERFACE lif.",
    "  METHODS m.",
    "ENDINTERFACE.",
    "CLASS lcl DEFINITION.",
    "  PUBLIC SECTION.",
    "    INTERFACES lif.",
    "ENDCLASS.",
    "CLASS lcl IMPLEMENTATION.",
    "  METHOD lif~m.",
    "  ENDMETHOD.",
    "ENDCLASS.",
    "START-OF-SELECTION.",
    "  NEW lcl( )->lif~m( ).",
  ];
  const partial = await convert(lines, { mode: "partial" });
  assert.ok(errors(partial, "GGCONV-E202").length);
  assert.ok(partial.classSource);
  const strict = await convert(lines, { mode: "strict" });
  assert.ok(errors(strict, "GGCONV-E202").length);
  assert.equal(strict.supported, false);
  assert.equal(strict.classSource, undefined);
  assert.equal(strict.helperSources, undefined);
});
