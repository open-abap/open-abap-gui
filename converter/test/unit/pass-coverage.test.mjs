import assert from "node:assert/strict";
import test from "node:test";
import { emptyReportIR } from "../../src/ir/report-ir.mjs";
import { dynproProgramIR } from "../../src/ir/dynpro-ir.mjs";
import { buildSourceIndex } from "../../src/source-index.mjs";
import { analyzeFieldSymbols } from "../../src/passes/analyze-field-symbols.mjs";
import { analyzeReferences } from "../../src/passes/analyze-references.mjs";
import { classifyProgram, eventName } from "../../src/passes/classify-program.mjs";
import { collectDeclarations } from "../../src/passes/collect-declarations.mjs";
import { collectEvents } from "../../src/passes/collect-events.mjs";
import { collectModules } from "../../src/passes/collect-modules.mjs";
import { collectRoutines } from "../../src/passes/collect-routines.mjs";
import { collectSelectionScreens } from "../../src/passes/collect-selection-screens.mjs";
import { buildControlFlowGraphs } from "../../src/passes/control-flow.mjs";
import { collectContinuations } from "../../src/passes/lower-continuations.mjs";
import { buildStatePlan } from "../../src/passes/lower-state.mjs";
import { resolveTypes } from "../../src/passes/resolve-types.mjs";
import { selectInterfaces } from "../../src/passes/select-interfaces.mjs";
import { LOWERING_RULES, lowerStatement } from "../../src/passes/lower-statements.mjs";

let nextLine = 1;
function statement(kind, text) {
  const line = nextLine++;
  return {
    kind,
    text,
    filename: "pass-coverage.prog.abap",
    span: { start: { line, column: 1 }, end: { line, column: Math.max(1, text.length) } },
  };
}

function resetLines() {
  nextLine = 1;
}

