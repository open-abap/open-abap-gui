import { diagnostic } from "../diagnostics.mjs";

const ELEMENTARY = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "ABAP_BOOL"]);

function metadataMap(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return Object.fromEntries(Object.entries(value).map(([name, item]) => [name.toUpperCase(), item]));
}

function typeInfo(value, fallback) {
  if (typeof value === "string" && value.trim()) return { type: value.trim().toLowerCase(), fields: {} };
  if (!value || typeof value !== "object") return undefined;
  const type = value.type ?? value.abapType ?? value.name ?? fallback;
  if (!type) return undefined;
  return { ...value, type: String(type).toLowerCase(), fields: metadataMap(value.fields ?? value.components) };
}

function lookup(map, name) {
  return map[String(name ?? "").toUpperCase()];
}

function typeDiagnostic(statement, construct, message, suggestion) {
  return diagnostic({
    code: "GGCONV-E301",
    filename: statement.filename,
    start: statement.span.start,
    end: statement.span.end,
    construct,
    message,
    suggestion,
    phase: "types",
  });
}

export function resolveTypes(ir, options, diagnostics) {
  const dictionary = metadataMap(options.ddicTypes ?? options.dictionaryTypes ?? options.dictionary);
  ir.resolvedTypes = {};
  for (const declaration of ir.declarations) {
    if (declaration.kind === "tables") {
      const name = declaration.names?.[0];
      const info = typeInfo(lookup(dictionary, name), name);
      if (!info || !lookup(dictionary, name)) {
        diagnostics.push(typeDiagnostic(declaration.statement, name ?? declaration.raw, `DDIC table type for ${name ?? "TABLES"} was not supplied`, "Pass ddicTypes with the table type and fields, or convert this declaration manually."));
        continue;
      }
      declaration.type = info.type;
      declaration.fields = info.fields;
      declaration.resolved = true;
      declaration.statement.resolvedType = true;
      ir.resolvedTypes[name] = info;
      continue;
    }
    if (declaration.kind === "type") {
      const match = /^TYPES\s+([A-Z][A-Z0-9_]*)\s+TYPE\s+([A-Z0-9_\/]+)/i.exec(declaration.raw);
      if (!match) continue;
      const typeName = match[2].toUpperCase();
      if (ELEMENTARY.has(typeName) || lookup(dictionary, typeName)) {
        declaration.resolved = true;
        declaration.statement.resolvedType = true;
        if (lookup(dictionary, typeName)) ir.resolvedTypes[match[1].toUpperCase()] = typeInfo(lookup(dictionary, typeName), typeName);
      } else {
        diagnostics.push(typeDiagnostic(declaration.statement, typeName, `DDIC type ${typeName} was not supplied`, "Pass ddicTypes for the referenced type or rewrite the local type declaration."));
      }
    }
  }
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      const match = /\bFOR\s+([A-Z][A-Z0-9_]*)-([A-Z][A-Z0-9_]*)/i.exec(item.additions ?? "");
      if (!match) continue;
      const table = lookup(ir.resolvedTypes, match[1]) ?? lookup(dictionary, match[1]);
      const field = table?.fields ? lookup(table.fields, match[2]) : undefined;
      const info = typeInfo(field);
      if (info?.type) {
        item.dataType = {
          typ: info.type.toUpperCase(),
          ...(info.length ? { length: Number(info.length) } : {}),
          ...(info.decimals ? { decimals: Number(info.decimals) } : {}),
        };
      }
    }
  }
  return ir;
}
