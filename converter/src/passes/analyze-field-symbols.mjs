const ELEMENTARY_TYPES = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "ABAP_BOOL", "ANY"]);

function ownerStatements(ir, statement) {
  const event = ir.eventBlocks?.find((block) => block.statements?.includes(statement));
  if (event) return event.statements;
  const routine = ir.routines?.find((item) => item.statements?.includes(statement));
  return routine?.statements ?? [];
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

export function analyzeFieldSymbols(ir) {
  const safe = new Set();
  for (const declaration of ir.declarations ?? []) {
    if (declaration.kind !== "field-symbol" || declaration.statement?.scope !== "local" || !staticType(declaration.raw)) continue;
    const statements = ownerStatements(ir, declaration.statement);
    for (const name of declaration.names ?? []) {
      if (staticallyAssigned(statements, name)) safe.add(name.toUpperCase());
    }
  }
  return safe;
}

export function fieldSymbolName(statement) {
  return /<([A-Z][A-Z0-9_]*)>/i.exec(statement.text)?.[1]?.toUpperCase();
}