test("directly exercises every report-IR collector and analysis pass", () => {
  resetLines();
  const report = statement("Report", "REPORT zpass_coverage.");
  const data = statement("Data", "DATA gv_value TYPE i.");
  const parameter = statement("Parameter", "PARAMETERS p_value TYPE i.");
  const selection = statement("SelectionScreen", "SELECTION-SCREEN BEGIN OF BLOCK b.");
  const selectionEnd = statement("SelectionScreen", "SELECTION-SCREEN END OF BLOCK b.");
  const start = statement("StartOfSelection", "START-OF-SELECTION.");
  const write = statement("Write", "WRITE gv_value.");
  const form = statement("Form", "FORM add USING iv_value TYPE i.");
  const formData = statement("Data", "DATA lv_local TYPE i.");
  const perform = statement("Perform", "PERFORM add USING gv_value.");
  const endForm = statement("EndForm", "ENDFORM.");
  const module = statement("Module", "MODULE pbo OUTPUT.");
  const moduleWrite = statement("Write", "WRITE 'module'.");
  const endModule = statement("EndModule", "ENDMODULE.");

  const classification = classifyProgram([report, start, write]);
  assert.equal(classification.programKind, "report");
  assert.equal(classification.programName, "ZPASS_COVERAGE");
  assert.equal(eventName(start), "start_of_selection");

  const declarations = collectDeclarations([data, parameter, selection, selectionEnd]);
  assert.deepEqual(declarations.map((item) => item.kind), ["data", "parameter", "selectionscreen", "selectionscreen"]);
  const screens = collectSelectionScreens(declarations);
  assert.equal(screens[0].number, "0100");
  assert.ok(screens[0].elements.some((item) => item.kind === "parameter"));

  const ir = emptyReportIR({ filename: report.filename, source: "", sourceHash: "hash", newline: "\n" });
  ir.programName = classification.programName;
  ir.programKind = classification.programKind;
  collectEvents(ir, [report, data, parameter, start, write, form, formData, perform, endForm, module, moduleWrite, endModule]);
  assert.ok(ir.events.start_of_selection.some((item) => item.kind === "Write"));
  assert.equal(ir.routines.length, 1);
  assert.equal(ir.modules.length, 0);
  assert.equal(ir.localClasses.length, 0);

  const routines = collectRoutines(ir);
  assert.equal(routines.routines[0].methodName, "form_add");
  assert.equal(routines.routines[0].parameters[0].direction, "IMPORTING");
  assert.equal(collectModules([module, moduleWrite, endModule]).length, 1);

  ir.declarations = declarations;
  ir.selections = screens;
  ir.sourceIndex = buildSourceIndex(ir);
  assert.ok(ir.sourceIndex.symbols.some((item) => item.name === "GV_VALUE"));
  ir.statePlan = buildStatePlan(ir);
  assert.ok(ir.statePlan.globals.includes("GV_VALUE"));
  assert.ok(ir.statePlan.selections.includes("P_VALUE"));
  ir.statements = [data, write];
  ir.references = analyzeReferences(ir);
  assert.ok(ir.references.statements[1].reads.includes("GV_VALUE"));

  const fieldSymbol = statement("FieldSymbol", "FIELD-SYMBOLS <lv_value> TYPE i.");
  const assign = statement("Assign", "ASSIGN gv_value TO <lv_value>.");
  ir.declarations = [...declarations, { kind: "field-symbol", names: ["LV_VALUE"], raw: fieldSymbol.text, statement: fieldSymbol }];
  fieldSymbol.scope = "local";
  ir.eventBlocks = [{ event: "start_of_selection", statements: [fieldSymbol, assign] }];
  assert.ok(analyzeFieldSymbols(ir).has("LV_VALUE"));

  const callScreen = statement("CallScreen", "CALL SCREEN 100.");
  const continuations = collectContinuations([callScreen], ["GV_VALUE"]);
  assert.equal(continuations.length, 1);
  ir.continuations = continuations;
  ir.eventBlocks = [{ event: "start_of_selection", statements: [callScreen] }];
  assert.equal(buildControlFlowGraphs(ir).length, 1);

  const type = statement("Type", "TYPES ty_value TYPE i.");
  const typeIR = emptyReportIR({ filename: type.filename, source: "", sourceHash: "hash", newline: "\n" });
  typeIR.declarations = [{ kind: "type", names: ["TY_VALUE"], raw: type.text, statement: type }];
  const typeDiagnostics = [];
  resolveTypes(typeIR, {}, typeDiagnostics);
  assert.equal(typeDiagnostics.length, 0);
  assert.equal(typeIR.declarations[0].resolved, true);
  typeIR.features = ["list-processing", "continuation"];
  typeIR.programKind = "report";
  selectInterfaces(typeIR);
  assert.ok(typeIR.interfaces.includes("zif_gg_list_processing_v1"));
  assert.ok(typeIR.interfaces.includes("zif_gg_resumable_v1"));
  typeIR.dynproMetadata = { initialScreen: "0100", screens: [] };
  assert.equal(dynproProgramIR(typeIR).kind, "dynpro-program");
});

