import assert from "node:assert/strict";
import test from "node:test";
import { convertProgram } from "../../src/api.mjs";

const methodBody = (source, name) => source.match(new RegExp(`METHOD ${name.replace(/~/g, "~")}\\.[\\s\\S]*?ENDMETHOD\\.`))?.[0] ?? "";
const resumeBranch = (resume, id) => resume.match(new RegExp(`WHEN '${id}'\\.([\\s\\S]*?)(?=\\n\\s*WHEN '|\\n\\s*WHEN OTHERS\\.)`))?.[1] ?? "";

// A cockpit that dispatches each action to a transaction: the first CALL
// TRANSACTION used to end the method, so every later WHEN disappeared.
const COCKPIT = [
  "REPORT zcockpit.",
  "DATA gv_ucomm TYPE sy-ucomm.",
  "DATA gv_tcode TYPE sy-tcode.",
  "START-OF-SELECTION.",
  "  WRITE / 'start'.",
  "  CASE gv_ucomm.",
  "    WHEN 'CFG'.",
  "      CALL TRANSACTION 'ZCFG' AND SKIP FIRST SCREEN.",
  "      WRITE / 'after config'.",
  "    WHEN 'LOG'.",
  "      WRITE / 'log inline'.",
  "    WHEN 'QUEUE'.",
  "      CALL TRANSACTION gv_tcode.",
  "      WRITE / 'after queue'.",
  "    WHEN OTHERS.",
  "      WRITE / 'unknown action'.",
  "  ENDCASE.",
  "  WRITE / 'after case'.",
].join("\n");

