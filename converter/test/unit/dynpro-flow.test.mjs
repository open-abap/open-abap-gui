import test from "node:test";
import assert from "node:assert/strict";
import { loadDynproMetadata } from "../../src/dynpro-metadata.mjs";

async function parseFlowLogic(source) {
  const metadata = await loadDynproMetadata({
    filename: "demo.prog.abap",
    screenFiles: [{filename: "demo.prog.screen_0100.abap", source}],
    readFile: async () => '<abapGit><asx:abap xmlns:asx="http://www.sap.com/abapxml"><asx:values/></asx:abap></abapGit>',
  });
  return metadata.flowLogic[0];
}

test("multiline and chained screen fields retain their module associations", async () => {
  const flow = await parseFlowLogic(`PROCESS AFTER INPUT.
  CHAIN.
    FIELD: choice_a,
           choice_b.
    MODULE choose ON CHAIN-REQUEST.
    FIELD report_name:
      MODULE validate.
  ENDCHAIN.
PROCESS ON VALUE-REQUEST.
  FIELD report_name
    MODULE lookup.
PROCESS ON HELP-REQUEST.
  FIELD report_name MODULE help.
`, "demo.prog.screen_0100.abap", "0100");
  assert.deepEqual(flow.steps.filter(s => s.kind === "field").map(s => s.field), ["CHOICE_A", "CHOICE_B"]);
  assert.deepEqual(flow.steps.filter(s => s.kind === "field").map(s => s.line), [3, 4]);
  assert.equal(flow.pai[0].name, "CHOOSE");
  assert.equal(flow.pai[0].onRequest, true);
  assert.equal(flow.pai[0].onChainRequest, true);
  assert.equal(flow.pai[1].field, "REPORT_NAME");
  assert.equal(flow.pai[1].chainDepth, 1);
  assert.equal(flow.pov.modules[0].name, "LOOKUP");
  assert.equal(flow.pov.modules[0].field, "REPORT_NAME");
  assert.equal(flow.poh.modules[0].name, "HELP");
});

test("comments and several statements on a line preserve flow phases", async () => {
  const flow = await parseFlowLogic(`* MODULE never.
PROCESS BEFORE OUTPUT. MODULE initialize. " MODULE never.
PROCESS AFTER INPUT.
MODULE exit AT EXIT-COMMAND.
`, "demo.prog.screen_0100.abap", "0100");
  assert.deepEqual(flow.pbo.map(m => m.name), ["INITIALIZE"]);
  assert.equal(flow.pbo[0].line, 2);
  assert.equal(flow.pai[0].atExitCommand, true);
});

test("separate request FIELD and MODULE statements keep each field association", async () => {
  const flow = await parseFlowLogic(`PROCESS ON VALUE-REQUEST.
FIELD first. MODULE lookup_first.
FIELD second. MODULE lookup_second.
PROCESS ON HELP-REQUEST.
FIELD third. MODULE help_third.
`);
  assert.deepEqual(flow.pov.modules.map(m => [m.name, m.field]), [["LOOKUP_FIRST", "FIRST"], ["LOOKUP_SECOND", "SECOND"]]);
  assert.deepEqual(flow.poh.modules.map(m => [m.name, m.field]), [["HELP_THIRD", "THIRD"]]);
  assert.equal(flow.pov.field, "FIRST");
});

test("CHAIN-INPUT and CHAIN-REQUEST stay distinct from single-field additions", async () => {
  const flow = await parseFlowLogic(`PROCESS AFTER INPUT.
CHAIN.
FIELD first.
MODULE check_input ON CHAIN-INPUT.
MODULE check_request ON CHAIN-REQUEST.
ENDCHAIN.
FIELD second MODULE check_single ON INPUT.
`);
  assert.equal(flow.pai[0].onChainInput, true);
  assert.equal(flow.pai[0].onInput, false);
  assert.equal(flow.pai[1].onChainRequest, true);
  assert.equal(flow.pai[1].onChainInput, false);
  assert.equal(flow.pai[2].onInput, true);
  assert.equal(flow.pai[2].onChainInput, false);
});
