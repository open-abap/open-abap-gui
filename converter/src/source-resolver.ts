import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { Expressions, Statements, Tokens } from "@abaplint/core";
import { lexedAst } from "./abap/ast.js";
import { diagnostic } from "./diagnostics.js";
import type { Diagnostic, Position, SourceUnit } from "./types.js";

export interface SystemInclude {
  name: string;
  patterns: string[];
  filename: string;
  start: Position;
}

export interface ResolvedSources {
  units: SourceUnit[];
  diagnostics: Diagnostic[];
  systemIncludes: SystemInclude[];
  sourceHash: string;
  newline: string;
}

export type IncludeResolver = (name: string, parentFilename: string) => unknown;

function normalizeSource(source: string): { source: string; newline: string } {
  const withoutBom = source.replace(/^\uFEFF/, "");
  const newline = withoutBom.includes("\r\n") ? "\r\n" : "\n";
  return { source: withoutBom.replace(/\r\n?/g, "\n"), newline };
}

export function sourceHash(source: string): string {
  return crypto.createHash("sha256").update(normalizeSource(source).source, "utf8").digest("hex");
}

function linePosition(source: string, offset: number): Position {
  const before = source.slice(0, Math.max(0, offset));
  const lastNewline = before.lastIndexOf("\n");
  return { line: (before.match(/\n/g) ?? []).length + 1, column: offset - lastNewline };
}

export function rangeFromOffsets(source: string, startOffset: number, endOffset: number): { start: Position; end: Position } {
  return { start: linePosition(source, startOffset), end: linePosition(source, endOffset) };
}

// abapGit-serialised repositories store INCLUDE programs as `<name>.prog.abap`,
// so that suffix has to be tried alongside the `<name>.incl.abap` form.
const INCLUDE_SUFFIXES = ["", ".incl.abap", ".prog.abap"];

function includeCandidates(name: string, parentFilename: string, searchPaths: string[] = []): string[] {
  const bases = [undefined, path.dirname(parentFilename), ...searchPaths];
  const candidates = bases.flatMap((base) => INCLUDE_SUFFIXES
    .map((suffix) => (base === undefined ? `${name}${suffix}` : path.join(base, `${name}${suffix}`))));
  return candidates.filter((value, index, values) => values.indexOf(value) === index);
}

async function loadInclude(name: string, parentFilename: string, resolver: IncludeResolver | undefined, includePaths: string[]): Promise<{ filename: string; source: string } | undefined> {
  if (typeof resolver === "function") {
    try {
      const result = await resolver(name, parentFilename) as string | { filename?: string; source?: unknown } | undefined;
      if (typeof result === "string") {
        return { filename: name, source: result };
      }
      if (result && typeof result.source === "string") {
        return { filename: result.filename ?? name, source: result.source as string };
      }
    } catch {
      return undefined;
    }
  }
  for (const candidate of includeCandidates(name, parentFilename, includePaths)) {
    try {
      return { filename: candidate, source: await fs.readFile(candidate, "utf8") };
    } catch {
      // Try the next deterministic candidate.
    }
  }
  return undefined;
}

// The kernel's own includes, INCLUDE <name>, which no library ships as source.
// Each only declares constants. <ICON> declares those of TYPE-POOL icon, which
// open-abap-core provides, and <COLOR> the list colors abaplint and the
// transpiler know as built-ins, so both are complete without the include. The
// others are skipped and checked against the generated class: a constant of
// theirs still referenced there is GGCONV-E102, otherwise GGCONV-W109 notes
// the skip. WRITE ... AS SYMBOL needs no constant, it writes the symbol's name.
// An include not listed here declares who knows what and stays GGCONV-E102.
const LINE_ELEMENTS = [
  "SPACE", "CROSS", "HORIZONTAL_LINE", "VERTICAL_LINE",
  "TOP_LEFT_CORNER", "TOP_RIGHT_CORNER", "BOTTOM_LEFT_CORNER", "BOTTOM_RIGHT_CORNER",
  "TOP_MIDDLE_CORNER", "BOTTOM_MIDDLE_CORNER", "LEFT_MIDDLE_CORNER", "RIGHT_MIDDLE_CORNER",
].map((name) => `LINE_${name}\\b`);
const SYMBOL_ELEMENTS = ["SYM_[A-Z0-9_]+"];
const SYSTEM_INCLUDES: Record<string, { provided?: boolean; patterns?: string[] }> = {
  ICON: { provided: true },
  COLOR: { provided: true },
  SYMBOL: { patterns: SYMBOL_ELEMENTS },
  LINE: { patterns: LINE_ELEMENTS },
  // <LIST> is <SYMBOL>, <ICON>, <LINE> and <COLOR> together.
  LIST: { patterns: [...SYMBOL_ELEMENTS, ...LINE_ELEMENTS] },
};

