import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "./api.mjs";
import { diagnostic, sortDiagnostics } from "./diagnostics.mjs";
import { conversionPlan, discoverGlobalObjects, discoverIncludeFolders, discoverPrograms, discoverTransactions } from "./config.mjs";

async function writeAtomically(filename, contents) {
  const temporary = `${filename}.tmp-${process.pid}`;
  await fs.writeFile(temporary, contents, "utf8");
  // rename replaces an existing file, so an interrupted run leaves the previous
  // output in place rather than a half-written one.
  await fs.rename(temporary, filename);
}

// Helper classes count too: they are written to the same folder, and a helper
// name is derived from the first 24 characters of its target class.
function generatedClassNames(result) {
  const targetClass = result.manifest?.targetClass ?? result.reportIR?.targetClassName;
  return [targetClass, ...(result.helperSources ?? []).map((helper) => helper.className)]
    .filter(Boolean)
    .map((name) => String(name).toUpperCase());
}

function collisionDiagnostics(converted) {
  const byClass = new Map();
  const diagnostics = [];
  for (const entry of converted) {
    for (const className of generatedClassNames(entry.result)) {
      const first = byClass.get(className);
      if (first === undefined) {
        byClass.set(className, entry);
        continue;
      }
      diagnostics.push(diagnostic({
        code: "GGCONV-E115",
        filename: entry.program.filename,
        construct: className,
        message: `class ${className} is produced by both ${first.program.relativePath} and ${entry.program.relativePath}`,
        suggestion: "Rename one of the reports, or pass an explicit class name for one of them.",
        phase: "batch",
      }));
    }
  }
  return diagnostics;
}

async function runOne(converter, plan, fallbackStrategy) {
  if (fallbackStrategy !== "skeleton") return converter(plan);
  // Prefer the lowering that preserves supported statements; fall back to the
  // skeleton only when that cannot produce usable source.
  const probe = await converter({ ...plan, partialStrategy: "preserve" });
  const fatal = probe.diagnostics.some((item) => item.severity === "error");
  if (probe.classSource && !fatal) return probe;
  return converter({ ...plan, partialStrategy: "skeleton" });
}

/**
 * Convert every program in an abap_transpile.json's converter input folders.
 *
 * Writes go to `converter.output_folder`, which the converter owns: a full
 * run clears it first, so a class no current program produces cannot survive as
 * a stale transpiler input. Clearing is skipped for a subset run (`clear:
 * false`, what `--program` passes) because the classes it does not produce are
 * still current, and for a redirected run (`outputFolder`) because that folder
 * may be shared. Nothing is written at all when two programs claim one class.
 */
export async function convertConfiguredPrograms({
  config,
  programs,
  overrides = {},
  fallbackStrategy,
  write = true,
  clear = true,
  outputFolder,
  outputFile,
  onResult,
  converter = convertProgram,
} = {}) {
  const discovered = programs ?? await discoverPrograms(config);
  const targetFolder = outputFolder ? path.resolve(outputFolder) : config.generatedFolder;

  if (outputFile && discovered.length > 1) {
    return {
      programs: [],
      supportedCount: 0,
      diagnostics: [diagnostic({
        code: "GGCONV-E116",
        filename: config.filename,
        construct: "--output",
        message: `--output writes a single class but ${discovered.length} programs were selected`,
        suggestion: "Narrow the run with --program, or use --output-folder.",
        phase: "batch",
      })],
    };
  }

  const transactions = overrides.transactions ?? await discoverTransactions(config);
  const includeFolders = overrides.includeFolders ?? await discoverIncludeFolders(config);
  // What this run writes replaces the files it is written over, so the target
  // folder and the --output file are not existing classes.
  const globalObjects = await discoverGlobalObjects(config, [targetFolder]);
  const replaced = outputFile ? path.resolve(outputFile) : undefined;
  const existing = [...globalObjects].filter(([, filename]) => filename !== replaced);
  const existingClassNames = [...new Set([...(overrides.existingClassNames ?? []), ...existing.map(([name]) => name)])];
  // Named in GGCONV-W106 when a default class name is taken.
  const existingClassFiles = {
    ...Object.fromEntries(existing.map(([name, filename]) => [name, path.relative(config.root, filename).replaceAll("\\", "/")])),
    ...(overrides.existingClassFiles ?? {}),
  };
  const converted = [];
  for (const program of discovered) {
    const plan = conversionPlan(config, program, { ...overrides, transactions, includeFolders, existingClassNames, existingClassFiles });
    const result = await runOne(converter, plan, fallbackStrategy);
    converted.push({ program, result });
    if (typeof onResult === "function") await onResult({ program, result });
  }

  const diagnostics = collisionDiagnostics(converted);

  // Two programs mapping to one class would write one file and silently lose
  // the other, so nothing is written until the collision is resolved.
  if (write && diagnostics.length) write = false;

  if (write && converted.length) {
    // Clearing is only correct when this run produces the whole set. A caller
    // converting a subset would otherwise delete output that is still current.
    if (clear && !outputFile && targetFolder === config.generatedFolder) {
      await fs.rm(targetFolder, { recursive: true, force: true });
    }
    await fs.mkdir(outputFile ? path.dirname(path.resolve(outputFile)) : targetFolder, { recursive: true });
    for (const { result } of converted) {
      if (!result.classSource) continue;
      // Partial mode still emits an explicitly named class whose name is taken
      // (GGCONV-E106; a default name is renamed instead, GGCONV-W106);
      // writing it would put a second definition of that class in the build.
      if (result.diagnostics.some((item) => item.code === "GGCONV-E106")) continue;
      const targetClass = result.manifest?.targetClass ?? result.reportIR?.targetClassName;
      const classFile = outputFile
        ? path.resolve(outputFile)
        : path.join(targetFolder, `${String(targetClass).toLowerCase()}.clas.abap`);
      await writeAtomically(classFile, result.classSource);
      for (const helper of result.helperSources ?? []) {
        await writeAtomically(
          path.join(path.dirname(classFile), `${helper.className.toLowerCase()}.clas.abap`),
          helper.source,
        );
      }
    }
  }

  const programSummaries = converted.map(({ program, result }) => ({
    filename: program.relativePath,
    programName: program.programName,
    targetClass: result.manifest?.targetClass ?? result.reportIR?.targetClassName,
    transactionCode: result.manifest?.transactionCode ?? result.reportIR?.transactionCode,
    supported: result.supported,
    programKind: result.reportIR?.programKind,
    capabilities: result.reportIR?.capabilities ?? [],
    diagnostics: result.diagnostics,
  }));

  return {
    programs: programSummaries,
    results: converted,
    supportedCount: programSummaries.filter((item) => item.supported).length,
    diagnostics: sortDiagnostics(diagnostics),
    outputFolder: write ? targetFolder : undefined,
  };
}
