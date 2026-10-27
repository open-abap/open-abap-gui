import { Expressions, Nodes } from "@abaplint/core";
import { fragmentAst } from "../abap/ast.js";
import type { TokenEntry } from "../abap/ast.js";
import type { Replacement } from "./lower-statements.js";

// The converter renames report data in carried-over statements: a global that
// moved to the owner class, a reserved name, a selection parameter's member.
// Only a reference to the data object may change. The same spelling is also a
// component (`ls_row-value`, `get( )-value`), an attribute or method (`->name`,
// `=>name`, `~name`), a field symbol (`<value>`), a table key or a constructor
// component (`itab[ name = ... ]`, `VALUE #( name = ... )`), a formal parameter
// (`EXPORTING name = ...`), a column or a database table, and renaming one of
// those either breaks the statement or changes what it means. abaplint tells
// them apart: each is a name of its own kind in the syntax tree.
const NAMES = [
  Expressions.ComponentName,
  Expressions.AttributeName,
  Expressions.MethodName,
  Expressions.ParameterName,
  Expressions.SQLFieldName,
  Expressions.SQLAsName,
  Expressions.DatabaseTable,
  // A component in a constructor row, a TRANSPORTING or COMPARING list, or a
  // parameter of the report SUBMIT calls.
  Expressions.FieldSub,
];

// The components after COMPARING and TRANSPORTING, which abaplint reads as
// fields in DELETE ADJACENT DUPLICATES.
const COMPONENT_LISTS = new Set(["COMPARING", "TRANSPORTING"]);

function inComponentList(entry: TokenEntry): boolean {
  const operand = entry.ancestors[1];
  if (!operand) return false;
  const siblings = entry.statement.getChildren();
  let index = siblings.indexOf(operand as Nodes.ExpressionNode) - 1;
  while (index >= 0 && siblings[index] instanceof Nodes.ExpressionNode) index--;
  return COMPONENT_LISTS.has(siblings[index]?.getFirstToken().getUpperStr() ?? "");
}

// A name token that refers to a data object, class or type. A keyword spelled
// like the name, VALUE in VALUE #( ), is none, and neither is a match inside a
// literal, a template's text or a field symbol: no name starts there.
export function isReference(entry: TokenEntry | undefined): boolean {
  if (!entry || !(entry.node instanceof Nodes.TokenNodeRegex)) return false;
  const parent = entry.parent.get();
  return !NAMES.some((type) => parent instanceof type) && !inComponentList(entry);
}

// Applies [pattern, replacement] pairs in order, each to the result of the
// ones before, at references only. A pattern is a regular expression source
// without anchors, e.g. a name or `screen-(input|output)`, and the replacement
// may use its groups.
export function replaceIdentifiers(text: string | undefined, replacements: readonly Replacement[] | undefined): string {
  let output = String(text ?? "");
  for (const [name, replacement] of replacements ?? []) {
    const pattern = new RegExp(`\\b(?:${name})\\b`, "gi");
    if (!pattern.test(output)) continue;
    const ast = fragmentAst(output);
    // Without its syntax tree, no occurrence is known to be a reference.
    if (!ast) continue;
    pattern.lastIndex = 0;
    const whole = new RegExp(`^(?:${name})$`, "i");
    let result = "";
    let last = 0;
    for (const match of output.matchAll(pattern)) {
      if (!isReference(ast.tokenAt(match.index))) continue;
      result += output.slice(last, match.index) + match[0].replace(whole, replacement);
      last = match.index + match[0].length;
    }
    output = result + output.slice(last);
  }
  return output;
}
