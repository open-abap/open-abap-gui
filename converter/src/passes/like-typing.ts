import { Nodes } from "@abaplint/core";
import { sourceAst } from "../abap/ast.js";
import type { TokenEntry } from "../abap/ast.js";

// In a report, LIKE may name a dictionary structure or table, or one of its
// components, as in LIKE mara-matnr or LIKE TABLE OF bapiret2; a TABLES work
// area has the name of its table. In a class, LIKE names a data object only.
// A declaration's LIKE whose head is no data object in scope is written TYPE,
// which names the same type; one that is gets the head's name in the class,
// e.g. a parameter's member. Component names, as in BEGIN OF ... p_dir LIKE
// p_dir, are not LIKE operands and stay.

// What may stand between LIKE and its operand.
const ADDITIONS = [
  "LINE OF", "REF TO", "RANGE OF",
  "STANDARD TABLE OF", "SORTED TABLE OF", "HASHED TABLE OF", "ANY TABLE OF", "INDEX TABLE OF", "TABLE OF",
].map((addition) => addition.split(" "));

// Data objects every class sees.
const PREDEFINED = new Set(["SY", "SPACE", "ME", "ABAP_TRUE", "ABAP_FALSE", "ABAP_UNDEFINED"]);

interface LikeOperand {
  like: TokenEntry;
  head: TokenEntry;
  /** Where the operand's components, as -matnr, end. */
  end: number;
}

function isKeyword(entry: TokenEntry | undefined, word: string): boolean {
  return Boolean(entry && !(entry.node instanceof Nodes.TokenNodeRegex) && entry.token.getUpperStr() === word);
}

function likeOperands(text: string): LikeOperand[] {
  const tokens = sourceAst(text)?.tokens() ?? [];
  const operands: LikeOperand[] = [];
  for (let index = 0; index < tokens.length; index++) {
    if (!isKeyword(tokens[index], "LIKE")) continue;
    const addition = ADDITIONS.find((words) => words.every((word, offset) => isKeyword(tokens[index + 1 + offset], word))) ?? [];
    const head = tokens[index + 1 + addition.length];
    if (!(head?.node instanceof Nodes.TokenNodeRegex) || !/^[A-Z][A-Z0-9_/]*$/i.test(head.token.getStr())) continue;
    let end = head.end;
    for (let next = index + 2 + addition.length; tokens[next]?.token.getStr() === "-" && tokens[next].start === end
      && tokens[next + 1]?.start === tokens[next].end; next += 2) end = tokens[next + 1].end;
    operands.push({ like: tokens[index], head, end });
  }
  return operands;
}

// member(name) is what a declaration sees as name: the name in the class of a
// data object, { type } for a TABLES work area, typed by its table, or
// undefined when there is none.
export function likeTyping(text: string, member: (name: string) => string | { type: string } | undefined): string {
  let output = "";
  let last = 0;
  for (const { like, head, end } of likeOperands(text)) {
    const name = head.token.getStr();
    if (PREDEFINED.has(name.toUpperCase())) continue;
    const resolved = member(name.toUpperCase());
    const addition = text.slice(like.end, head.start);
    const components = text.slice(head.end, end);
    const operand = typeof resolved === "string"
      ? `LIKE${addition}${resolved}${components}`
      : `TYPE${addition}${resolved?.type ?? name}${components}`;
    output += text.slice(last, like.start) + operand;
    last = end;
  }
  return output + text.slice(last);
}

// The data objects the declarations in text name in LIKE, upper case.
export function likeHeads(text: string): string[] {
  return likeOperands(text).map(({ head }) => head.token.getUpperStr());
}

// The names a declaration in a routine or event sees as data objects: its
// own and the routine's, mapped to themselves, then the program's.
export function scopedMember(localNames: Set<string>, globalMember: (name: string) => string | { type: string } | undefined): (name: string) => string | { type: string } | undefined {
  return (name) => localNames.has(name) ? name.toLowerCase() : globalMember(name);
}
