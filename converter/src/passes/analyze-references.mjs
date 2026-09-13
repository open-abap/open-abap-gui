const IGNORED = new Set([
  "ABAP_TRUE", "ABAP_FALSE", "AND", "OR", "NOT", "IS", "INITIAL", "TYPE", "VALUE", "DATA", "FIELD-SYMBOLS",
  "SCREEN", "SY", "UCOMM", "SUBRC", "INDEX", "NAME", "INTO", "FROM", "TO", "AT", "TABLE", "STANDARD",
  "WITH", "DEFAULT", "NO", "EXTENSION", "INTERVALS", "FOR", "PARAMETERS", "SELECT", "OPTIONS", "WRITE",
]);

function identifiers(text) {
  const withoutStrings = text.replace(/'(?:''|[^'])*'/g, " ");
  return [...withoutStrings.matchAll(/\b[A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)?\b/gi)]
    .map((match) => match[0].toUpperCase())
    .filter((name) => !IGNORED.has(name) && !name.startsWith("TEXT-"));
}

function declarationNames(ir) {
  return new Set(ir.declarations.flatMap((declaration) => [
    ...(declaration.names ?? []),
    ...(declaration.name ? [declaration.name] : []),
  ]).map((name) => String(name).toUpperCase()));
}

export function analyzeReferences(ir) {
  const globals = declarationNames(ir);
  const selections = new Set(ir.selections.flatMap((screen) => screen.elements)
    .filter((item) => item.kind === "parameter" || item.kind === "select-option")
    .map((item) => item.name.toUpperCase()));
  const statements = ir.statements.map((statement) => {
    const text = statement.text.trim();
    const assignment = /^([A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)?)\s*=\s*([\s\S]+)$/i.exec(text.replace(/\.$/, ""));
    const writes = assignment ? identifiers(assignment[1]) : [];
    const reads = identifiers(assignment ? assignment[2] : text)
      .filter((name) => !writes.includes(name));
    return {
      filename: statement.filename,
      span: statement.span,
      kind: statement.kind,
      reads,
      writes,
    };
  });
  return {
    globals: [...globals].sort().map((name) => ({ name, reads: [], writes: [] })),
    selections: [...selections].sort().map((name) => ({ name, reads: [], writes: [] })),
    statements,
  };
}
