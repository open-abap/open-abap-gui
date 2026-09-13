import fs from "node:fs/promises";
import { Config, MemoryFile, Registry } from "@abaplint/core";
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

export function parseSource(source, filename = "program.prog.abap", config = Config.getDefault()) {
  return parseUnits([{ source, filename, ancestry: [], newline: "\n" }], config);
}
