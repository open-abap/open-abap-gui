const ELEMENTARY_TYPES = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "ABAP_BOOL"]);

function ownerStatements(ir, statement) {
  const event = ir.eventBlocks?.find((block) => block.statements?.includes(statement));
  if (event) return event.statements;
  const routine = ir.routines?.find((item) => item.statements?.includes(statement));
  if (routine) return routine.statements;
  return ir.localClasses?.flatMap((item) => item.methods ?? [])
    .find((method) => method.statements?.includes(statement))?.statements ?? [];
}

const UNSAFE_ASSIGN_ADDITIONS = /\b(CASTING|INCREMENTING|DECIMALS|RANGE|ELSEWHERE)\b/i;
const TABLE_DECLARATION_KINDS = new Set(["data", "static", "tables", "ranges"]);

function declaredTables(ir) {
  return new Set((ir.declarations ?? [])
    .filter((declaration) => TABLE_DECLARATION_KINDS.has(declaration.kind))
    .flatMap((declaration) => (declaration.names ?? []).map((name) => String(name).toUpperCase())));
}

// `TYPE <elementary>` is determined on its own. `TYPE|LIKE LINE OF <itab>` is
// too, provided the table is named statically and declared by the program
// itself: the row type is then whatever the emitted table declaration already
// says, so no shape has to be guessed.
function staticType(raw, tables) {
  const type = /\bTYPE\s+([A-Z][A-Z0-9_]*)\b/i.exec(raw)?.[1]?.toUpperCase();
  if (type && ELEMENTARY_TYPES.has(type)) return true;
  const row = /\b(?:TYPE|LIKE)\s+LINE\s+OF\s+([A-Z][A-Z0-9_]*)(?![A-Z0-9_(-])/i.exec(raw)?.[1]?.toUpperCase();
  return Boolean(row && tables.has(row));
}

// `LOOP AT itab ASSIGNING <fs>` and `READ TABLE itab ... ASSIGNING <fs>` bind
// the field symbol to a row of a statically named table, which is exactly as
// determined as the `ASSIGN x TO <fs>` form. Both are lowered and emitted, so
// both have to count as bindings or the emitted use loses its declaration.
function bindsStatically(text, name) {
  if (UNSAFE_ASSIGN_ADDITIONS.test(text)) return false;
  const assign = /^\s*ASSIGN\s+([A-Z][A-Z0-9_-]*)\s+TO\s+<([A-Z][A-Z0-9_]*)>\.?\s*$/i.exec(text);
  if (assign) return assign[2].toUpperCase() === name;
  if (!/^\s*(?:LOOP\s+AT|READ\s+TABLE)\s+[A-Z][A-Z0-9_]*\b/i.test(text)) return false;
  if (/^\s*LOOP\s+AT\s+SCREEN\b/i.test(text)) return false;
  const assigning = /\bASSIGNING\s+<([A-Z][A-Z0-9_]*)>/i.exec(text)?.[1]?.toUpperCase();
  return assigning === name;
}

function staticallyAssigned(statements, name) {
  return statements.some((statement) => bindsStatically(statement.text, name));
}

function references(statements, name) {
  return statements.some((statement) => new RegExp(`<${name}>`, "i").test(statement.text));
}

function globalOwners(ir, name) {
  const owners = [
    ...(ir.eventBlocks ?? []).map((block) => block.statements ?? []),
    ...(ir.routines ?? []).map((routine) => routine.statements ?? []),
    ...(ir.localClasses ?? []).flatMap((item) => (item.methods ?? []).map((method) => method.statements ?? [])),
  ];
  return owners.filter((statements) => references(statements, name));
}

export function analyzeFieldSymbols(ir) {
  const safe = new Set();
  const tables = declaredTables(ir);
  for (const declaration of ir.declarations ?? []) {
    for (const name of declaration.names ?? []) {
      if (declaration.kind !== "field-symbol" || !staticType(declaration.raw, tables)) continue;
      const owner = declaration.statement?.scope === "local"
        ? [ownerStatements(ir, declaration.statement)]
        : globalOwners(ir, name);
      // An unused global declaration has no binding to preserve and can be
      // omitted. A used global field symbol is localized into each owning
      // generated method, so every owner must establish a static binding.
      const unusedGlobal = declaration.statement?.scope !== "local" && owner.length === 0;
      const boundInOwners = owner.length > 0 && owner.every((statements) => staticallyAssigned(statements, name));
      if (unusedGlobal || boundInOwners) safe.add(name.toUpperCase());
    }
  }
  return safe;
}

export function fieldSymbolName(statement) {
  return /<([A-Z][A-Z0-9_]*)>/i.exec(statement.text)?.[1]?.toUpperCase();
}
