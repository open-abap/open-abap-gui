import { ABAPObject, ArtifactsRules, Config, Edits, Expressions, MemoryFile, Nodes, Registry } from "@abaplint/core";
import type { Position, Token } from "@abaplint/core";
import {textLiteral} from "./abap-text.js";
import {parsesAsStatement} from "../abap/ast.js";

const DECLARATIONS = new Set([
  "Data", "DataBegin", "DataEnd", "Constant", "ConstantBegin", "ConstantEnd", "Static", "StaticBegin", "StaticEnd",
  "ClassData", "ClassDataBegin", "ClassDataEnd", "Parameter", "SelectOption", "Type", "TypeBegin", "TypeEnd", "MethodDef",
]);

// Lowering writes each statement on one line. The quick fixes of these
// abaplint rules give a call with several parameters one line per parameter,
// aligned, and drop a chain colon that chains nothing, as the repository's
// lint configuration asks.
const RULES = ["line_break_multiple_parameters", "align_parameters", "unnecessary_chaining", "indentation"];
const MAX_EDITS = 500;

function ruleInstances() {
  return ArtifactsRules.getRules()
    .filter((rule) => RULES.includes(rule.getMetadata().key))
    .map((rule) => {
      rule.setConfig(rule.getConfig());
      return rule;
    });
}

function breakRemainingExpressions(registry: Registry, filename: string, source: string): void {
  const file = (registry.getFirstObject() as ABAPObject).getABAPFiles()[0];
  const lines = source.split("\n");
  const offsets: number[] = [];
  let offset = 0;
  for (const line of lines) { offsets.push(offset); offset += line.length + 1; }
  const inserts = new Map<number, string>();
  const before = (token: Token, indent: number) => {
    const pos = token.getStart();
    const line = lines[pos.getRow() - 1];
    const column = pos.getCol() - 1;
    if (!line.slice(0, column).trim()) return;
    inserts.set(offsets[pos.getRow() - 1] + column, "\n" + " ".repeat(indent));
  };
  const visit = (node: Nodes.StatementNode | Nodes.ExpressionNode, indent: number) => {
    const children = node.getChildren();
    if (node.get() instanceof Expressions.MethodParameters) {
      const sections = children.filter((child) => /^(EXPORTING|IMPORTING|CHANGING|RECEIVING|EXCEPTIONS)$/i.test(child.concatTokens()));
      if (sections.length > 1) {
        for (const section of sections) before(section.getFirstToken(), indent + 2);
        for (const child of children) {
          if (!(child instanceof Nodes.ExpressionNode)) continue;
          for (const parameter of child.getChildren()) {
            if (parameter instanceof Nodes.ExpressionNode && (parameter.get() instanceof Expressions.ParameterS || parameter.get() instanceof Expressions.ParameterT)) before(parameter.getFirstToken(), indent + 4);
          }
        }
      }
    } else if (node.get() instanceof Expressions.ValueBody) {
      const rows = children.filter((child) => child instanceof Nodes.ExpressionNode && child.get() instanceof Expressions.ValueBodyLine);
      if (rows.length > 1) for (const row of rows) before(row.getFirstToken(), indent + 2);
    }
    for (const child of children) if (!(child instanceof Nodes.TokenNode)) visit(child, indent);
  };
  for (const statement of file.getStatements()) {
    const indent = statement.getFirstToken().getStart().getCol() - 1;
    visit(statement, indent);
    const tokens = statement.getTokens();
    if (statement.get().constructor.name === "CreateObject") {
      const section = tokens.find(token => token.getStr().toUpperCase() === "EXPORTING");
      if (section) before(section, indent + 2);
    }
    for (const token of tokens) if (token.getStr() === "&&") before(token, indent + 2);
  }
  for (const [position, value] of [...inserts].sort((a, b) => b[0] - a[0])) source = source.slice(0, position) + value + source.slice(position);
  registry.updateFile(new MemoryFile(filename, source));
}

interface LiteralEdit {
  start: number;
  literal: string;
  replacement: string;
  text?: string;
  quote?: string;
}

