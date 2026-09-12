import assert from "node:assert/strict";
import { convertProgram } from "../src/api.mjs";

const variants = [
  `REPORT z_fuzz.\nDATA gv_count TYPE i.\nSTART-OF-SELECTION.\n  WRITE: / 'a', gv_count.\n`,
  `\uFEFFREPORT   z_fuzz.\r\n\r\n* harmless comment\r\nDATA gv_count TYPE i.\r\nSTART-OF-SELECTION.\r\n  WRITE: / 'a', gv_count.\r\n`,
  `REPORT z_fuzz.\nDATA gv_count TYPE i.\nSTART-OF-SELECTION.\n  IF gv_count = 0.\n    DO 1 TIMES.\n      WRITE / 'nested'.\n    ENDDO.\n  ELSE.\n    WRITE / 'other'.\n  ENDIF.\n`,
];

for (const [index, source] of variants.entries()) {
  const first = await convertProgram({ source, filename: `fuzz-${index}.prog.abap` });
  const second = await convertProgram({ source, filename: `fuzz-${index}.prog.abap` });
  assert.equal(first.supported, true, `fuzz variant ${index} was rejected`);
  assert.equal(first.classSource, second.classSource, `fuzz variant ${index} is not deterministic`);
  assert.doesNotMatch(first.classSource, /TODO GGCONV-E501/);
}

const oversized = await convertProgram({ source: "REPORT z_fuzz.\n" + "*x\n".repeat(10), filename: "oversized.prog.abap", maxSourceLines: 3 });
assert.equal(oversized.supported, false);
assert.ok(oversized.diagnostics.some((item) => item.code === "GGCONV-E108"));
const oversizedBytes = await convertProgram({ source: "REPORT z_fuzz.\n" + "*x\n".repeat(10), filename: "oversized-bytes.prog.abap", maxSourceBytes: 10 });
assert.equal(oversizedBytes.supported, false);
assert.ok(oversizedBytes.diagnostics.some((item) => item.code === "GGCONV-E107"));

console.log(`hardening corpus passed for ${variants.length} syntax variants and source limits`);
