import fs from "node:fs/promises";
import { Config, MemoryFile, Registry, Version } from "@abaplint/core";
import { ABAPParser } from "@abaplint/core/build/src/abap/abap_parser.js";
import { diagnostic, parserIssueToDiagnostic } from "./diagnostics.mjs";
import { rangeFromOffsets } from "./source-resolver.mjs";

function statementText(statement) {
  return statement.concatTokens?.() ?? "";
}

function offsetForPosition(source, position) {
  const lines = source.split("\n");
  let offset = 0;
  for (let index = 0; index < Math.max(0, (position.row ?? 1) - 1); index++) offset += (lines[index]?.length ?? 0) + 1;
  return offset + Math.max(0, (position.col ?? 1) - 1);
}

function sourceSpan(source, statement) {
  const start = statement.getStart?.() ?? { row: 0, col: 0 };
  const end = statement.getEnd?.() ?? start;
  const startOffset = offsetForPosition(source, start);
  const endOffset = offsetForPosition(source, end);
  return { ...rangeFromOffsets(source, startOffset, endOffset), startOffset, endOffset };
}

function configuredParser(config) {
  const registry = new Registry(config);
  return new ABAPParser({
    release: config.getRelease(),
    languageVersion: config.getLanguageVersion(),
    globalMacros: config.getSyntaxSetttings().globalMacros,
    reg: registry,
  });
}

export async function readConfig(configPath = "abaplint.jsonc") {
  try {
    return new Config(await fs.readFile(configPath, "utf8"));
  } catch {
    return Config.getDefault();
  }
}

// The generated class is written for the scaffold, whose own sources need
// 7.40 SP08: VALUE #, inline declarations, xsdbool. A project configured for an
// older release still has its reports parsed with that release, but checking
// the generated class against it would reject every converted program.
const PRE_SCAFFOLD_RELEASES = new Set(["v700", "v702", "v740sp02", "v740sp05"]);

export function generatedSourceConfig(config = Config.getDefault()) {
  if (!PRE_SCAFFOLD_RELEASES.has(config.getRelease()?.name)) return config;
  const raw = JSON.parse(JSON.stringify(config.get()));
  const version = raw.syntax.version;
  raw.syntax.version = version && typeof version === "object"
    ? { ...version, release: Version.v740sp08 }
    : Version.v740sp08;
  return new Config(JSON.stringify(raw));
}

export function parseUnits(units, config = Config.getDefault()) {
  const parser = configuredParser(config);
  const diagnostics = [];
  const parsedUnits = [];
  for (const unit of units) {
    const result = parser.parse([new MemoryFile(unit.filename, unit.source)]);
    diagnostics.push(...result.issues.map((issue) => parserIssueToDiagnostic(issue, unit.filename)));
    const file = result.output[0];
    const statements = [];
    for (const statement of file?.getStatements?.() ?? []) {
      const span = sourceSpan(unit.source, statement);
      const kind = statement.get?.()?.constructor?.name ?? statement.constructor.name;
      const text = statementText(statement);
      if (kind === "Unknown") {
        diagnostics.push(diagnostic({
          code: "GGCONV-E201",
          filename: unit.filename,
          start: span.start,
          end: span.end,
          construct: text.trim() || "unknown syntax",
          message: "abaplint could not classify this statement",
          suggestion: "Rewrite the statement using a supported ABAP construct or convert it manually.",
          phase: "parse",
        }));
      }
      statements.push({
        node: statement,
        kind,
        text,
        span,
        filename: unit.filename,
        ancestry: unit.ancestry,
      });
    }
    parsedUnits.push({ ...unit, statements });
  }
  return { units: parsedUnits, diagnostics, config };
}

let statementParser;
const statementParses = new Map();

// Whether abaplint classifies every statement in the text. Lowering uses it to
// check that a rewrite left the statement parseable, for example that a
// statement accepts a method call where it had a data object.
export function parsesAsStatement(text) {
  if (!statementParses.has(text)) {
    statementParser ??= configuredParser(Config.getDefault());
    const file = statementParser.parse([new MemoryFile("zggconv_probe.prog.abap", text)]).output[0];
    const statements = file?.getStatements?.() ?? [];
    statementParses.set(text, statements.length > 0
      && statements.every((statement) => (statement.get?.()?.constructor?.name ?? statement.constructor.name) !== "Unknown"));
  }
  return statementParses.get(text);
}

const keywordParses = new Map();

function keywordsOfStatements(text) {
  statementParser ??= configuredParser(Config.getDefault());
  const file = statementParser.parse([new MemoryFile("zggconv_probe.prog.abap", text)]).output[0];
  const statements = file?.getStatements?.() ?? [];
  if (!statements.length || statements.some((statement) => (statement.get?.()?.constructor?.name ?? statement.constructor.name) === "Unknown")) return undefined;
  const lineStarts = [0];
  for (let index = 0; index < text.length; index++) if (text[index] === "\n") lineStarts.push(index + 1);
  const offsets = new Set();
  for (const statement of statements) {
    const visit = (node) => {
      if (node.constructor.name === "TokenNode") {
        const token = node.getFirstToken();
        if (/^[A-Z_]/i.test(token.getStr())) offsets.add(lineStarts[token.getStart().getRow() - 1] + token.getStart().getCol() - 1);
        return;
      }
      for (const child of node.getChildren?.() ?? []) visit(child);
    };
    visit(statement);
  }
  return offsets;
}

// The offsets of the keywords in ABAP text: what abaplint matched as a word of
// the syntax rather than as a name, such as VALUE in `VALUE #( value = 1 )`.
// The text is a statement or an expression; undefined if it parses as neither.
export function keywordOffsets(text) {
  if (!keywordParses.has(text)) {
    const prefix = "ggconv_probe = ";
    let offsets = keywordsOfStatements(text);
    if (!offsets) {
      const expression = keywordsOfStatements(`${prefix}${text}.`);
      offsets = expression && new Set([...expression].filter((offset) => offset >= prefix.length).map((offset) => offset - prefix.length));
    }
    keywordParses.set(text, offsets);
  }
  return keywordParses.get(text);
}

export function parseSource(source, filename = "program.prog.abap", config = Config.getDefault()) {
  return parseUnits([{ source, filename, ancestry: [], newline: "\n" }], config);
}
