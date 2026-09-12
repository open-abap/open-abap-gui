import { convertProgram } from "./api.mjs";
import { diagnostic, sortDiagnostics } from "./diagnostics.mjs";
import { normalizeObjectName } from "./options.mjs";

function previewDiagnostic(code, construct, message, suggestion, filename) {
  return diagnostic({
    code,
    filename: filename ?? "program.prog.abap",
    construct,
    message,
    suggestion,
    phase: "workbench-preview",
  });
}

function targetClassName(value) {
  try {
    return value ? normalizeObjectName(value, "target class") : undefined;
  } catch {
    return undefined;
  }
}

/**
 * Run the read-only conversion step a workbench adapter can use before it
 * offers generated source. The converter never receives a repository writer;
 * callers must explicitly opt into returning classSource after diagnostics
 * have been inspected.
 */
export async function previewProgram({
  source,
  filename = "program.prog.abap",
  className,
  transactionCode,
  description,
  existingClassNames = [],
  collisionConfirmed = false,
  includeSource = false,
  converter = convertProgram,
  ...options
} = {}) {
  const diagnostics = [];
  const normalizedClass = targetClassName(className);
  if (!normalizedClass) diagnostics.push(previewDiagnostic(
    "GGCONV-E601",
    "target class",
    "a valid target class name is required before conversion preview",
    "Supply an explicit className that satisfies the ABAP global-class naming rules.",
    filename,
  ));

  const existing = new Set(existingClassNames.map((name) => String(name).toUpperCase()));
  const collision = normalizedClass && existing.has(normalizedClass);
  if (collision && !collisionConfirmed) diagnostics.push(previewDiagnostic(
    "GGCONV-E602",
    normalizedClass,
    `target class ${normalizedClass} already exists and has not been explicitly confirmed`,
    "Confirm the collision in the workbench before offering generated source; preview itself never overwrites objects.",
    filename,
  ));

  let result;
  if (typeof source !== "string") {
    diagnostics.push(previewDiagnostic(
      "GGCONV-E603",
      "source",
      "conversion preview requires source text from a read-authorized repository adapter",
      "Read the source through the repository service and pass it to the preview endpoint.",
      filename,
    ));
  } else {
    result = await converter({
      ...options,
      source,
      filename,
      className: normalizedClass,
      transactionCode,
      description,
      mode: options.mode ?? "partial",
    });
    diagnostics.push(...(result.diagnostics ?? []));
  }

  const sorted = sortDiagnostics(diagnostics);
  const hasErrors = sorted.some((item) => item.severity === "error" || item.code.startsWith("GGCONV-E"));
  const sourceAvailable = Boolean(result?.classSource) && !hasErrors;
  return {
    kind: "conversion-preview",
    repositoryChanged: false,
    sourceFilename: filename,
    targetClassName: normalizedClass,
    collision,
    collisionConfirmed: Boolean(collisionConfirmed),
    diagnostics: sorted,
    capabilities: result?.reportIR?.capabilities ?? [],
    manifest: result?.manifest,
    supported: Boolean(result?.supported) && !hasErrors,
    sourceAvailable,
    classSource: includeSource && sourceAvailable ? result.classSource : undefined,
    sourceMap: includeSource && sourceAvailable ? result.sourceMap : [],
    reportIR: result?.reportIR,
    scaffoldIR: result?.scaffoldIR,
  };
}

/**
 * Resolve source through a read-only adapter and then run the same preview
 * contract. The adapter shape deliberately has no save/activate method.
 */
export async function previewRepositoryProgram({
  repository,
  program,
  ...options
} = {}) {
  if (!repository || typeof repository.getProgram !== "function") {
    return previewProgram({
      ...options,
      filename: options.filename ?? `${program ?? "program"}.prog.abap`,
      source: undefined,
    });
  }
  const record = await repository.getProgram(program);
  if (!record || typeof record.source !== "string") {
    return previewProgram({
      ...options,
      filename: options.filename ?? `${program ?? "program"}.prog.abap`,
      source: undefined,
    });
  }
  return previewProgram({
    ...options,
    filename: options.filename ?? record.filename ?? `${program}.prog.abap`,
    source: record.source,
  }).then((result) => ({
    ...result,
    repositoryRevision: record.revision,
  }));
}
