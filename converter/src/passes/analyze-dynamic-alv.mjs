// Detect the deliberately finite dynamic-ALV pattern supported by the
// converter.  The runtime cannot manufacture an anonymous ABAP structure in
// a generated class, but a field catalog made entirely from literals gives us
// enough information to emit the same row shape safely.

function fieldSymbols(source) {
  return [...String(source ?? "").matchAll(/\bFIELD-SYMBOLS\s+<([A-Z][A-Z0-9_]*)>\s+TYPE\s+([^\.]+)\./gi)]
    .map((match) => ({name: match[1].toUpperCase(), type: match[2].trim().toUpperCase()}));
}

function catalogEntries(source) {
  const assignment = /\bGT_FIELDCAT\s*=\s*VALUE\s*#\(([^]*?)\)\s*\./i.exec(String(source ?? ""));
  if (!assignment) return [];
  return [...assignment[1].matchAll(/\(\s*FIELDNAME\s*=\s*'([^']+)'([^]*?)\)/gi)]
    .map((match) => {
      const body = match[2];
      const name = match[1].toUpperCase();
      const intType = /\bINTTYPE\s*=\s*'([^']+)'/i.exec(body)?.[1]?.toUpperCase() ?? "C";
      const length = Number(/\bINTLEN\s*=\s*(\d+)/i.exec(body)?.[1] ?? 1);
      const decimals = Number(/\bDECIMALS\s*=\s*(\d+)/i.exec(body)?.[1] ?? 0);
      const outputLength = Number(/\bOUTPUTLEN\s*=\s*(\d+)/i.exec(body)?.[1] ?? length);
      return {
        name,
        intType,
        length: Number.isFinite(length) && length > 0 ? length : 1,
        decimals: Number.isFinite(decimals) && decimals >= 0 ? decimals : 0,
        outputLength: Number.isFinite(outputLength) && outputLength > 0 ? outputLength : length,
        checkbox: /\bCHECKBOX\s*=\s*ABAP_TRUE\b/i.test(body),
        editable: /\bEDIT\s*=\s*ABAP_TRUE\b/i.test(body),
        total: /\bDO_SUM\s*=\s*ABAP_TRUE\b/i.test(body),
        title: /\bCOLTEXT\s*=\s*'([^']*)'/i.exec(body)?.[1] ?? name,
        currencyField: /\bCFIELDNAME\s*=\s*'([^']+)'/i.exec(body)?.[1]?.toUpperCase() ?? "",
      };
    });
}

function abapType(entry) {
  switch (entry.intType) {
    case "I": return "i";
    case "P": return `p LENGTH ${entry.length} DECIMALS ${entry.decimals}`;
    case "D": return "d";
    case "T": return "t";
    case "F": return "f";
    case "STRING": return "string";
    default: return `c LENGTH ${entry.length}`;
  }
}

function declaredName(source, pattern, fallback) {
  return String(source ?? "").match(pattern)?.[1]?.toUpperCase() ?? fallback;
}

export function detectDynamicAlv(ir) {
  const source = ir?.source?.source ?? "";
  if (!/CL_ALV_TABLE_CREATE\s*=>\s*CREATE_DYNAMIC_TABLE/i.test(source)) return undefined;
  const table = fieldSymbols(source).find((item) => /^(?:STANDARD\s+)?TABLE\b/i.test(item.type));
  const entries = catalogEntries(source);
  if (!table || entries.length === 0) return undefined;

  const symbols = fieldSymbols(source).map((item) => item.name);
  const styleComponent = /\bCONSTANTS\s+([A-Z][A-Z0-9_]*)\s+TYPE\s+LVC_FNAME\s+VALUE\s+'([^']+)'/i.exec(source);
  const row = /\bAPPEND\s+INITIAL\s+LINE\s+TO\s+<([A-Z][A-Z0-9_]*)>\s+ASSIGNING\s+<([A-Z][A-Z0-9_]*)>/i.exec(source)?.[2]?.toUpperCase() ?? "LS_ROW";
  const component = /\bASSIGN\s+COMPONENT\s+'ID'\s+OF\s+STRUCTURE\s+<[^>]+>\s+TO\s+<([A-Z][A-Z0-9_]*)>/i.exec(source)?.[1]?.toUpperCase() ?? "LV_COMPONENT";
  const styleTable = /\bASSIGN\s+COMPONENT\s+'CELLSTYLES'\s+OF\s+STRUCTURE\s+[^\s]+\s+TO\s+<([A-Z][A-Z0-9_]*)>/i.exec(source)?.[1]?.toUpperCase() ?? "LT_STYLES";
  const styleRow = /\bAPPEND\s+INITIAL\s+LINE\s+TO\s+<[^>]+>\s+ASSIGNING\s+<([A-Z][A-Z0-9_]*)>/gi.exec(source)?.[1]?.toUpperCase() ?? "LS_STYLE";
  const styleValue = /\bASSIGN\s+COMPONENT\s+'STYLE'\s+OF\s+STRUCTURE\s+<[^>]+>\s+TO\s+<([A-Z][A-Z0-9_]*)>/i.exec(source)?.[1]?.toUpperCase() ?? "LV_STYLE";
  const reference = /\bDATA\s+([A-Z][A-Z0-9_]*)\s+TYPE\s+REF\s+TO\s+DATA\b/i.exec(source)?.[1]?.toUpperCase() ?? "GR_TABLE";
  const styleField = styleComponent?.[2]?.toUpperCase() ?? "CELLSTYLES";

  return {
    rowType: "ty_dynamic_alv_row",
    tableType: "ty_dynamic_alv_rows",
    tableMember: table.name,
    tableSymbol: table.name,
    referenceMember: reference,
    styleMember: /\bDATA\s+([A-Z][A-Z0-9_]*)\s+TYPE\s+LVC_FNAME\b/i.exec(source)?.[1]?.toUpperCase() ?? "GV_STYLE_FIELD",
    styleComponent: styleField,
    rowSymbol: row,
    componentSymbol: component,
    styleTableSymbol: styleTable,
    styleRowSymbol: styleRow,
    styleValueSymbol: styleValue,
    fieldSymbols: [...new Set(symbols)],
    fields: entries,
    typeFields: [
      ...entries.map((entry) => ({name: entry.name, type: abapType(entry)})),
      {name: styleField, type: "lvc_t_styl"},
    ],
  };
}
