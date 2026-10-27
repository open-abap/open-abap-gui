import { Expressions } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import { assignTarget, assigningTarget, bindsStatically, declaredFieldSymbols, fieldSymbolsIn } from "../abap/statements.js";
import { rebindingCall } from "./lower-statements.js";
import type { FieldSymbolReference, ReportIR, Statement } from "../types.js";

function ownerStatements(ir: ReportIR, statement: Statement): Statement[] {
  const event = ir.eventBlocks?.find((block) => block.statements?.includes(statement));
  if (event) return event.statements;
  const routine = ir.routines?.find((item) => item.statements?.includes(statement));
  if (routine) return routine.statements;
  return ir.localClasses?.flatMap((item) => item.methods ?? [])
    .find((method) => method.statements?.includes(statement))?.statements ?? [];
}

// The field symbol a statement binds, whether or not the binding converts:
// ASSIGN ... TO <fs>, or an ASSIGNING <fs> of LOOP, READ TABLE, APPEND, INSERT
// or COLLECT.
function bindsAtAll(statement: Statement, name: string): boolean {
  if (statement.kind === "Assign") return assignTarget(statement.text) === name;
  return assigningTarget(statement.text) === name;
}

function uses(statement: Statement, name: string): boolean {
  return fieldSymbolsIn(statement.text).includes(name);
}

function references(statements: Statement[], name: string): boolean {
  return statements.some((statement) => uses(statement, name));
}

// The owner binds the field symbol before anything else uses it, so the
// binding it had in another procedure is never seen.
function bindsFirst(statements: Statement[], name: string): boolean {
  const first = statements.find((statement) => uses(statement, name));
  return Boolean(first && bindsStatically(first.text, name));
}

// A FORM or method declaring a field symbol of its own name never sees the
// global one; an event block has no local declarations to hide it.
function hides(statements: Statement[], name: string): boolean {
  return declaredFieldSymbols(statements).includes(name);
}

function globalOwners(ir: ReportIR, name: string): Statement[][] {
  const procedures = [
    ...(ir.routines ?? []).map((routine) => routine.statements ?? []),
    ...(ir.localClasses ?? []).flatMap((item) => (item.methods ?? []).map((method) => method.statements ?? [])),
  ];
  const owners = [
    ...(ir.eventBlocks ?? []).map((block) => block.statements ?? []),
    ...procedures.filter((statements) => !hides(statements, name)),
  ];
  return owners.filter((statements) => references(statements, name));
}

// A field-symbol declaration is emitted into each generated method that uses
// it, so any type the original accepted is still valid there, generic ones
// such as `TYPE any`, `TYPE data` and `TYPE STANDARD TABLE` included. Only the
// obsolete untyped and STRUCTURE forms, which classes reject, are not.
function methodType(raw: string): boolean {
  const ast = statementAst(raw);
  return Boolean(ast && (ast.findDirect(Expressions.Type) ?? ast.findDirect(Expressions.TypeTable)) && !ast.hasPhrase("STRUCTURE"));
}

function classify(ir: ReportIR): { safe: Set<string>; persistent: Set<string> } {
  const safe = new Set<string>();
  const persistent = new Set<string>();
  for (const declaration of ir.declarations ?? []) {
    if (declaration.kind !== "field-symbol" || !methodType(declaration.raw)) continue;
    for (const declared of declaration.names ?? []) {
      const name = declared.toUpperCase();
      if (declaration.statement?.scope === "local") {
        if (ownerStatements(ir, declaration.statement).some((statement) => bindsStatically(statement.text, name))) safe.add(name);
        continue;
      }
      const owners = globalOwners(ir, name);
      // An unused global declaration has no binding to preserve and can be
      // omitted.
      if (!owners.length) {
        safe.add(name);
        continue;
      }
      // A used global field symbol is declared in each owning method. Where
      // every owner binds it before using it, that is all.
      if (owners.every((owner) => bindsFirst(owner, name))) {
        safe.add(name);
        continue;
      }
      // Otherwise an owner relies on a binding another procedure made, which
      // the class keeps in a data reference, see fieldSymbolReferences. Every
      // binding has to survive conversion for that: one through a dynamic
      // ASSIGN is omitted, and the uses relying on it would read the wrong
      // object.
      const statements = owners.flat();
      const dynamic = statements.some((statement) => bindsAtAll(statement, name) && !bindsStatically(statement.text, name));
      if (!dynamic && statements.some((statement) => bindsStatically(statement.text, name))) {
        safe.add(name);
        persistent.add(name);
      } else if (owners.every((owner) => owner.some((statement) => bindsStatically(statement.text, name)))) {
        safe.add(name);
      }
    }
  }
  return { safe, persistent };
}

export function analyzeFieldSymbols(ir: ReportIR): Set<string> {
  return classify(ir).safe;
}

function rebinds(statement: Statement, name: string): boolean {
  return bindsStatically(statement.text, name)
    || (statement.kind === "Unassign" && uses(statement, name));
}

// The FORMs whose call may bind or unassign the field symbol, themselves or
// through a FORM they perform, and whether a local-class method may.
function rebinders(ir: ReportIR, name: string): Omit<FieldSymbolReference, "member"> {
  const rebindsGlobal = (statements: Statement[]) => !hides(statements, name) && statements.some((statement) => rebinds(statement, name));
  const routines = new Set((ir.routines ?? [])
    .filter((routine) => rebindsGlobal(routine.statements ?? []))
    .map((routine) => routine.name.toUpperCase()));
  const methods = (ir.localClasses ?? []).flatMap((item) => item.methods ?? []);
  let reference = { routines: [...routines], methods: methods.some((method) => rebindsGlobal(method.statements ?? [])) };
  for (let grown = true; grown;) {
    grown = false;
    for (const routine of ir.routines ?? []) {
      if (routines.has(routine.name.toUpperCase()) || !(routine.statements ?? []).some((statement) => rebindingCall(statement, reference))) continue;
      routines.add(routine.name.toUpperCase());
      grown = true;
    }
    const methodsRebind = reference.methods || methods.some((method) => (method.statements ?? []).some((statement) => rebindingCall(statement, reference)));
    grown ||= methodsRebind !== reference.methods;
    reference = { routines: [...routines].sort(), methods: methodsRebind };
  }
  return reference;
}

// The binding of each global field symbol that is bound in one generated
// method and used in another, by field-symbol name: the class attribute
// keeping it, and the calls that may change it, see rebindingCall.
export function fieldSymbolReferences(ir: ReportIR, excluded: string[] = []): Record<string, FieldSymbolReference> {
  const names = [...classify(ir).persistent].filter((name) => !excluded.includes(name)).sort();
  return Object.fromEntries(names.map((name, index) => {
    const member = `mr_ggconv_${name.toLowerCase()}`;
    return [name, { member: member.length <= 30 ? member : `mr_ggconv_fs${index + 1}`, ...rebinders(ir, name) }];
  }));
}
