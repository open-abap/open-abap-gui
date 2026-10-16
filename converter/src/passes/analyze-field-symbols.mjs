import { assignTarget, bindsStatically, rebindingCall } from "./lower-statements.mjs";

function ownerStatements(ir, statement) {
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
function bindsAtAll(text, name) {
  if (/^\s*ASSIGN\b/i.test(text)) return assignTarget(text) === name;
  return /\bASSIGNING\s+<([A-Z][A-Z0-9_]*)>/i.exec(text)?.[1]?.toUpperCase() === name;
}

function references(statements, name) {
  return statements.some((statement) => new RegExp(`<${name}>`, "i").test(statement.text));
}

// The owner binds the field symbol before anything else uses it, so the
// binding it had in another procedure is never seen.
function bindsFirst(statements, name) {
  const first = statements.find((statement) => new RegExp(`<${name}>`, "i").test(statement.text));
  return Boolean(first && bindsStatically(first.text, name));
}

function globalOwners(ir, name) {
  const owners = [
    ...(ir.eventBlocks ?? []).map((block) => block.statements ?? []),
    ...(ir.routines ?? []).map((routine) => routine.statements ?? []),
    ...(ir.localClasses ?? []).flatMap((item) => (item.methods ?? []).map((method) => method.statements ?? [])),
  ];
  return owners.filter((statements) => references(statements, name));
}

// A field-symbol declaration is emitted into each generated method that uses
// it, so any type the original accepted is still valid there, generic ones
// such as `TYPE any`, `TYPE data` and `TYPE STANDARD TABLE` included. Only the
// obsolete untyped and STRUCTURE forms, which classes reject, are not.
function methodType(raw) {
  return /\b(?:TYPE|LIKE)\b/i.test(raw) && !/\bSTRUCTURE\b/i.test(raw);
}

function classify(ir) {
  const safe = new Set();
  const persistent = new Set();
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
      const dynamic = statements.some((statement) => bindsAtAll(statement.text, name) && !bindsStatically(statement.text, name));
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

export function analyzeFieldSymbols(ir) {
  return classify(ir).safe;
}

function rebinds(statement, name) {
  return bindsStatically(statement.text, name)
    || (statement.kind === "Unassign" && new RegExp(`<${name}>`, "i").test(statement.text));
}

// The FORMs whose call may bind or unassign the field symbol, themselves or
// through a FORM they perform, and whether a local-class method may.
function rebinders(ir, name) {
  const routines = new Set((ir.routines ?? [])
    .filter((routine) => (routine.statements ?? []).some((statement) => rebinds(statement, name)))
    .map((routine) => routine.name.toUpperCase()));
  const methods = (ir.localClasses ?? []).flatMap((item) => item.methods ?? []);
  let reference = { routines: [...routines], methods: methods.some((method) => (method.statements ?? []).some((statement) => rebinds(statement, name))) };
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
export function fieldSymbolReferences(ir, excluded = []) {
  const names = [...classify(ir).persistent].filter((name) => !excluded.includes(name)).sort();
  return Object.fromEntries(names.map((name, index) => {
    const member = `mr_ggconv_${name.toLowerCase()}`;
    return [name, { member: member.length <= 30 ? member : `mr_ggconv_fs${index + 1}`, ...rebinders(ir, name) }];
  }));
}
