const DECLARATION_KINDS = new Set([
  "Data", "DataBegin", "DataEnd", "Parameter", "SelectOption", "SelectionScreen", "Tables", "Type", "TypeBegin", "TypeEnd", "Constant", "Static", "FieldSymbol",
]);

function firstNames(raw, keyword) {
  const body = raw.replace(new RegExp(`^\\s*${keyword}\\s*:??\\s*`, "i"), "").replace(/\.$/, "");
  return body.split(",").map((part) => /^\s*([A-Z][A-Z0-9_]*)/i.exec(part)?.[1]?.toUpperCase()).filter(Boolean);
}

export function declarationInfo(statement) {
  const raw = statement.text.replace(/\s+/g, " ").trim();
  if (["Data", "Constant", "Static"].includes(statement.kind)) {
    const keyword = { Data: "DATA", Constant: "CONSTANTS", Static: "STATICS" }[statement.kind];
    return { kind: statement.kind === "Data" ? "data" : statement.kind === "Constant" ? "constant" : "static", names: firstNames(raw, keyword), raw, complex: statement.kind === "Data" && /\bBEGIN\s+OF\b|\bEND\s+OF\b/i.test(raw) };
  }
  if (statement.kind === "FieldSymbol") {
    const names = [...raw.matchAll(/<([A-Z][A-Z0-9_]*)>/gi)].map((match) => match[1].toUpperCase());
    return { kind: "field-symbol", names, raw };
  }
  if (statement.kind === "Parameter") {
    const match = /^PARAMETERS\s+([A-Z][A-Z0-9_]*)\s*(.*)$/i.exec(raw.replace(/\.$/, ""));
    return { kind: "parameter", name: match?.[1]?.toUpperCase(), raw, additions: match?.[2] ?? "" };
  }
  if (statement.kind === "SelectOption") {
    const match = /^SELECT-OPTIONS\s+([A-Z][A-Z0-9_]*)\s*(.*)$/i.exec(raw.replace(/\.$/, ""));
    return { kind: "select-option", name: match?.[1]?.toUpperCase(), raw, additions: match?.[2] ?? "" };
  }
  if (statement.kind === "Tables") {
    const match = /^TABLES\s+([A-Z][A-Z0-9_]*)/i.exec(raw);
    return { kind: "tables", names: match?.[1] ? [match[1].toUpperCase()] : [], raw };
  }
  if (statement.kind === "Type") {
    const match = /^TYPES\s+([A-Z][A-Z0-9_]*)/i.exec(raw);
    return { kind: "type", names: match?.[1] ? [match[1].toUpperCase()] : [], raw };
  }
  if (statement.kind === "TypeBegin") {
    const match = /^TYPES\s+BEGIN\s+OF\s+([A-Z][A-Z0-9_]*)/i.exec(raw);
    return { kind: "typebegin", names: match?.[1] ? [match[1].toUpperCase()] : [], raw, complex: true };
  }
  if (statement.kind === "TypeEnd") {
    const match = /^TYPES\s+END\s+OF\s+([A-Z][A-Z0-9_]*)/i.exec(raw);
    return { kind: "typeend", names: match?.[1] ? [match[1].toUpperCase()] : [], raw, complex: true };
  }
  return { kind: statement.kind.toLowerCase(), raw };
}

export function collectDeclarations(statements) {
  return statements.filter((statement) => DECLARATION_KINDS.has(statement.kind)).map((statement) => ({
    ...declarationInfo(statement),
    statement,
  }));
}
