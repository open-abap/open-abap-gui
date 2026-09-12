import path from "node:path";

export const CONVERTER_VERSION = "0.1.0";
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

export function defaultClassName(programName) {
  const normalized = programName.toUpperCase();
  const match = REPORT_NAME.exec(normalized);
  if (match === null || normalized.includes("/")) {
    return undefined;
  }
  const candidate = `${match.groups.prefix}CL_${match.groups.rest}`;
  return SIMPLE_OBJECT.test(candidate) && candidate.length <= 30 ? candidate : undefined;
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
  return {
    ...options,
    filename,
    mode,
    partialStrategy,
    descriptionProvided: options.description !== undefined,
    description: options.description ?? "Converted executable report",
    configPath: options.configPath ?? "abaplint.jsonc",
    converterVersion: options.converterVersion ?? CONVERTER_VERSION,
    maxSourceBytes: options.maxSourceBytes ?? 5 * 1024 * 1024,
    maxSourceLines: options.maxSourceLines ?? 100_000,
    maxDurationMs: options.maxDurationMs ?? 30_000,
    resolveInclude: options.resolveInclude,
  };
}