test("every registered lowering rule has a direct positive fixture", () => {
  resetLines();
  const context = {
    replacements: [],
    selections: [],
    selectionState: {},
    safeFieldSymbols: ["FS"],
    routines: [{ name: "ADD", methodName: "form_add", parameters: [] }],
    guiStatusMetadata: {},
    activeCommands: [],
    activePFKeys: [],
    mutableValues: false,
  };
  const sourceByKind = {
    Write: "WRITE 'x'.",
    Skip: "SKIP 1.",
    Uline: "ULINE.",
    NewLine: "NEW-LINE.",
    Format: "FORMAT RESET.",
    SetBlank: "SET BLANK LINES ON.",
    Reserve: "RESERVE 1 LINES.",
    NewPage: "NEW-PAGE.",
    Stop: "STOP.",
    Message: "MESSAGE 'x' TYPE I.",
    SetPFStatus: "SET PF-STATUS 'MAIN'.",
    SetTitlebar: "SET TITLEBAR 'MAIN'.",
    CallSelectionScreen: "CALL SELECTION-SCREEN 100.",
    CallScreen: "CALL SCREEN 100.",
    Submit: "SUBMIT ztarget.",
    CallTransaction: "CALL TRANSACTION 'SE38'.",
    Append: "APPEND ls_value TO lt_values.",
    Collect: "COLLECT ls_value INTO lt_values.",
    InsertInternal: "INSERT ls_value INTO TABLE lt_values.",
    DeleteInternal: "DELETE lt_values INDEX 1.",
    ModifyInternal: "MODIFY lt_values FROM ls_value.",
    ReadTable: "READ TABLE lt_values INTO ls_value INDEX 1.",
    Select: "SELECT * FROM zsflight INTO TABLE lt_values.",
    SelectLoop: "SELECT * FROM zsflight INTO ls_value.",
    EndSelect: "ENDSELECT.",
    InsertDatabase: "INSERT zsflight FROM ls_value.",
    UpdateDatabase: "UPDATE zsflight FROM ls_value.",
    DeleteDatabase: "DELETE FROM zsflight.",
    ModifyDatabase: "MODIFY zsflight FROM ls_value.",
    Clear: "CLEAR gv_value.",
    Add: "ADD 1 TO gv_value.",
    Subtract: "SUBTRACT 1 FROM gv_value.",
    Multiply: "MULTIPLY gv_value BY 2.",
    Divide: "DIVIDE gv_value BY 2.",
    Compute: "COMPUTE gv_value = gv_value + 1.",
    Leave: "LEAVE PROGRAM.",
    SetScreen: "SET SCREEN 100.",
    LeaveScreen: "LEAVE SCREEN.",
    LeaveToScreen: "LEAVE TO SCREEN 100.",
    GetCursor: "GET CURSOR FIELD gv_value.",
    ReadLine: "READ LINE 1.",
    ModifyLine: "MODIFY LINE 1.",
    Hide: "HIDE gv_value.",
    Perform: "PERFORM add.",
    Return: "RETURN.",
    Translate: "TRANSLATE gv_value TO UPPER CASE.",
    LoopAtScreen: "LOOP AT SCREEN.",
    ModifyScreen: "MODIFY SCREEN.",
    Move: "gv_value = 1.",
    If: "IF gv_value = 1.",
    Else: "ELSE.",
    ElseIf: "ELSEIF gv_value = 2.",
    EndIf: "ENDIF.",
    Do: "DO 1 TIMES.",
    EndDo: "ENDDO.",
    Case: "CASE gv_value.",
    When: "WHEN 1.",
    WhenOthers: "WHEN OTHERS.",
    EndCase: "ENDCASE.",
    Loop: "LOOP AT lt_values INTO ls_value.",
    EndLoop: "ENDLOOP.",
    Try: "TRY.",
    Catch: "CATCH cx_root.",
    Cleanup: "CLEANUP.",
    EndTry: "ENDTRY.",
    Data: "DATA gv_local TYPE i.",
    TypeBegin: "TYPES BEGIN OF ty_row.",
    TypeEnd: "TYPES END OF ty_row.",
    Constant: "CONSTANTS gc_value TYPE i VALUE 1.",
    Static: "STATICS gv_static TYPE i.",
    Assign: "ASSIGN gv_value TO <fs>.",
    FieldSymbol: "FIELD-SYMBOLS <fs> TYPE i.",
    Comment: "* comment",
    Empty: "",
  };
  const continuationKinds = new Set(["CallSelectionScreen", "CallScreen", "CallTransaction"]);
  for (const kind of LOWERING_RULES.keys()) {
    const source = sourceByKind[kind];
    assert.notEqual(source, undefined, `missing direct fixture for ${kind}`);
    const item = statement(kind, source);
    const itemContext = { ...context };
    if (continuationKinds.has(kind)) {
      itemContext.continuations = [{ filename: item.filename, span: item.span, id: `C_${kind.toUpperCase()}` }];
    }
    const lowered = lowerStatement(item, itemContext);
    assert.notEqual(lowered, undefined, `${kind} lowering returned undefined`);
    assert.doesNotMatch(String(lowered), /TODO GGCONV-E\d+/, `${kind} lowering emitted a TODO`);
  }
});
