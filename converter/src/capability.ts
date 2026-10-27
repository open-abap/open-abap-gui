import { diagnostic } from "./diagnostics.js";
import { eventName, normalizedText } from "./passes/classify-program.js";
import { isLocalClassStructural } from "./passes/collect-local-classes.js";
import { LOWERING_RULES, classicWriteFormatSupported, dynamicWriteOperand, isMethodSafeLoop, isStaticAssign, writeToTarget } from "./passes/lower-statements.js";
import { isAmbiguousScreenRoutine } from "./passes/screen-states.js";
import { Expressions } from "@abaplint/core";
import { leadingWords, statementAst } from "./abap/ast.js";
import { fieldSymbolsIn, performedForm } from "./abap/statements.js";
import type { Diagnostic, ReportIR, Statement } from "./types.js";
import { LOOP_BLOCKS } from "./passes/blocks.js";
import { isSuspendingStatement } from "./passes/lower-continuations.js";
import { headerLinesOf } from "./passes/header-lines.js";

export const ACTIONABLE_DIAGNOSTIC_CODES = Object.freeze({
  dynamicType: "GGCONV-E515",
  unsupportedStatement: "GGCONV-E516",
});

const ACTIONABLE_CATEGORIES = Object.freeze(Object.fromEntries(
  Object.entries(ACTIONABLE_DIAGNOSTIC_CODES).map(([category, code]) => [code, category]),
));

function actionableDiagnosticCode(statement: Statement): string {
  if (statement.kind === "FieldSymbol" || statement.kind === "Assign") return ACTIONABLE_DIAGNOSTIC_CODES.dynamicType;
  return ACTIONABLE_DIAGNOSTIC_CODES.unsupportedStatement;
}

function addStatementDiagnostic(diagnostics: Diagnostic[], statement: Statement, message: string, suggestion: string, code = "GGCONV-E501"): void {
  const resolvedCode = code === "GGCONV-E501" ? actionableDiagnosticCode(statement) : code;
  diagnostics.push(diagnostic({
    code: resolvedCode,
    severity: resolvedCode.startsWith("GGCONV-W") ? "warning" : "error",
    filename: statement.filename,
    start: statement.span.start,
    end: statement.span.end,
    construct: normalizedText(statement),
    message,
    suggestion,
    phase: "capability",
    category: (ACTIONABLE_CATEGORIES as Record<string, string>)[resolvedCode],
  }));
}

// The table a LOOP AT names first, itab of LOOP AT itab-sub.
function loopName(statement: Statement): string | undefined {
  const ast = statementAst(statement.text);
  const source = ast?.findDirect(Expressions.LoopSource);
  return source && ast ? ast.tokens().find((entry) => entry.start === ast.start(source))?.token.getUpperStr() : undefined;
}

// The keywords of a statement, also of one abaplint cannot classify.
function wordsOf(statement: Statement): string {
  return statementAst(statement.text)?.words() ?? leadingWords(statement.text);
}

function hasDynamicWriteTargets(ir: ReportIR): boolean {
  if ((ir.declarations ?? []).some((declaration) => declaration.statement?.scope !== "local" && ["data", "static", "tables"].includes(declaration.kind) && (declaration.names ?? []).length)) return true;
  return (ir.selections ?? []).some((screen) => (screen.elements ?? []).some((element) => element.name));
}


