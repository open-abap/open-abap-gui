import { ArtifactsRules, Config, Edits, MemoryFile, Registry } from "@abaplint/core";
import {textLiteral} from "./abap-text.mjs";

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

function breakRemainingExpressions(registry, filename, source) {
  const file = registry.getFirstObject().getABAPFiles()[0];
  const lines = source.split("\n");
  const offsets = [];
  let offset = 0;
  for (const line of lines) { offsets.push(offset); offset += line.length + 1; }
  const inserts = new Map();
  const before = (token, indent) => {
    const pos = token.getStart();
    const line = lines[pos.getRow() - 1];
    const column = pos.getCol() - 1;
    if (!line.slice(0, column).trim()) return;
    inserts.set(offsets[pos.getRow() - 1] + column, "\n" + " ".repeat(indent));
  };
  const visit = (node, indent) => {
    const kind = node.get?.().constructor.name;
    const children = node.getChildren?.() ?? [];
    if (kind === "MethodParameters") {
      const sections = children.filter(child => /^(EXPORTING|IMPORTING|CHANGING|RECEIVING|EXCEPTIONS)$/i.test(child.concatTokens?.() ?? ""));
      if (sections.length > 1) {
        for (const section of sections) before(section.getFirstToken(), indent + 2);
        for (const child of children) {
          for (const parameter of child.getChildren?.() ?? []) {
            if (["ParameterS", "ParameterT"].includes(parameter.get?.().constructor.name)) before(parameter.getFirstToken(), indent + 4);
          }
        }
      }
    } else if (kind === "ValueBody") {
      const rows = children.filter(child => child.get?.().constructor.name === "ValueBodyLine");
      if (rows.length > 1) for (const row of rows) before(row.getFirstToken(), indent + 2);
    }
    for (const child of children) visit(child, indent);
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

export function applyStyleFixes(source, className) {
  const filename = `${className.toLowerCase()}.clas.abap`;
  const registry = new Registry(Config.getDefault());
  registry.addFile(new MemoryFile(filename, source));
  registry.parse();
  // Template tokens contain only literal text; embedded expressions have
  // their own tokens, including quoted strings and nested templates.
  const lines = source.split("\n");
  const offsets = [];
  let offset = 0;
  for (const line of lines) { offsets.push(offset); offset += line.length + 1; }
  const edits = [];
  for (const statement of registry.getFirstObject().getABAPFiles()[0].getStatements()) {
    for (const token of statement.getTokens()) {
      const literal = token.getStr();
      if (!/[^\x00-\x7f]/.test(literal)) continue;
      let replacement;
      if (token.constructor.name === "StringToken") {
        const quote = literal[0];
        replacement = textLiteral(literal.slice(1, -1).replaceAll(quote + quote, quote));
      } else if (token.constructor.name.startsWith("StringTemplate")) {
        replacement = literal.replace(/[^\x00-\x7f]+/g, text => `{ ${textLiteral(text)} }`);
      }
      if (replacement) {
        const position = token.getStart();
        edits.push({start: offsets[position.getRow() - 1] + position.getCol() - 1, literal, replacement});
      }
    }
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
        return rule.run(object);
      })
      .map((issue) => issue.getDefaultFix())
      .find(Boolean);
    if (!fix) break;
    Edits.applyEditSingle(registry, fix);
  }
  // The line-break fix leaves the blank before the new line behind.
  return (registry.getFileByName(filename)?.getRaw() ?? source).replace(/[ \t]+$/gm, "");
}
