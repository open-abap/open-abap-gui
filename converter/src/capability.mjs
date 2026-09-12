import { diagnostic } from "./diagnostics.mjs";
import { eventName, normalizedText } from "./passes/classify-program.mjs";
import { LOWERING_RULES, METHOD_SAFE_STATEMENTS, OPEN_SQL_STATEMENTS, dynamicWriteOperand, isMethodSafeLoop, isStaticOpenSql } from "./passes/lower-statements.mjs";

const SUPPORTED_STATEMENTS = new Set([
  "Comment", "Empty", "Report", "Program", "Data", "DataBegin", "DataEnd", "Constant", "Static", "Parameter", "SelectOption", "Tables", "Type", "TypeBegin", "TypeEnd",
  "SelectionScreen", "StartOfSelection", "EndOfSelection", "LoadOfProgram", "Initialization", "AtSelectionScreen",
  "AtLineSelection", "AtUserCommand", "AtPF", "TopOfPage", "EndOfPage", "Write", "Skip", "Uline", "Format",
  "NewLine", "SetBlank", "Reserve", "NewPage", "Stop", "Message", "If", "Else", "ElseIf", "EndIf", "Do", "EndDo",
  "Case", "When", "WhenOthers", "EndCase", "Loop", "EndLoop", "Move", "Return", "Hide", "GetCursor", "ReadLine",
  "ModifyLine", "SetPFStatus", "SetTitlebar", "Leave", "AtSelectionScreenOutput", "LoopAtScreen", "ModifyScreen",
  "Form", "EndForm", "Perform", "Translate", "TopOfPageDuringLineSelection", "CallSelectionScreen", "CallScreen", "EndClass",
  "Try", "Catch", "Cleanup", "EndTry",
  "Submit", "CallTransaction", "Include", "Append", "Collect", "InsertInternal", "DeleteInternal", "ModifyInternal", "ReadTable", "Assign",
  "Clear", "Add", "Subtract", "Multiply", "Divide", "Compute",
  "Select", "SelectLoop", "EndSelect", "InsertDatabase", "UpdateDatabase", "DeleteDatabase", "ModifyDatabase",
]);

function addStatementDiagnostic(diagnostics, statement, message, suggestion, code = "GGCONV-E501") {
  diagnostics.push(diagnostic({
    code,
    filename: statement.filename,
    start: statement.span.start,
    end: statement.span.end,
    construct: normalizedText(statement),
    message,
    suggestion,
    phase: "capability",
  }));
}

function loopName(statement) {
  return /^LOOP\s+AT\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text.trim())?.[1]?.toUpperCase();
}

function isSelectionRangeLoop(ir, statement) {
  const name = loopName(statement);
  return Boolean(name && ir.selections?.some((selection) => selection.name === name && selection.ranges));
}

function hasDynamicWriteTargets(ir) {
  if ((ir.declarations ?? []).some((declaration) => declaration.statement?.scope !== "local" && ["data", "static", "tables"].includes(declaration.kind) && (declaration.names ?? []).length)) return true;
  return (ir.selections ?? []).some((screen) => (screen.elements ?? []).some((element) => element.name));
}

