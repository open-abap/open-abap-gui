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

// Every type a declaration references is assumed to exist in the target
// system, so declarations are emitted with the type name exactly as written.
// `ddicTypes` is optional field metadata: it types selection-screen elements
// declared FOR <table>-<field>, and never renames a type or gates conversion.
export function resolveTypes(ir, options) {
  const dictionary = metadataMap(options.ddicTypes ?? options.dictionaryTypes ?? options.dictionary);
  ir.resolvedTypes = {};
  const scalarTypes = new Map();
  for (const declaration of ir.declarations) {
    if (!['data', 'static'].includes(declaration.kind)) continue;
    for (const entry of declaration.entries ?? []) {
      const match = /\bTYPE\s+([A-Z0-9_\/]+)(?:\s+LENGTH\s+(\d+))?(?:\s+DECIMALS\s+(\d+))?/i.exec(entry.definition ?? '');
      if (!match) continue;
      scalarTypes.set(entry.name.toUpperCase(), {
        typ: (match[1] ?? 'STRING').toUpperCase(),
        ...(match[2] ? {length: Number(match[2])} : {}),
        ...(match[3] ? {decimals: Number(match[3])} : {}),
      });
    }
  }
  for (const declaration of ir.declarations) {
    if (declaration.kind === "tables") {
      const name = declaration.names?.[0];
      if (!name) continue;
      // TABLES <name> declares a work area of the dictionary type <name>.
      declaration.type = name.toLowerCase();
      declaration.fields = typeInfo(lookup(dictionary, name), name)?.fields ?? {};
      declaration.resolved = true;
      declaration.statement.resolvedType = true;
      if (lookup(dictionary, name)) ir.resolvedTypes[name] = typeInfo(lookup(dictionary, name), name);
      continue;
    }
    if (declaration.kind === "type") {
      const name = declaration.names?.[0]?.toUpperCase();
      declaration.resolved = true;
      declaration.statement.resolvedType = true;
      const expression = declaration.typeExpression ?? declaration.raw.replace(/^TYPES\s+[A-Z][A-Z0-9_]*\s*/i, "").replace(/\.$/, "").trim();
      const referencePattern = "[A-Z][A-Z0-9_\\/]*(?:=>[A-Z][A-Z0-9_]*)?";
      const reference = new RegExp(`^(?:TYPE\\s+)?(?:STANDARD|SORTED|HASHED)?\\s*TABLE\\s+OF\\s+(${referencePattern})`, "i").exec(expression)?.[1]
        ?? new RegExp(`^(?:TYPE\\s+)?RANGE\\s+OF\\s+(${referencePattern})`, "i").exec(expression)?.[1]
        ?? new RegExp(`^(?:TYPE\\s+)?REF\\s+TO\\s+(${referencePattern})`, "i").exec(expression)?.[1]
        ?? new RegExp(`^(?:TYPE\\s+)?(${referencePattern})`, "i").exec(expression)?.[1];
      if (name && reference && lookup(dictionary, reference)) ir.resolvedTypes[name] = typeInfo(lookup(dictionary, reference), reference);
    }
  }
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      const scalarMatch = /\bFOR\s+([A-Z][A-Z0-9_]*)\b/i.exec(item.additions ?? '');
      const scalarType = scalarTypes.get(scalarMatch?.[1]?.toUpperCase());
      if (scalarType) {
        item.dataType = scalarType;
        continue;
      }
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