// The constant of a skipped system include that generated source still
// references, as an unqualified name: a component such as ls_x-sym_y, an
// attribute behind -> or =>, or a name the program declares itself is not one.
export function systemIncludeUse(include: SystemInclude, sources: string[], declared: Set<string> = new Set()): string | undefined {
  const pattern = new RegExp(`^(?:${include.patterns.join("|")})$`, "i");
  for (const source of sources) {
    const tokens = lexedAst(String(source))?.tokens() ?? [];
    for (const [index, entry] of tokens.entries()) {
      const before = tokens[index - 1];
      const qualified = before?.end === entry.start && ["-", "~", "->", "=>"].includes(before.token.getStr());
      const name = entry.token.getStr();
      if (!(entry.token instanceof Tokens.Comment) && !qualified && pattern.test(name) && !declared.has(name.toUpperCase())) return name.toLowerCase();
    }
  }
  return undefined;
}

// The INCLUDE statements of a source, each with the offset of the line it
// starts on.
function findIncludes(source: string): { name: string; optional: boolean; offset: number }[] {
  const ast = lexedAst(source);
  return (ast?.statements ?? []).filter((statement) => statement.get() instanceof Statements.Include).flatMap((statement) => {
    const name = statement.findDirectExpression(Expressions.IncludeName);
    if (!ast || !name) return [];
    const start = ast.start(statement);
    return [{ name: ast.source(name), optional: ast.has("IF FOUND", statement), offset: source.lastIndexOf("\n", start - 1) + 1 }];
  });
}

export async function resolveSources({ source, filename, resolveInclude, includePaths }: { source: string; filename: string; resolveInclude?: IncludeResolver; includePaths?: string[] }): Promise<ResolvedSources> {
  const searchPaths = (Array.isArray(includePaths) ? includePaths : []).filter((item) => typeof item === "string" && item);
  const diagnostics: Diagnostic[] = [];
  const units: SourceUnit[] = [];
  const systemIncludes: SystemInclude[] = [];
  const seen = new Set<string>();
  const active: string[] = [];

  async function visit(unit: { filename: string; source: string; hashKey?: string }, ancestry: string[]): Promise<void> {
    const normalized = normalizeSource(unit.source);
    const identity = path.normalize(unit.filename).toUpperCase();
    if (active.includes(identity)) {
      diagnostics.push(diagnostic({
        code: "GGCONV-E104",
        filename: unit.filename,
        start: linePosition(normalized.source, 0),
        construct: "INCLUDE",
        message: `cyclic include detected: ${[...active, identity].join(" -> ")}`,
        suggestion: "Break the include cycle or supply a resolver that returns a flattened source.",
        phase: "source-resolution",
      }));
      return;
    }
    if (seen.has(identity)) {
      diagnostics.push(diagnostic({
        code: "GGCONV-E103",
        filename: unit.filename,
        construct: "INCLUDE",
        message: `include ${unit.filename} is resolved more than once`,
        suggestion: "Remove the duplicate include or make its ownership explicit.",
        phase: "source-resolution",
      }));
      return;
    }
    seen.add(identity);
    active.push(identity);
    units.push({ filename: unit.filename, source: normalized.source, newline: normalized.newline, ancestry, hashKey: unit.hashKey });
    for (const include of findIncludes(normalized.source)) {
      const system = /^<([A-Z0-9_]+)>$/i.exec(include.name)?.[1]?.toUpperCase();
      if (system && SYSTEM_INCLUDES[system]) {
        if (!SYSTEM_INCLUDES[system].provided) {
          systemIncludes.push({ name: system, patterns: SYSTEM_INCLUDES[system].patterns!, filename: unit.filename, start: linePosition(normalized.source, include.offset) });
        }
        continue;
      }
      const loaded = await loadInclude(include.name, unit.filename, resolveInclude, searchPaths);
      if (loaded === undefined) {
        // `INCLUDE name IF FOUND.` is optional: a missing include is not an
        // error, but a resolvable one still has to participate in the
        // conversion so its content is not silently dropped.
        if (include.optional) continue;
        diagnostics.push(diagnostic({
          code: "GGCONV-E102",
          filename: unit.filename,
          start: linePosition(normalized.source, include.offset),
          construct: `INCLUDE ${include.name}`,
          message: `unable to resolve include ${include.name}`,
          suggestion: "Pass resolveInclude or make the include available beside the source file.",
          phase: "source-resolution",
        }));
        continue;
      }
      await visit({ ...loaded, hashKey: `INCLUDE ${include.name.toUpperCase()}` }, [...ancestry, unit.filename]);
    }
    active.pop();
  }

  await visit({ filename, source, hashKey: filename }, []);
  // Includes are usually found through absolute search paths, so they are
  // hashed by INCLUDE name; a path would differ per checkout and platform.
  const compilationInput = units.map((unit) => `${unit.hashKey}\0${unit.source}`).join("\0");
  const compilationHash = crypto.createHash("sha256").update(compilationInput, "utf8").digest("hex");
  return { units, diagnostics, systemIncludes, sourceHash: compilationHash, newline: normalizeSource(source).newline };
}
