import fs from "node:fs/promises";
import { Config, MemoryFile, Nodes, Registry, Version, VirtualPosition } from "@abaplint/core";
import { ABAPParser } from "@abaplint/core/build/src/abap/abap_parser.js";
import { diagnostic, parserIssueToDiagnostic } from "./diagnostics.js";
import { rangeFromOffsets } from "./source-resolver.js";
import type { Diagnostic, SourceUnit, Span, Statement } from "./types.js";

export interface ParsedStatement extends Statement {
  node: Nodes.StatementNode;
}

export interface ParsedUnit extends SourceUnit {
  statements: ParsedStatement[];
}

export interface ParseResult {
  units: ParsedUnit[];
  diagnostics: Diagnostic[];
  config: Config;
}

function statementText(statement: Nodes.StatementNode): string {
  // A macro expansion's tokens all sit at the call; only their virtual
  // positions tell sy-dbcnt from sy - dbcnt.
  if (statement.getFirstToken?.()?.getStart() instanceof VirtualPosition) return statement.concatTokensVirtual();
  return statement.concatTokens?.() ?? "";
}

function offsetForPosition(source: string, position: { row: number; col: number }): number {
  const lines = source.split("\n");
  let offset = 0;
  for (let index = 0; index < Math.max(0, (position.row ?? 1) - 1); index++) offset += (lines[index]?.length ?? 0) + 1;
  return offset + Math.max(0, (position.col ?? 1) - 1);
}

function sourceSpan(source: string, statement: Nodes.StatementNode): Span {
  const start = statement.getStart();
  const end = statement.getEnd();
  const startOffset = offsetForPosition(source, { row: start.getRow(), col: start.getCol() });
  const endOffset = offsetForPosition(source, { row: end.getRow(), col: end.getCol() });
  return { ...rangeFromOffsets(source, startOffset, endOffset), startOffset, endOffset };
}

function configuredParser(config: Config): ABAPParser {
  const registry = new Registry(config);
  return new ABAPParser({
    release: config.getRelease(),
    languageVersion: config.getLanguageVersion(),
    globalMacros: config.getSyntaxSetttings().globalMacros,
    reg: registry,
  });
}

export async function readConfig(configPath = "abaplint.jsonc"): Promise<Config> {
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

export function generatedSourceConfig(config: Config = Config.getDefault()): Config {
  if (!PRE_SCAFFOLD_RELEASES.has(config.getRelease()?.name)) return config;
  const raw = JSON.parse(JSON.stringify(config.get()));
  const version = raw.syntax.version;
  raw.syntax.version = version && typeof version === "object"
    ? { ...version, release: Version.v740sp08 }
    : Version.v740sp08;
  return new Config(JSON.stringify(raw));
}

export function parseUnits(units: SourceUnit[], config: Config = Config.getDefault()): ParseResult {
  const parser = configuredParser(config);
  const diagnostics: Diagnostic[] = [];
  const parsedUnits: ParsedUnit[] = [];
  for (const unit of units) {
    const result = parser.parse([new MemoryFile(unit.filename, unit.source)]);
    diagnostics.push(...result.issues.map((issue) => parserIssueToDiagnostic(issue, unit.filename)));
    const file = result.output[0];
    const statements: ParsedStatement[] = [];
    for (const statement of file?.getStatements() ?? []) {
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

export function parseSource(source: string, filename = "program.prog.abap", config: Config = Config.getDefault()): ParseResult {
  return parseUnits([{ source, filename, ancestry: [], newline: "\n" }], config);
}
