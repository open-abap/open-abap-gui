// A text for generated source. The source stays 7-bit ASCII, as the lint rules
// ask; a text with other characters (a title in Hebrew, an emoji in a function
// text) is written as its UTF-8 bytes and decoded at runtime.
export function textLiteral(value) {
  const text = String(value ?? "");
  if (/^[\x20-\x7e]*$/.test(text)) return `'${text.replaceAll("'", "''")}'`;
  const hex = Buffer.from(text, "utf8").toString("hex").toUpperCase();
  // A literal holds at most 255 characters.
  const parts = hex.match(/.{1,200}/g).map((part) => `'${part}'`).join(" && ");
  return `cl_abap_codepage=>convert_from( CONV xstring( ${parts} ) )`;
}
