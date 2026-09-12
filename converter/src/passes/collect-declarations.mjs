const DECLARATION_KINDS = new Set([
  "Data", "DataBegin", "DataEnd", "Parameter", "SelectOption", "SelectionScreen", "Tables", "Ranges", "Type", "TypeBegin", "TypeEnd", "Constant", "Static", "FieldSymbol",
]);

function splitDeclarationParts(body) {
  const parts = [];
  let current = "";
  let quoted = false;
  let depth = 0;
  for (let index = 0; index < body.length; index++) {
    const char = body[index];
    if (char === "'" && quoted && body[index + 1] === "'") {
      current += "''";
      index++;
    } else if (char === "'") {
      quoted = !quoted;
      current += char;
    } else if (!quoted && char === "(") {
      depth++;
      current += char;
    } else if (!quoted && char === ")") {
      depth = Math.max(0, depth - 1);
      current += char;
    } else if (!quoted && depth === 0 && char === ",") {
      parts.push(current.trim());
      current = "";
    } else current += char;
  }
  if (current.trim()) parts.push(current.trim());
  return parts;
}

export function declarationEntries(raw, keyword) {
  const body = raw.replace(new RegExp(`^\\s*${keyword}\\s*:??\\s*`, "i"), "").replace(/\.$/, "");
  return splitDeclarationParts(body).map((part) => {
    const match = /^([A-Z][A-Z0-9_]*)\s*(.*)$/i.exec(part);
    return match ? { name: match[1].toUpperCase(), definition: match[2].trim() } : undefined;
  }).filter(Boolean);
}

function firstNames(raw, keyword) {
  return declarationEntries(raw, keyword).map((entry) => entry.name);
}

export function declarationInfo(statement) {
  const raw = statement.text.replace(/\s+/g, " ").trim();
  if (["Data", "Constant", "Static"].includes(statement.kind)) {
    const keyword = { Data: "DATA", Constant: "CONSTANTS", Static: "STATICS" }[statement.kind];
    return { kind: statement.kind === "Data" ? "data" : statement.kind === "Constant" ? "constant" : "static", names: firstNames(raw, keyword), entries: declarationEntries(raw, keyword), raw, complex: statement.kind === "Data" && /\bBEGIN\s+OF\b|\bEND\s+OF\b/i.test(raw) };
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
  if (statement.kind === "Ranges") {
    const match = /^RANGES\s+([A-Z][A-Z0-9_]*)\s+FOR\s+(.+)$/i.exec(raw.replace(/\.$/, ""));
    return { kind: "ranges", names: match?.[1] ? [match[1].toUpperCase()] : [], target: match?.[2]?.trim().toUpperCase(), raw };
  }
  if (statement.kind === "Type") {
    const match = /^TYPES\s+([A-Z][A-Z0-9_]*)/i.exec(raw);
    return { kind: "type", names: match?.[1] ? [match[1].toUpperCase()] : [], typeExpression: match?.[1] ? raw.replace(/^TYPES\s+[A-Z][A-Z0-9_]*\s*/i, "").replace(/\.$/, "").trim() : undefined, raw };
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
