import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { diagnostic } from "./diagnostics.mjs";

function normalizeSource(source) {
  const withoutBom = source.replace(/^\uFEFF/, "");
  const newline = withoutBom.includes("\r\n") ? "\r\n" : "\n";
  return { source: withoutBom.replace(/\r\n?/g, "\n"), newline };
}

export function sourceHash(source) {
  return crypto.createHash("sha256").update(normalizeSource(source).source, "utf8").digest("hex");
}

function linePosition(source, offset) {
  const before = source.slice(0, Math.max(0, offset));
  const lastNewline = before.lastIndexOf("\n");
  return { line: (before.match(/\n/g) ?? []).length + 1, column: offset - lastNewline };
}

export function rangeFromOffsets(source, startOffset, endOffset) {
  return { start: linePosition(source, startOffset), end: linePosition(source, endOffset) };
}

// abapGit-serialised repositories store INCLUDE programs as `<name>.prog.abap`,
// so that suffix has to be tried alongside the `<name>.incl.abap` form.
const INCLUDE_SUFFIXES = ["", ".incl.abap", ".prog.abap"];

function includeCandidates(name, parentFilename, searchPaths = []) {
  const bases = [undefined, path.dirname(parentFilename), ...searchPaths];
  const candidates = bases.flatMap((base) => INCLUDE_SUFFIXES
    .map((suffix) => (base === undefined ? `${name}${suffix}` : path.join(base, `${name}${suffix}`))));
  return candidates.filter((value, index, values) => values.indexOf(value) === index);
}

async function loadInclude(name, parentFilename, resolver, includePaths) {
  if (typeof resolver === "function") {
    try {
      const result = await resolver(name, parentFilename);
      if (typeof result === "string") {
        return { filename: name, source: result };
      }
      if (result && typeof result.source === "string") {
        return { filename: result.filename ?? name, source: result.source };
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
const SYSTEM_INCLUDES = {
  ICON: { provided: true },
  COLOR: { provided: true },
  SYMBOL: { patterns: SYMBOL_ELEMENTS },
  LINE: { patterns: LINE_ELEMENTS },
  // <LIST> is <SYMBOL>, <ICON>, <LINE> and <COLOR> together.
  LIST: { patterns: [...SYMBOL_ELEMENTS, ...LINE_ELEMENTS] },
};

function stripLiteralsAndComments(line) {
  if (/^\s*\*/.test(line)) return "";
  return line
    .replace(/'(?:''|[^'])*'|`(?:``|[^`])*`|\|(?:\\.|[^|\\])*\|/g, " ")
    .split('"')[0];
}

// The constant of a skipped system include that generated source still
// references, as an unqualified name: a component such as ls_x-sym_y, an
// attribute behind -> or =>, or a name the program declares itself is not one.
export function systemIncludeUse(include, sources, declared = new Set()) {
  const pattern = new RegExp(`(?<![\\w\\-~>/])(?:${include.patterns.join("|")})`, "gi");
  for (const source of sources) {
    for (const line of String(source).split("\n")) {
      for (const match of stripLiteralsAndComments(line).matchAll(pattern)) {
        if (!declared.has(match[0].toUpperCase())) return match[0].toLowerCase();
      }
    }
  }
  return undefined;
}

function findIncludes(source) {
  const includes = [];
  // `[ \t]*` (not `\s*`) keeps the match anchored on the INCLUDE line: with the
  // `m` flag `\s` also matches newlines, which made the offset - and therefore
  // the diagnostic line - point at the preceding blank line.
  const pattern = /^[ \t]*INCLUDE\s+([^\s.]+)\s*(IF\s+FOUND)?\s*\./gim;
  for (const match of source.matchAll(pattern)) {
    includes.push({ name: match[1], optional: Boolean(match[2]), offset: match.index ?? 0 });
  }
  return includes;
}

export async function resolveSources({ source, filename, resolveInclude, includePaths }) {
  const searchPaths = (Array.isArray(includePaths) ? includePaths : []).filter((item) => typeof item === "string" && item);
  const diagnostics = [];
  const units = [];
  const systemIncludes = [];
  const seen = new Set();
  const active = [];

  async function visit(unit, ancestry) {
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
          systemIncludes.push({ name: system, patterns: SYSTEM_INCLUDES[system].patterns, filename: unit.filename, start: linePosition(normalized.source, include.offset) });
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
