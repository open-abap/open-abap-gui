import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { diagnostic } from "./diagnostics.mjs";

export function normalizeSource(source) {
  const withoutBom = source.replace(/^\uFEFF/, "");
  const newline = withoutBom.includes("\r\n") ? "\r\n" : "\n";
  return { source: withoutBom.replace(/\r\n?/g, "\n"), newline };
}

export function sourceHash(source) {
  return crypto.createHash("sha256").update(normalizeSource(source).source, "utf8").digest("hex");
}

export function linePosition(source, offset) {
  const before = source.slice(0, Math.max(0, offset));
  const lastNewline = before.lastIndexOf("\n");
  return { line: (before.match(/\n/g) ?? []).length + 1, column: offset - lastNewline };
}

export function rangeFromOffsets(source, startOffset, endOffset) {
  return { start: linePosition(source, startOffset), end: linePosition(source, endOffset) };
}

function includeCandidates(name, parentFilename) {
  const base = path.dirname(parentFilename);
  return [name, `${name}.incl.abap`, path.join(base, name), path.join(base, `${name}.incl.abap`)].filter(
    (value, index, values) => values.indexOf(value) === index,
  );
}

async function loadInclude(name, parentFilename, resolver) {
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
  for (const candidate of includeCandidates(name, parentFilename)) {
    try {
      return { filename: candidate, source: await fs.readFile(candidate, "utf8") };
    } catch {
      // Try the next deterministic candidate.
    }
  }
  return undefined;
}

function findIncludes(source) {
  const includes = [];
  const pattern = /^\s*INCLUDE\s+([^\s.]+)\s*\./gim;
  for (const match of source.matchAll(pattern)) {
    includes.push({ name: match[1], offset: match.index ?? 0 });
  }
  return includes;
}

export async function resolveSources({ source, filename, resolveInclude }) {
  const diagnostics = [];
  const units = [];
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
    units.push({ filename: unit.filename, source: normalized.source, newline: normalized.newline, ancestry });
    for (const include of findIncludes(normalized.source)) {
      const loaded = await loadInclude(include.name, unit.filename, resolveInclude);
      if (loaded === undefined) {
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
      await visit(loaded, [...ancestry, unit.filename]);
    }
    active.pop();
  }

  await visit({ filename, source }, []);
  const compilationInput = units.map((unit) => `${unit.filename}\0${unit.source}`).join("\0");
  const compilationHash = crypto.createHash("sha256").update(compilationInput, "utf8").digest("hex");
  return { units, diagnostics, sourceHash: compilationHash, newline: normalizeSource(source).newline };
}
