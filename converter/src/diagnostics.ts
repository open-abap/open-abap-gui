import type { Issue } from "@abaplint/core";
import type { Diagnostic, DiagnosticInput } from "./types.js";

export function diagnostic({
  code,
  severity = "error",
  filename = "program.prog.abap",
  start = { line: 1, column: 1 },
  end = start,
  construct,
  message,
  suggestion = "",
  phase,
  feature,
  category,
}: DiagnosticInput): Diagnostic {
  return {
    code,
    severity,
    filename,
    start: { line: start.line, column: start.column },
    end: { line: end.line, column: end.column },
    construct: construct ?? "source",
    message: message ?? construct ?? "conversion diagnostic",
    suggestion,
    phase: phase ?? "analysis",
    ...(category ? { category } : {}),
    ...(feature ? { feature } : {}),
  };
}

export function sortDiagnostics(diagnostics: readonly Diagnostic[]): Diagnostic[] {
  return [...diagnostics].sort((a, b) =>
    a.filename.localeCompare(b.filename) ||
    a.start.line - b.start.line ||
    a.start.column - b.start.column ||
    a.code.localeCompare(b.code),
  );
}

export function hasErrors(diagnostics: readonly Diagnostic[]): boolean {
  return diagnostics.some((item) => item.severity === "error");
}

export function diagnosticsToText(diagnostics: readonly Diagnostic[]): string {
  return sortDiagnostics(diagnostics).map((item) => {
    const location = `${item.filename}:${item.start.line}:${item.start.column}`;
    const suffix = item.suggestion ? ` Suggestion: ${item.suggestion}` : "";
    return `${location} ${item.code} ${item.severity}: ${item.message}${suffix}`;
  }).join("\n");
}

export function diagnosticsToJSON(diagnostics: readonly Diagnostic[]): string {
  return JSON.stringify(sortDiagnostics(diagnostics), null, 2);
}

export function parserIssueToDiagnostic(issue: Issue, filename: string): Diagnostic {
  const start = issue.getStart();
  const end = issue.getEnd();
  return diagnostic({
    code: "GGCONV-E201",
    filename,
    start: { line: start.getRow() + 1, column: start.getCol() + 1 },
    end: { line: end.getRow() + 1, column: end.getCol() + 1 },
    construct: "parser input",
    message: issue.getMessage(),
    suggestion: "Correct the ABAP syntax before converting the report.",
    phase: "parse",
  });
}