test("keeps every CASE branch around a suspending CALL TRANSACTION", async () => {
  const result = await convertProgram({ source: COCKPIT, filename: "zcockpit.prog.abap" });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.deepEqual(result.diagnostics, []);
  const start = methodBody(result.classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /WHEN 'CFG'\.\s+io_session->get_navigation\( \)->call_transaction\([\s\S]*tcode = 'ZCFG' skip_first_screen = abap_true[\s\S]*\)\.\s+WHEN 'LOG'\./);
  assert.match(start, /WHEN 'LOG'\.[\s\S]*log inline/);
  assert.match(start, /WHEN 'QUEUE'\.\s+io_session->get_navigation\( \)->call_transaction\([\s\S]*tcode = CONV #\( gv_tcode \)[\s\S]*\)\.\s+WHEN OTHERS\./);
  assert.match(start, /WHEN OTHERS\.[\s\S]*unknown action[\s\S]*ENDCASE\.[\s\S]*after case/);
  // The call does not return, so what follows it in its branch runs only
  // from the continuation.
  assert.doesNotMatch(start, /after config|after queue/);
  assert.equal(result.reportIR.continuations.length, 2);
});

test("resumes only the path after the suspension, without repeating earlier side effects", async () => {
  const result = await convertProgram({ source: COCKPIT, filename: "zcockpit.prog.abap" });
  const resume = methodBody(result.classSource, "zif_gg_resumable_v1~resume");
  const [config, queue] = result.reportIR.continuations.map((item) => item.id);
  const afterConfig = resumeBranch(resume, config);
  assert.match(afterConfig, /after config[\s\S]*after case/);
  assert.doesNotMatch(afterConfig, /'start'|log inline|after queue|unknown action|call_transaction/);
  const afterQueue = resumeBranch(resume, queue);
  assert.match(afterQueue, /after queue[\s\S]*after case/);
  assert.doesNotMatch(afterQueue, /'start'|after config|log inline|unknown action/);
  // Every continuation writes, and one method may declare lo_writer once.
  assert.equal([...resume.matchAll(/DATA\(lo_writer\)/g)].length, 1);
});

test("keeps sibling branches of suspensions in IF and in a FORM", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zroutine.",
      "DATA gv_mode TYPE c LENGTH 1.",
      "START-OF-SELECTION.",
      "  PERFORM dispatch.",
      "FORM dispatch.",
      "  IF gv_mode = 'S'.",
      "    CALL SCREEN 100.",
      "    WRITE / 'after screen'.",
      "  ELSEIF gv_mode = 'R'.",
      "    SUBMIT zother AND RETURN.",
      "    WRITE / 'after submit'.",
      "  ELSE.",
      "    WRITE / 'no navigation'.",
      "  ENDIF.",
      "  WRITE / 'after if'.",
      "ENDFORM.",
    ].join("\n"),
    filename: "zroutine.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const form = methodBody(result.classSource, "form_dispatch");
  assert.match(form, /call_screen\([\s\S]*ELSEIF gv_mode = 'R'\.[\s\S]*submit_and_return\([\s\S]*ELSE\.[\s\S]*no navigation[\s\S]*ENDIF\.[\s\S]*after if/);
  assert.doesNotMatch(form, /after screen|after submit/);
  const resume = methodBody(result.classSource, "zif_gg_resumable_v1~resume");
  const afterScreen = resumeBranch(resume, "AFTER_0100");
  assert.match(afterScreen, /after screen[\s\S]*after if/);
  assert.doesNotMatch(afterScreen, /after submit|no navigation|ELSE/);
  const afterSubmit = resumeBranch(resume, "AFTER_SUBMIT");
  assert.match(afterSubmit, /after submit[\s\S]*after if/);
  assert.doesNotMatch(afterSubmit, /after screen|no navigation/);
});

test("reopens a TRY around a resumed suspension and passes the unwinding through cx_root handlers", async () => {
  const result = await convertProgram({
    source: [
      "REPORT ztry.",
      "START-OF-SELECTION.",
      "  TRY.",
      "      WRITE / 'before'.",
      "      CALL SCREEN 100.",
      "      WRITE / 'after screen'.",
      "    CATCH cx_sy_conversion_error.",
      "      WRITE / 'conversion'.",
      "    CATCH cx_root INTO DATA(lx_error).",
      "      WRITE / 'caught'.",
      "  ENDTRY.",
      "  WRITE / 'after try'.",
    ].join("\n"),
    filename: "ztry.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.equal(result.diagnostics.some((item) => item.code === "GGCONV-W402"), false);
  const start = methodBody(result.classSource, "zif_gg_report_v1~start_of_selection");
  // Only the handler that would catch zcx_gg_control_flow passes it on.
  assert.match(start, /call_screen\([\s\S]*CATCH cx_sy_conversion_error\.\s+lo_writer[\s\S]*CATCH cx_root INTO DATA\(lx_error\)\.\s+IF lx_error IS INSTANCE OF zcx_gg_control_flow\.\s+RAISE EXCEPTION lx_error\.\s+ENDIF\.\s+lo_writer[\s\S]*caught/);
  assert.match(start, /ENDTRY\.[\s\S]*after try/);
  const afterScreen = resumeBranch(methodBody(result.classSource, "zif_gg_resumable_v1~resume"), "AFTER_0100");
  assert.match(afterScreen, /^\s*TRY\.[\s\S]*after screen[\s\S]*CATCH cx_sy_conversion_error\.[\s\S]*conversion[\s\S]*CATCH cx_root INTO[\s\S]*caught[\s\S]*ENDTRY\.[\s\S]*after try/);
  assert.doesNotMatch(afterScreen, /'before'/);
});

test("gives a cx_root handler without a target one to pass the host's unwinding on", async () => {
  const result = await convertProgram({
    source: "REPORT zcatchall.\nSTART-OF-SELECTION.\nTRY.\n    CALL TRANSACTION 'SE16'.\n  CATCH cx_root.\n    WRITE / 'failed'.\nENDTRY.\n",
    filename: "zcatchall.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const start = methodBody(result.classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /DATA lx_ggconv_caught TYPE REF TO cx_root\./);
  assert.match(start, /CATCH cx_root INTO lx_ggconv_caught\.\s+IF lx_ggconv_caught IS INSTANCE OF zcx_gg_control_flow\.\s+RAISE EXCEPTION lx_ggconv_caught\.\s+ENDIF\./);
});

test("drops only the unreachable rest of a block after a terminal statement", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zterminal.",
      "DATA gv_mode TYPE c LENGTH 1.",
      "START-OF-SELECTION.",
      "  IF gv_mode = 'X'.",
      "    LEAVE PROGRAM.",
      "    WRITE / 'unreachable'.",
      "  ELSEIF gv_mode = 'Y'.",
      "    WRITE / 'branch y'.",
      "  ENDIF.",
      "  LOOP AT SCREEN.",
      "  ENDLOOP.",
      "  WRITE / 'after if'.",
    ].join("\n"),
    filename: "zterminal.prog.abap",
    mode: "partial",
  });
  const start = methodBody(result.classSource, "zif_gg_report_v1~start_of_selection");
  assert.match(start, /leave_program\( \)\.\s+ELSEIF gv_mode = 'Y'\.[\s\S]*branch y[\s\S]*ENDIF\.[\s\S]*after if/);
  assert.doesNotMatch(start, /unreachable/);
});

test("warns that a suspension inside a loop resumes after the loop", async () => {
  const result = await convertProgram({
    source: "REPORT zloopwarn.\nSTART-OF-SELECTION.\nDO 2 TIMES.\n  CALL SCREEN 100.\n  WRITE / 'inside'.\nENDDO.\nWRITE / 'after'.\n",
    filename: "zloopwarn.prog.abap",
  });
  const warning = result.diagnostics.find((item) => item.code === "GGCONV-W402");
  assert.ok(warning, JSON.stringify(result.diagnostics));
  assert.match(warning.message, /remaining iterations do not run/);
});

test("reports CALL TRANSACTION ... USING instead of dropping the batch-input table", async () => {
  const result = await convertProgram({
    source: "REPORT zbdc.\nDATA gt_bdc TYPE STANDARD TABLE OF bdcdata WITH DEFAULT KEY.\nSTART-OF-SELECTION.\nCALL TRANSACTION 'SE16' USING gt_bdc MODE 'E'.\n",
    filename: "zbdc.prog.abap",
    mode: "partial",
  });
  assert.match(result.classSource, /TODO GGCONV-E516: CALL TRANSACTION \.\.\. USING/);
  assert.doesNotMatch(result.classSource, /call_transaction\(/);
  assert.equal(result.supported, false);
});

test("keeps helper method bodies that write, using the helper's stored session", async () => {
  const result = await convertProgram({
    source: [
      "REPORT zbackup.",
      "DATA gv_count TYPE i.",
      "CLASS lcl_backup DEFINITION.",
      "  PUBLIC SECTION.",
      "    METHODS export IMPORTING iv_rows TYPE i.",
      "    CLASS-METHODS status IMPORTING iv_text TYPE string.",
      "ENDCLASS.",
      "CLASS lcl_backup IMPLEMENTATION.",
      "  METHOD export.",
      "    gv_count = gv_count + iv_rows.",
      "    WRITE: / 'Exported rows:', gv_count.",
      "  ENDMETHOD.",
      "  METHOD status.",
      "    WRITE / iv_text.",
      "  ENDMETHOD.",
      "ENDCLASS.",
      "START-OF-SELECTION.",
      "  DATA(lo_backup) = NEW lcl_backup( ).",
      "  lo_backup->export( 3 ).",
      "  lcl_backup=>status( 'Backup written' ).",
    ].join("\n"),
    filename: "zbackup.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  const helper = result.helperSources?.[0]?.source ?? "";
  assert.doesNotMatch(helper, /TODO GGCONV/);
  const exportBody = methodBody(helper, "export");
  assert.match(exportBody, /DATA\(lo_writer\) = mo_session->get_list\( \)->get_writer\( \)\./);
  assert.match(exportBody, /mo_owner->gv_count = mo_owner->gv_count \+ iv_rows\./);
  assert.match(exportBody, /text = 'Exported rows:'/);
  const statusBody = methodBody(helper, "status");
  assert.match(statusBody, /DATA\(lo_writer\) = io_session->get_list\( \)->get_writer\( \)\./);
  assert.match(statusBody, /text = \|\{ iv_text \}\|/);
});
