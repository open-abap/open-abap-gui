const SEVERITY_ORDER = { error: 0, warning: 1, info: 2 };

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
}) {
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

export function sortDiagnostics(diagnostics) {
  return [...diagnostics].sort((a, b) =>
    a.filename.localeCompare(b.filename) ||
    a.start.line - b.start.line ||
    a.start.column - b.start.column ||
    a.code.localeCompare(b.code),
  );
}

export function hasErrors(diagnostics) {
  return diagnostics.some((item) => item.severity === "error");
}

export function diagnosticsToText(diagnostics) {
  return sortDiagnostics(diagnostics).map((item) => {
    const location = `${item.filename}:${item.start.line}:${item.start.column}`;
    const suffix = item.suggestion ? ` Suggestion: ${item.suggestion}` : "";
    return `${location} ${item.code} ${item.severity}: ${item.message}${suffix}`;
  }).join("\n");
}

export function diagnosticsToJSON(diagnostics) {
  return JSON.stringify(sortDiagnostics(diagnostics), null, 2);
}

export function parserIssueToDiagnostic(issue, filename) {
  const position = issue.getPosition?.() ?? issue.getStart?.() ?? { row: 1, col: 1 };
  const end = issue.getEnd?.() ?? position;
  return diagnostic({
    code: "GGCONV-E201",
    filename,
    start: { line: (position.row ?? 0) + 1, column: (position.col ?? 0) + 1 },
    end: { line: (end.row ?? position.row ?? 0) + 1, column: (end.col ?? position.col ?? 0) + 1 },
    construct: "parser input",
    message: issue.getMessage?.() ?? issue.message ?? String(issue),
    suggestion: "Correct the ABAP syntax before converting the report.",
    phase: "parse",
  });
}
