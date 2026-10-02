import { ReferenceType } from "@abaplint/core/build/src/abap/5_syntax/_reference.js";

// A FORM may write a USING parameter passed by reference, and the caller sees
// the change. A method cannot write an IMPORTING parameter, so a USING
// parameter that its FORM writes becomes CHANGING. The writes come from the
// abaplint syntax check: every access it resolves to a FORM parameter is a
// read or a write reference.

// Statements that make an alias of a data object without writing it; writing
// through the field symbol or reference then writes the parameter.
const ALIASING = /^\s*(?:ASSIGN|GET\s+REFERENCE\s+OF)\b|\b(?:ASSIGNING|REFERENCE\s+INTO)\b|\bREF\s*[#A-Z0-9_]*\s*\(/i;

export function performArguments(text) {
  return [...String(text ?? "").matchAll(/'(?:''|[^'])*'|`(?:``|[^`])*`|[^\s,]+/g)].map((match) => match[0]);
}

// PERFORM passes data objects only, so an argument is a literal, a text
// symbol, a constant or a variable, possibly with offset and length.
export function isWritableArgument(argument, constants) {
  const head = /^<?([A-Z_][A-Z0-9_]*)>?/i.exec(argument)?.[1]?.toUpperCase();
  if (!head || /^TEXT-/i.test(argument)) return false;
  if (constants?.has(head)) return false;
  return /^(?:<[A-Z_][A-Z0-9_]*>|[A-Z_][A-Z0-9_]*)(?:(?:-|->|=>)[A-Z_][A-Z0-9_]*)*(?:\[\])?(?:\+\d+)?(?:\(\d+\))?$/i.test(argument);
}

function programConstants(ir) {
  const names = new Set();
  for (const statement of ir.statements ?? []) {
    if (statement.scope === "local" || statement.localClassName) continue;
    if (!["Constant", "ConstantBegin"].includes(statement.kind)) continue;
    if ((ir.routines ?? []).some((routine) => routine.statements?.includes(statement))) continue;
    const name = /^\s*CONSTANTS\s*:?\s*(?:BEGIN\s+OF\s+)?([A-Z_][A-Z0-9_]*)/i.exec(statement.text)?.[1];
    if (name) names.add(name.toUpperCase());
  }
  return names;
}

function formScopes(scope, result = new Map()) {
  for (const child of scope?.getChildren?.() ?? []) {
    const identifier = child.getIdentifier();
    if (identifier.stype === "form") result.set(identifier.sname.toUpperCase(), child);
    formScopes(child, result);
  }
  return result;
}

function contains(statement, position) {
  const row = position.getRow();
  const col = position.getCol();
  const { start, end } = statement.span;
  if (row < start.line || row > end.line) return false;
  if (row === start.line && col < start.column) return false;
  return !(row === end.line && col > end.column);
}

function writtenParameters(routine, scope) {
  const written = new Set();
  for (const reference of scope.getData().references) {
    const resolved = reference.resolved;
    if (!resolved?.getMeta?.().includes("form_parameter")) continue;
    const name = resolved.getName().toUpperCase();
    if (reference.referenceType === ReferenceType.DataWriteReference) {
      written.add(name);
      continue;
    }
    const filename = reference.position.getFilename();
    const start = reference.position.getStart();
    const statement = routine.statements.find((item) => item.filename === filename && contains(item, start));
    if (statement && ALIASING.test(statement.text)) written.add(name);
  }
  return written;
}

/**
 * Turns written by-reference USING parameters into CHANGING ones, marked
 * `written`, and lists the PERFORM arguments that cannot take a write. Without
 * a syntax check the directions stay as declared.
 */
export function analyzeRoutineWrites(ir, programScope) {
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
    const name = /^\s*PERFORM\s+([A-Z_][A-Z0-9_]*)/i.exec(statement.text)?.[1]?.toUpperCase();
    const routine = (ir.routines ?? []).find((item) => item.name === name);
    if (!routine || /\bIN\s+PROGRAM\b/i.test(statement.text)) continue;
    const using = [];
    let section;
    for (const token of performArguments(statement.text.replace(/^\s*PERFORM\s+\S+\s*/i, "").replace(/\.\s*$/, ""))) {
      if (/^(?:TABLES|USING|CHANGING)$/i.test(token)) section = token.toUpperCase();
      else if (section === "USING") using.push(token);
    }
    routine.parameters.filter((parameter) => parameter.section === "USING").forEach((parameter, index) => {
      if (parameter.written && using[index] !== undefined && !isWritableArgument(using[index], ir.constantNames)) {
        ir.readonlyPerformArguments.push({ statement, routine: routine.name, parameter: parameter.name, argument: using[index] });
      }
    });
  }
  return ir;
}
