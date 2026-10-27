import { Expressions } from "@abaplint/core";
import { referencedNames } from "../abap/statements.js";
import type { Metadata, ReportIR } from "../types.js";

const IGNORED = new Set([
  "ABAP_TRUE", "ABAP_FALSE", "AND", "OR", "NOT", "IS", "INITIAL", "TYPE", "VALUE", "DATA", "FIELD-SYMBOLS",
  "SCREEN", "SY", "UCOMM", "SUBRC", "INDEX", "NAME", "INTO", "FROM", "TO", "AT", "TABLE", "STANDARD",
  "WITH", "DEFAULT", "NO", "EXTENSION", "INTERVALS", "FOR", "PARAMETERS", "SELECT", "OPTIONS", "WRITE",
]);

function identifiers(names: string[]): string[] {
  return names.filter((name) => !IGNORED.has(name));
}

function declarationNames(ir: ReportIR): Set<string> {
  return new Set(ir.declarations.flatMap((declaration) => [
    ...(declaration.names ?? []),
    ...(declaration.name ? [declaration.name] : []),
  ]).map((name) => String(name).toUpperCase()));
}

export function analyzeReferences(ir: ReportIR): Metadata {
  const globals = declarationNames(ir);
  const selections = new Set(ir.selections.flatMap((screen) => screen.elements)
    .filter((item) => item.kind === "parameter" || item.kind === "select-option")
    .map((item) => item.name!.toUpperCase()));
  const statements = ir.statements.map((statement) => {
    const text = statement.text.trim();
    const assignment = statement.kind === "Move";
    const writes = assignment ? identifiers(referencedNames(text, (ast) => ast.findDirect(Expressions.Target))) : [];
    const reads = identifiers(assignment ? referencedNames(text, (ast) => ast.findDirect(Expressions.Source)) : referencedNames(text))
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
