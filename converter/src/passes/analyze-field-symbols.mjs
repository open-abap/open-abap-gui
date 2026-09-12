const ELEMENTARY_TYPES = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "ABAP_BOOL"]);

function ownerStatements(ir, statement) {
  const event = ir.eventBlocks?.find((block) => block.statements?.includes(statement));
  if (event) return event.statements;
  const routine = ir.routines?.find((item) => item.statements?.includes(statement));
  if (routine) return routine.statements;
  return ir.localClasses?.flatMap((item) => item.methods ?? [])
    .find((method) => method.statements?.includes(statement))?.statements ?? [];
}

function staticType(raw) {
  const type = /\bTYPE\s+([A-Z][A-Z0-9_]*)\b/i.exec(raw)?.[1]?.toUpperCase();
  return type && ELEMENTARY_TYPES.has(type);
}

function staticallyAssigned(statements, name) {
  return statements.some((statement) => {
    const match = /^\s*ASSIGN\s+([A-Z][A-Z0-9_-]*)\s+TO\s+<([A-Z][A-Z0-9_]*)>\.?\s*$/i.exec(statement.text);
    return match?.[2]?.toUpperCase() === name && !/\b(CASTING|INCREMENTING|DECIMALS|RANGE|ELSEWHERE)\b/i.test(statement.text);
  });
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
  for (const declaration of ir.declarations ?? []) {
    for (const name of declaration.names ?? []) {
      if (declaration.kind !== "field-symbol" || !staticType(declaration.raw)) continue;
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