export function applyStyleFixes(source: string, className: string): string {
  const filename = `${className.toLowerCase()}.clas.abap`;
  const registry = new Registry(Config.getDefault());
  registry.addFile(new MemoryFile(filename, source));
  registry.parse();
  // Template tokens contain only literal text; embedded expressions have
  // their own tokens, including quoted strings and nested templates.
  const lines = source.split("\n");
  const offsets: number[] = [];
  let offset = 0;
  for (const line of lines) { offsets.push(offset); offset += line.length + 1; }
  const offsetOf = (position: Position) => offsets[position.getRow() - 1] + position.getCol() - 1;
  const edits: LiteralEdit[] = [];
  let hoisted = 0;
  for (const statement of (registry.getFirstObject() as ABAPObject).getABAPFiles()[0].getStatements()) {
    const statementEdits: LiteralEdit[] = [];
    for (const token of statement.getTokens()) {
      const literal = token.getStr();
      if (!/[^\x00-\x7f]/.test(literal)) continue;
      let replacement: string | undefined;
      let text: string | undefined;
      if (token.constructor.name === "StringToken") {
        const quote = literal[0];
        text = literal.slice(1, -1).replaceAll(quote + quote, quote);
        replacement = textLiteral(text);
      } else if (token.constructor.name.startsWith("StringTemplate")) {
        replacement = literal.replace(/[^\x00-\x7f]+/g, text => `{ ${textLiteral(text)} }`);
      }
      if (replacement) statementEdits.push({start: offsetOf(token.getStart()), literal, replacement, text, quote: literal[0]});
    }
    if (!statementEdits.length) continue;
    // The decoded text is an expression, which only some operand positions
    // accept: CONCATENATE, Open SQL and EXPORTING take data objects. There the
    // text is decoded into a variable first. A declaration cannot be preceded
    // by that, so its VALUE literal keeps its characters.
    const start = offsetOf(statement.getFirstToken().getStart());
    const end = offsetOf(statement.getLastToken().getEnd());
    let inline = source.slice(start, end);
    for (const edit of [...statementEdits].sort((a, b) => b.start - a.start)) {
      inline = inline.slice(0, edit.start - start) + edit.replacement + inline.slice(edit.start - start + edit.literal.length);
    }
    if (parsesAsStatement(inline)) {
      edits.push(...statementEdits);
      continue;
    }
    const kind = statement.get().constructor.name;
    if (DECLARATIONS.has(kind)) continue;
    const indent = " ".repeat(statement.getFirstToken().getStart().getCol() - 1);
    const host = /^Select/.test(kind) && source.slice(start, end).includes("@") ? "@" : "";
    const declarations: string[] = [];
    for (const edit of statementEdits) {
      if (edit.text === undefined) {
        edits.push(edit);
        continue;
      }
      const name = `lv_ggconv_text_${++hoisted}`;
      // A '...' literal is a text field: kept as type c, its trailing blanks
      // are ignored where the literal's would be, as by CONCATENATE.
      const type = edit.quote === "'" ? `c LENGTH ${Math.max(1, edit.text.length)}` : "string";
      declarations.push(`DATA ${name} TYPE ${type}.\n${indent}${name} = ${edit.replacement}.\n${indent}`);
      edits.push({...edit, replacement: `${host}${name}`});
    }
    edits.push({start, literal: "", replacement: declarations.join("")});
  }
  for (const {start, literal, replacement} of edits.sort((a, b) => b.start - a.start)) {
    source = source.slice(0, start) + replacement + source.slice(start + literal.length);
  }
  registry.updateFile(new MemoryFile(filename, source));
  registry.parse();
  breakRemainingExpressions(registry, filename, source);
  const rules = ruleInstances();
  for (let count = 0; count < MAX_EDITS; count++) {
    registry.parse();
    const object = registry.getFirstObject();
    const fix = rules
      .flatMap((rule) => {
        rule.initialize(registry);
        return rule.run(object!);
      })
      .map((issue) => issue.getDefaultFix())
      .find(Boolean);
    if (!fix) break;
    Edits.applyEditSingle(registry, fix);
  }
  // The line-break fix leaves the blank before the new line behind.
  return (registry.getFileByName(filename)?.getRaw() ?? source).replace(/[ \t]+$/gm, "");
}
