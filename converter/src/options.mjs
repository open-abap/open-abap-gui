import { createHash } from "node:crypto";
import { createRequire } from "node:module";
import path from "node:path";

export const CONVERTER_VERSION = createRequire(import.meta.url)("../package.json").version;
export const MANIFEST_SCHEMA_VERSION = 1;

const REPORT_NAME = /^(?<prefix>[ZY])(?<rest>[A-Z0-9_]+)$/i;
const SIMPLE_OBJECT = /^[A-Z][A-Z0-9_]{0,29}$/;
const NAMESPACED_OBJECT = /^\/[A-Z0-9_$]{1,10}\/[A-Z][A-Z0-9_]{0,29}$/;

export function normalizeObjectName(value, kind = "object") {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${kind} name is required`);
  }
  const normalized = value.trim().toUpperCase();
  const valid = normalized.includes("/") ? NAMESPACED_OBJECT : SIMPLE_OBJECT;
  if (!valid.test(normalized) || normalized.length > 30) {
    throw new Error(`invalid ${kind} name "${value}" (ABAP object names are at most 30 characters)`);
  }
  return normalized;
}

// The class name the report name implies, before it is fitted to 30 characters.
export function fullClassName(programName) {
  const normalized = programName.toUpperCase();
  const match = REPORT_NAME.exec(normalized);
  if (match === null || normalized.includes("/")) {
    return undefined;
  }
  return `${match.groups.prefix}CL_${match.groups.rest}`;
}

// A program name may have 40 characters and a class name only 30, so a long
// report name is cut down. Cutting alone would map names that differ only in
// their tail, such as ..._PROMO and ..._PROMO2, to one class; a hash of the
// full program name keeps them apart and gives the same name on every run.
export function defaultClassName(programName) {
  const candidate = fullClassName(programName);
  if (candidate === undefined) return undefined;
  if (candidate.length <= 30) return SIMPLE_OBJECT.test(candidate) ? candidate : undefined;
  const hash = createHash("sha1").update(programName.toUpperCase()).digest("hex").slice(0, 4).toUpperCase();
  const shortened = `${candidate.slice(0, 25).replace(/_+$/, "")}_${hash}`;
  return SIMPLE_OBJECT.test(shortened) ? shortened : undefined;
}

export function defaultTransactionCode(programName) {
  const normalized = programName.toUpperCase();
  return /^[A-Z0-9_]{1,20}$/.test(normalized) ? normalized : undefined;
}

export function normalizeTransactionCode(value) {
  if (typeof value !== "string" || !/^[A-Z0-9_\/]{1,20}$/i.test(value.trim())) {
    throw new Error(`invalid transaction code "${value}" (use at most 20 letters, digits, underscores, or namespace separators)`);
  }
  return value.trim().toUpperCase();
}

export function normalizeOptions(options = {}) {
  const mode = options.mode ?? "strict";
  if (mode !== "strict" && mode !== "partial") {
    throw new Error(`mode must be strict or partial, got ${mode}`);
  }
  const partialStrategy = options.partialStrategy ?? "preserve";
  if (partialStrategy !== "preserve" && partialStrategy !== "skeleton") {
    throw new Error(`partialStrategy must be preserve or skeleton, got ${partialStrategy}`);
  }
  const filename = (options.filename ? path.normalize(options.filename) : "program.prog.abap").replaceAll("\\", "/");
  if (options.source !== undefined && typeof options.source !== "string") {
    throw new Error("source must be a string when supplied");
  }
  if (options.language !== undefined && (typeof options.language !== "string" || !/^[A-Za-z0-9]$/.test(options.language))) {
    throw new Error(`language must be a one-character SAP language key, got ${options.language}`);
  }
  return {
    ...options,
    filename,
    ...(options.language === undefined ? {} : { language: options.language.toUpperCase() }),
    mode,
    partialStrategy,
    descriptionProvided: options.description !== undefined,
    configPath: options.configPath ?? "abaplint.jsonc",
    converterVersion: options.converterVersion ?? CONVERTER_VERSION,
    maxSourceBytes: options.maxSourceBytes ?? 5 * 1024 * 1024,
    maxSourceLines: options.maxSourceLines ?? 100_000,
    maxDurationMs: options.maxDurationMs ?? 30_000,
    resolveInclude: options.resolveInclude,
  };
}
