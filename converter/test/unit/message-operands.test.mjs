import test from "node:test";
import assert from "node:assert/strict";
import { convertProgram } from "../../src/api.mjs";

test("long MESSAGE keeps keywords inside quoted operands", async () => {
  const result = await convertProgram({
    source: `REPORT zmessage_operands.
MESSAGE ID 'ZMSG' TYPE 'I' NUMBER '001'
  WITH 'DISPLAY LIKE' 'TYPE NUMBER' 'WITH' 'it''s "ok"' DISPLAY LIKE 'E'.`,
    filename: "zmessage_operands.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /type = zif_gg_session_types_v1=>message_type_info id = 'ZMSG' number = '001'/);
  assert.match(result.classSource, /v1 = 'DISPLAY LIKE' v2 = 'TYPE NUMBER' v3 = 'WITH' v4 = 'it''s "ok"'/);
  assert.match(result.classSource, /display_like = zif_gg_session_types_v1=>message_type_error/);
});

test("long MESSAGE retains dynamic fields beside quoted additions", async () => {
  const result = await convertProgram({
    source: `REPORT zmessage_dynamic.
DATA lv_id TYPE c LENGTH 20.
DATA lv_type TYPE c LENGTH 1.
DATA lv_number TYPE n LENGTH 3.
DATA lv_value TYPE string.
MESSAGE ID lv_id TYPE lv_type NUMBER lv_number
  WITH lv_value 'DISPLAY LIKE' 'WITH' 'NUMBER' DISPLAY LIKE lv_type.`,
    filename: "zmessage_dynamic.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /type = lv_type id = lv_id number = lv_number/);
  assert.match(result.classSource, /v1 = lv_value v2 = 'DISPLAY LIKE' v3 = 'WITH' v4 = 'NUMBER' display_like = lv_type/);
});

test("short MESSAGE preserves hash and namespace characters in its class", async () => {
  const result = await convertProgram({
    source: `REPORT zmessage_classes.
MESSAGE e001(z#) WITH 'example'.
MESSAGE i002(/demo/msg) WITH 'example'.`,
    filename: "zmessage_classes.prog.abap",
  });
  assert.equal(result.supported, true, JSON.stringify(result.diagnostics));
  assert.match(result.classSource, /id = 'Z#' number = '001' v1 = 'example'/);
  assert.match(result.classSource, /id = '\/DEMO\/MSG' number = '002'/);
  assert.doesNotMatch(result.classSource, /ia_text\s*=\s*e001/i);
});
