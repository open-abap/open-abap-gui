// A program's text symbols (TEXT-nnn, 'text'(nnn)) move with its code into
// the class. A class has its own text pool; abapGit keeps it in the
// class's .clas.xml, where the transpiler and abaplint read it.

const escape = (value) => String(value)
  .replaceAll("&", "&amp;")
  .replaceAll("<", "&lt;")
  .replaceAll(">", "&gt;");

// The keys of the text symbols the generated source uses.
function usedTextSymbols(source) {
  const keys = new Set();
  const masked = source.replace(/^\*.*$/gm, "").replace(/"[^\n]*/g, "");
  for (const match of masked.matchAll(/\bTEXT-([A-Z0-9]{3})\b/gi)) keys.add(match[1].toUpperCase());
  for (const match of masked.matchAll(/'(?:''|[^'\n])*'\(([A-Z0-9]{3})\)/gi)) keys.add(match[1].toUpperCase());
  return keys;
}

/**
 * The abapGit .clas.xml of a generated class that uses text symbols, or
 * undefined when it uses none. withUnitTests marks a class with a test include.
 */
export function emitClassXml(ir, classSource, { withUnitTests = false } = {}) {
  const keys = usedTextSymbols(classSource);
  if (keys.size === 0) return undefined;
  const entries = ir.screenMetadata?.textPoolEntries ?? ir.dynproMetadata?.textPoolEntries ?? [];
  const symbols = new Map();
  for (const entry of entries) {
    const key = String(entry.key ?? "").toUpperCase();
    if (String(entry.id ?? "").toUpperCase() === "I" && keys.has(key) && !symbols.has(key) && entry.entry) {
      symbols.set(key, entry);
    }
  }
  const items = [...symbols.keys()].sort().map((key) => {
    const entry = symbols.get(key);
    const length = entry.length ?? [...String(entry.entry)].length;
    return [
      "    <item>",
      "     <ID>I</ID>",
      `     <KEY>${key}</KEY>`,
      `     <ENTRY>${escape(entry.entry)}</ENTRY>`,
      `     <LENGTH>${length}</LENGTH>`,
      "    </item>",
    ].join("\n");
  });
  return [
    '<?xml version="1.0" encoding="utf-8"?>',
    '<abapGit version="v1.0.0" serializer="LCL_OBJECT_CLAS" serializer_version="v1.0.0">',
    ' <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">',
    "  <asx:values>",
    "   <VSEOCLASS>",
    `    <CLSNAME>${escape(String(ir.targetClassName).toUpperCase())}</CLSNAME>`,
    "    <LANGU>E</LANGU>",
    `    <DESCRIPT>${escape(String(ir.description ?? "").slice(0, 60))}</DESCRIPT>`,
    "    <STATE>1</STATE>",
    "    <CLSCCINCL>X</CLSCCINCL>",
    "    <FIXPT>X</FIXPT>",
    "    <UNICODE>X</UNICODE>",
    ...(withUnitTests ? ["    <WITH_UNIT_TESTS>X</WITH_UNIT_TESTS>"] : []),
    "   </VSEOCLASS>",
    ...(items.length ? ["   <TPOOL>", ...items, "   </TPOOL>"] : []),
    "  </asx:values>",
    " </asx:abap>",
    "</abapGit>",
    "",
  ].join("\n");
}