export function scanCapabilities(ir, statements, { mode = "strict" } = {}) {
  const diagnostics = [];
  const interfaces = new Set(ir.interfaces);
  for (const continuation of ir.continuations ?? []) {
    const unsafeContext = (continuation.controlStack ?? []).find((item) => ["Do", "Loop", "Try", "While"].includes(item.kind));
    if (unsafeContext) {
      const statement = statements.find((item) => item.filename === continuation.filename && item.span.start.line === continuation.span.start.line && item.span.start.column === continuation.span.start.column);
      if (statement) addStatementDiagnostic(diagnostics, statement, `suspending navigation inside ${unsafeContext.kind.toUpperCase()} cannot be split safely yet`, "Move the suspension to an event boundary or provide an explicit continuation mapping.", "GGCONV-E402");
    }
  }
  for (const duplicate of ir.duplicateEvents ?? []) {
    addStatementDiagnostic(diagnostics, duplicate.statement, `duplicate singleton event ${duplicate.event} is ambiguous after conversion`, "Merge the event blocks into one ordered handler or provide an explicit event mapping.", "GGCONV-E203");
  }
  for (const statement of statements) {
    const text = normalizedText(statement).toUpperCase();
    if (["ClassDefinition", "ClassImplementation"].includes(statement.kind)) {
      addStatementDiagnostic(diagnostics, statement, "local class definitions are not emitted into the generated report class pool", "Move the local class to a separate global class or provide a manual class-pool mapping.", "GGCONV-E305");
      continue;
    }
    if (statement.kind === "FieldSymbol") {
      if (ir.safeFieldSymbols?.includes([...statement.text.matchAll(/<([A-Z][A-Z0-9_]*)>/gi)].map((match) => match[1].toUpperCase())[0])) continue;
      addStatementDiagnostic(diagnostics, statement, "field-symbol declarations require method-local binding analysis", "Move the field symbol into a generated method or provide an explicit field-symbol lowering rule.", "GGCONV-E501");
      continue;
    }
    if (statement.kind === "Assign" && !ir.safeFieldSymbols?.includes(/\bTO\s+<([A-Z][A-Z0-9_]*)>/i.exec(statement.text)?.[1]?.toUpperCase())) {
      addStatementDiagnostic(diagnostics, statement, "dynamic or unproven ASSIGN cannot be lowered safely", "Use a method-local elementary field symbol with a static ASSIGN target, or convert it manually.", "GGCONV-E501");
      continue;
    }
    if (OPEN_SQL_STATEMENTS.has(statement.kind) && !isStaticOpenSql(statement)) {
      addStatementDiagnostic(diagnostics, statement, "dynamic Open SQL cannot be preserved safely inside the generated method", "Use a statically named table and fields or provide a dedicated data-access lowering rule.", "GGCONV-E501");
      continue;
    }
    if (statement.kind === "Loop" && !isMethodSafeLoop(statement) && !isSelectionRangeLoop(ir, statement)) {
      addStatementDiagnostic(diagnostics, statement, "implicit-header-table LOOP cannot be lowered safely into a method", "Add an explicit INTO or ASSIGNING target, or provide a dedicated method-scope loop lowering rule.", "GGCONV-E501");
    }
    const supportedSpecial = statement.kind === "CallFunction" && /CALL\s+FUNCTION\s+'LIST_FROM_MEMORY'/i.test(statement.text);
    if (statement.kind === "CallFunction" && !supportedSpecial) {
      addStatementDiagnostic(diagnostics, statement, "CALL FUNCTION is not supported by the generated report method", "Use a supported scaffold operation or provide a dedicated function-module adapter.", "GGCONV-E501");
      continue;
    }
    if (statement.kind === "Perform" && /\bPERFORM\s+\(|\bIN\s+PROGRAM\b/i.test(statement.text)) {
      addStatementDiagnostic(diagnostics, statement, "dynamic or external PERFORM cannot be lowered safely", "Convert the routine to a local FORM or provide a manual method mapping.", "GGCONV-E401");
      continue;
    }
    if (statement.kind === "Write" && /\b(COLOR|CURRENCY|UNIT|EXPONENT|EDIT\s+MASK|NO-GROUPING|SIGN\s+AS\s+POSTFIX)\b/i.test(statement.text)) {
      addStatementDiagnostic(diagnostics, statement, "this WRITE formatting addition is not represented by the scaffold writer", "Move the formatting to FORMAT or provide a typed writer extension.", "GGCONV-E501");
    }
    const dynamicWrite = dynamicWriteOperand(statement);
    if (dynamicWrite && (!dynamicWrite.supported || !hasDynamicWriteTargets(ir))) {
      addStatementDiagnostic(diagnostics, statement, "dynamic WRITE operand expressions cannot be resolved safely in the generated writer call", "Use a statically named variable containing the target name, or provide a manual field-symbol lowering with an explicit type and binding.", "GGCONV-E501");
    }
    if (statement.kind === "Program") {
      if (!ir.dynproMetadata) addStatementDiagnostic(diagnostics, statement, "module pools require explicit dynpro metadata", "Supply dynpro metadata and use the dynpro frontend.", "GGCONV-E502");
      interfaces.delete("zif_gg_report_v1");
      interfaces.add("zif_gg_dynpro_v1");
      continue;
    }
    if (ir.programKind === "module-pool" && ir.dynproMetadata && ["Module", "EndModule", "SetScreen", "LeaveScreen", "LeaveToScreen"].includes(statement.kind)) continue;
    if (!SUPPORTED_STATEMENTS.has(statement.kind) && !LOWERING_RULES.has(statement.kind) && !supportedSpecial) {
      addStatementDiagnostic(diagnostics, statement, `statement kind ${statement.kind} is not supported by this converter`, "Convert this statement manually or add a lowering rule.");
    }
    if (/\b(CALL SCREEN|CALL SELECTION-SCREEN|CALL TRANSACTION|SUBMIT\b.*\bAND RETURN)\b/.test(text)) {
      interfaces.add("zif_gg_resumable_v1");
      ir.features.push("continuation");
    }
    if (["AtLineSelection", "AtUserCommand", "AtPF", "TopOfPage", "EndOfPage", "Hide", "ReadLine", "ModifyLine", "GetCursor", "SetPFStatus", "SetTitlebar"].includes(statement.kind) || /LINE-SIZE|LINE-COUNT|NO STANDARD PAGE HEADING/.test(text)) {
      interfaces.add("zif_gg_list_processing_v1");
      ir.features.push("list-processing");
    }
    const localElementaryType = statement.kind === "Type" && /^TYPES\s+[A-Z][A-Z0-9_]*\s+TYPE\s+(C|N|I|P|D|T|X|STRING)\b/i.test(statement.text.trim());
    if (/\b(TYPE|TABLES)\b/.test(text) && ["Type", "Tables"].includes(statement.kind) && !localElementaryType && !statement.resolvedType) {
      addStatementDiagnostic(diagnostics, statement, `${statement.kind.toUpperCase()} declarations need DDIC-aware lowering`, "Provide a resolvable type and a dedicated declaration lowering rule.", "GGCONV-E301");
    }
    if (/\bMESSAGE\b/.test(text)) ir.features.push("messages");
    if (/\bPARAMETERS\b|\bSELECT-OPTIONS\b/.test(text)) ir.features.push("selection-screen");
    if (eventName(statement)) ir.features.push(`event:${eventName(statement)}`);
  }
  ir.interfaces = [...interfaces].sort();
  ir.features = [...new Set(ir.features)].sort();
  const diagnosticFor = (statement) => diagnostics.find((item) => item.filename === statement.filename && item.start.line === statement.span.start.line && item.start.column === statement.span.start.column);
  ir.capabilities = statements.map((statement) => {
    const issue = diagnosticFor(statement);
    let status = "supported";
    if (issue) status = issue.code.startsWith("GGCONV-E3") || issue.code.startsWith("GGCONV-E5") ? "scaffold-gap" : "manual";
    return {
      kind: statement.kind,
      construct: normalizedText(statement),
      filename: statement.filename,
      span: statement.span,
      status,
      loweringRule: LOWERING_RULES.get(statement.kind)?.kind,
      ...(METHOD_SAFE_STATEMENTS.has(statement.kind) || isMethodSafeLoop(statement) ? { methodSafe: true } : {}),
      ...(issue ? { diagnostic: issue.code } : {}),
    };
  });
  if (mode === "partial") {
    for (const item of diagnostics) {
      if (item.severity === "error") item.severity = "warning";
    }
  }
  return diagnostics;
}