export function scanCapabilities(ir: ReportIR, statements: Statement[], { mode = "strict" } = {}): Diagnostic[] {
  const diagnostics: Diagnostic[] = [];
  const interfaces = new Set(ir.interfaces);
  for (const continuation of ir.continuations ?? []) {
    // A continuation resumes the rest of an IF, CASE or TRY body, but not the
    // remaining iterations of a loop around the suspension.
    const unsafeContext = (continuation.controlStack ?? []).find((item) => LOOP_BLOCKS.has(item.kind));
    if (unsafeContext) {
      const statement = statements.find((item) => item.filename === continuation.filename && item.span.start.line === continuation.span.start.line && item.span.start.column === continuation.span.start.column);
      if (statement) addStatementDiagnostic(diagnostics, statement, `suspending navigation inside ${unsafeContext.kind.toUpperCase()} resumes after the loop; its remaining iterations do not run`, "Move the suspension out of the loop or provide an explicit continuation mapping.", "GGCONV-W402");
    }
  }
  for (const item of ir.readonlyPerformArguments ?? []) {
    addStatementDiagnostic(diagnostics, item.statement, `FORM ${item.routine} writes USING parameter ${item.parameter.toUpperCase()}, which becomes CHANGING; the argument ${item.argument} is not a variable, so the call passes a temporary and the FORM's write to it is discarded`, "Pass a variable if the caller needs the value; in ABAP, writing a literal or constant through USING fails at runtime.", "GGCONV-W111");
  }
  for (const duplicate of ir.duplicateEvents ?? []) {
    addStatementDiagnostic(diagnostics, duplicate.statement, `duplicate singleton event ${duplicate.event} is ambiguous after conversion`, "Merge the event blocks into one ordered handler or provide an explicit event mapping.", "GGCONV-E203");
  }
  for (const routine of ir.routines ?? []) {
    if (!isAmbiguousScreenRoutine(ir, routine)) continue;
    for (const statement of routine.statements.filter((item) => item.kind === "LoopAtScreen")) {
      addStatementDiagnostic(diagnostics, statement, `LOOP AT SCREEN in FORM ${routine.name}, which is performed for both selection screens and dynpros, can only run over one kind of screen state`, "Split the FORM into one for the selection screen and one for the dynpro.", "GGCONV-E501");
    }
  }
  for (const statement of statements) {
    if (isLocalClassStructural(statement)) continue;
    if (statement.kind === "FieldSymbol") {
      if (ir.safeFieldSymbols?.includes(fieldSymbolsIn(statement.text)[0])) continue;
      addStatementDiagnostic(diagnostics, statement, "field-symbol declarations require method-local binding analysis", "Move the field symbol into a generated method or provide an explicit field-symbol lowering rule.", "GGCONV-E501");
      continue;
    }
    if (statement.kind === "Assign" && !isStaticAssign(statement.text)) {
      addStatementDiagnostic(diagnostics, statement, "dynamic ASSIGN names its source at runtime, which the converted class cannot resolve", "Name the source statically, or convert the ASSIGN manually.", "GGCONV-E501");
      continue;
    }
    // A header-line table's loop is given its work area, see header-lines.ts.
    if (statement.kind === "Loop" && !isMethodSafeLoop(statement)
      && !headerLinesOf(ir, statement)[loopName(statement) ?? ""]) {
      addStatementDiagnostic(diagnostics, statement, "implicit-header-table LOOP cannot be lowered safely into a method", "Add an explicit INTO or ASSIGNING target, or provide a dedicated method-scope loop lowering rule.", "GGCONV-E501");
    }
    if (statement.kind === "Perform" && statementAst(statement.text)?.findDirect(Expressions.Dynamic)) {
      addStatementDiagnostic(diagnostics, statement, "dynamic PERFORM names a FORM that became a method", "Call the generated method directly or provide a manual method mapping.", "GGCONV-E401");
      continue;
    }
    const performed = statement.kind === "Perform" ? performedForm(statement.text) : undefined;
    if (performed && !(ir.routines ?? []).some((routine) => routine.name === performed)) {
      addStatementDiagnostic(diagnostics, statement, `PERFORM ${performed.toLowerCase()} names a FORM the program does not define`, "Include the source that defines the FORM, or call the FORM of another program with IN PROGRAM.", ACTIONABLE_DIAGNOSTIC_CODES.unsupportedStatement);
      continue;
    }
    const writeTo = writeToTarget(statement);
    if (writeTo && !writeTo.supported) {
      addStatementDiagnostic(diagnostics, statement, writeTo.dynamic
        ? "WRITE (name) TO names its source at runtime, which the converted class cannot resolve"
        : "WRITE ... TO itab INDEX is obsolete and has no class equivalent", "Name the source statically, or write to a variable and MODIFY the table line.", ACTIONABLE_DIAGNOSTIC_CODES.unsupportedStatement);
    }
    if (statement.kind === "Write" && !writeTo && !classicWriteFormatSupported(statement.text)) {
      addStatementDiagnostic(diagnostics, statement, "this WRITE formatting addition is not represented by the scaffold writer", "Move the formatting to FORMAT or provide a typed writer extension.", "GGCONV-E501");
    }
    if (statement.kind === "CallTransaction" && statementAst(statement.text)?.hasPhrase("USING")) {
      addStatementDiagnostic(diagnostics, statement, "CALL TRANSACTION ... USING replays batch-input screens, which the host cannot drive", "Pass the values the called transaction reads through SET PARAMETER ID with AND SKIP FIRST SCREEN, or convert the call manually.", ACTIONABLE_DIAGNOSTIC_CODES.unsupportedStatement);
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
    const hasDynproFrontend = ir.programKind === "module-pool" && ir.dynproMetadata
      || ir.programKind === "report" && ir.screenMetadata;
    if (hasDynproFrontend && ["Module", "EndModule", "SetScreen", "LeaveScreen", "LeaveToScreen"].includes(statement.kind)) continue;
    if (isSuspendingStatement(statement)) {
      interfaces.add("zif_gg_resumable_v1");
      ir.features.push("continuation");
    }
    // WRITE ... TO writes no list.
    const words = wordsOf(statement);
    if ((statement.kind === "Write" && !writeTo) || ["AtLineSelection", "AtUserCommand", "AtPF", "TopOfPage", "EndOfPage", "Hide", "ReadLine", "ModifyLine", "GetCursor", "SetPFStatus", "SetTitlebar"].includes(statement.kind) || /LINE-SIZE|LINE-COUNT|NO STANDARD PAGE HEADING/.test(words)) {
      interfaces.add("zif_gg_list_processing_v1");
      ir.features.push("list-processing");
    }
    if (statement.kind === "Message" || /(?:^| )MESSAGE(?:-| |$)/.test(words)) ir.features.push("messages");
    if (statement.kind === "Parameter" || statement.kind === "SelectOption") ir.features.push("selection-screen");
    if (eventName(statement)) ir.features.push(`event:${eventName(statement)}`);
  }
  ir.interfaces = [...interfaces].sort();
  ir.features = [...new Set(ir.features)].sort();
  const diagnosticFor = (statement: Statement) => diagnostics.find((item) => item.filename === statement.filename && item.start.line === statement.span.start.line && item.start.column === statement.span.start.column);
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
