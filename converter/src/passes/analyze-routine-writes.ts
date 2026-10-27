import { Expressions, Nodes, ReferenceType, Statements, TypedIdentifier } from "@abaplint/core";
import type { Position } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import { isWritableArgument, performArguments, performedForm } from "../abap/statements.js";
import type { ProgramScopeGetter } from "./program-scope.js";
import type { ReportIR, Routine, Statement } from "../types.js";

// A FORM may write a USING parameter passed by reference, and the caller sees
// the change. A method cannot write an IMPORTING parameter, so a USING
// parameter that its FORM writes becomes CHANGING. The writes come from the
// abaplint syntax check: every access it resolves to a FORM parameter is a
// read or a write reference.

// Statements that make an alias of a data object without writing it; writing
// through the field symbol or reference then writes the parameter: ASSIGN,
// GET REFERENCE OF, ... ASSIGNING, ... REFERENCE INTO and REF #( ).
function isAliasing(text: string): boolean {
  const ast = statementAst(text);
  if (!ast) return false;
  if (ast.is(Statements.Assign) || ast.is(Statements.GetReference)) return true;
  const tokens = ast.tokens().filter((entry) => !(entry.node instanceof Nodes.TokenNodeRegex));
  return tokens.some((entry, index) => {
    const word = entry.token.getUpperStr();
    return word === "ASSIGNING" || (word === "REFERENCE" && tokens[index + 1]?.token.getUpperStr() === "INTO")
      || (word === "REF" && entry.parent.get() instanceof Expressions.Source);
  });
}

export { isWritableArgument };

function programConstants(ir: ReportIR): Set<string> {
  const names = new Set<string>();
  for (const statement of ir.statements ?? []) {
    if (statement.scope === "local" || statement.localClassName) continue;
    if (!["Constant", "ConstantBegin"].includes(statement.kind)) continue;
    if ((ir.routines ?? []).some((routine) => routine.statements?.includes(statement))) continue;
    const name = statementAst(statement.text)?.sourceOf(Expressions.DefinitionName);
    if (name) names.add(name.toUpperCase());
  }
  return names;
}

function formScopes(scope: NonNullable<ReturnType<ProgramScopeGetter>>["scope"] | undefined, result = new Map<string, NonNullable<ReturnType<ProgramScopeGetter>>["scope"]>()) {
  for (const child of scope?.getChildren?.() ?? []) {
    const identifier = child.getIdentifier();
    if (identifier.stype === "form") result.set(identifier.sname.toUpperCase(), child);
    formScopes(child, result);
  }
  return result;
}

function contains(statement: Statement, position: Position): boolean {
  const row = position.getRow();
  const col = position.getCol();
  const { start, end } = statement.span;
  if (row < start.line || row > end.line) return false;
  if (row === start.line && col < start.column) return false;
  return !(row === end.line && col > end.column);
}

function writtenParameters(routine: Routine, scope: NonNullable<ReturnType<ProgramScopeGetter>>["scope"]): Set<string> {
  const written = new Set<string>();
  for (const reference of scope.getData().references) {
    const resolved = reference.resolved;
    if (!(resolved instanceof TypedIdentifier) || !resolved.getMeta().includes("form_parameter" as never)) continue;
    const name = resolved.getName().toUpperCase();
    if (reference.referenceType === ReferenceType.DataWriteReference) {
      written.add(name);
      continue;
    }
    const filename = reference.position.getFilename();
    const start = reference.position.getStart();
    const statement = routine.statements.find((item) => item.filename === filename && contains(item, start));
    if (statement && isAliasing(statement.text)) written.add(name);
  }
  return written;
}

/**
 * Turns written by-reference USING parameters into CHANGING ones, marked
 * `written`, and lists the PERFORM arguments that cannot take a write. Without
 * a syntax check the directions stay as declared.
 */
export function analyzeRoutineWrites(ir: ReportIR, programScope: ProgramScopeGetter): ReportIR {
  ir.constantNames = programConstants(ir);
  const forms = formScopes(programScope()?.scope);
  for (const routine of ir.routines ?? []) {
    const scope = forms.get(routine.name.toUpperCase());
    if (!scope) continue;
    const written = writtenParameters(routine, scope);
    for (const parameter of routine.parameters ?? []) {
      if (parameter.section !== "USING" || parameter.byValue || !written.has(parameter.name.toUpperCase())) continue;
      parameter.direction = "CHANGING";
      parameter.written = true;
    }
  }
  ir.readonlyPerformArguments = [];
  for (const statement of ir.statements ?? []) {
    if (statement.kind !== "Perform") continue;
    const name = performedForm(statement.text);
    const routine = (ir.routines ?? []).find((item) => item.name === name);
    if (!routine) continue;
    const using = performArguments(statement.text).USING;
    (routine.parameters ?? []).filter((parameter) => parameter.section === "USING").forEach((parameter, index) => {
      if (parameter.written && using[index] !== undefined && !isWritableArgument(using[index], ir.constantNames)) {
        ir.readonlyPerformArguments!.push({ statement, routine: routine.name, parameter: parameter.name, argument: using[index] });
      }
    });
  }
  return ir;
}
