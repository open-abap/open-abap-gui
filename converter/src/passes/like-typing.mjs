import { maskedCode } from "./replace-identifiers.mjs";

// In a report, LIKE may name a dictionary structure or table, or one of its
// components, as in LIKE mara-matnr or LIKE TABLE OF bapiret2; a TABLES work
// area has the name of its table. In a class, LIKE names a data object only.
// A declaration's LIKE whose head is no data object in scope is written TYPE,
// which names the same type; one that is gets the head's name in the class,
// e.g. a parameter's member. Component names, as in BEGIN OF ... p_dir LIKE
// p_dir, are not LIKE operands and stay.

const LIKE_OPERAND = /\bLIKE(\s+(?:LINE\s+OF|REF\s+TO|RANGE\s+OF|(?:(?:STANDARD|SORTED|HASHED|ANY|INDEX)\s+)?TABLE\s+OF)\s+|\s+)([A-Z][A-Z0-9_\/]*)((?:-[A-Z][A-Z0-9_]*)*)/gi;

// Data objects every class sees.
const PREDEFINED = new Set(["SY", "SPACE", "ME", "ABAP_TRUE", "ABAP_FALSE", "ABAP_UNDEFINED"]);

// member(name) is what a declaration sees as name: the name in the class of a
// data object, { type } for a TABLES work area, typed by its table, or
// undefined when there is none.
export function likeTyping(text, member) {
  const code = maskedCode(text);
  let output = "";
  let last = 0;
  for (const match of code.matchAll(LIKE_OPERAND)) {
    const [, addition, head, components] = match;
    const upper = head.toUpperCase();
    if (PREDEFINED.has(upper)) continue;
    const resolved = member(upper);
    const operand = typeof resolved === "string"
      ? `LIKE${addition}${resolved}${components}`
      : `TYPE${addition}${resolved?.type ?? head}${components}`;
    output += text.slice(last, match.index) + operand;
    last = match.index + match[0].length;
  }
  return output + text.slice(last);
}

// The data objects the declarations in text name in LIKE, upper case.
export function likeHeads(text) {
  return [...maskedCode(text).matchAll(LIKE_OPERAND)].map((match) => match[2].toUpperCase());
}

// The names a declaration in a routine or event sees as data objects: its
// own and the routine's, mapped to themselves, then the program's.
export function scopedMember(localNames, globalMember) {
  return (name) => localNames.has(name) ? name.toLowerCase() : globalMember(name);
}
