import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "./api.mjs";
import { diagnostic, sortDiagnostics } from "./diagnostics.mjs";
import { conversionPlan, discoverPrograms, discoverTransactions } from "./config.mjs";

async function writeAtomically(filename, contents) {
  const temporary = `${filename}.tmp-${process.pid}`;
  await fs.writeFile(temporary, contents, "utf8");
  // rename replaces an existing file, so an interrupted run leaves the previous
  // output in place rather than a half-written one.
  await fs.rename(temporary, filename);
}

function collisionDiagnostics(converted) {
  const byClass = new Map();
  const diagnostics = [];
  for (const entry of converted) {
    const targetClass = entry.result.manifest?.targetClass ?? entry.result.reportIR?.targetClassName;
    if (!targetClass) continue;
    const first = byClass.get(targetClass);
    if (first === undefined) {
      byClass.set(targetClass, entry);
      continue;
    }
    diagnostics.push(diagnostic({
      code: "GGCONV-E115",
      filename: entry.program.filename,
      construct: targetClass,
      message: `target class ${targetClass} is produced by both ${first.program.relativePath} and ${entry.program.relativePath}`,
      suggestion: "Rename one of the reports, or pass an explicit class name for one of them.",
      phase: "batch",
    }));
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
 * Convert every program an abap_transpile.json selects.
 *
 * Writes go to `<output_folder>_converter`, which the converter owns: a full
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
  manifestFolder,
  onResult,
  converter = convertProgram,
} = {}) {
  const discovered = programs ?? await discoverPrograms(config);
  const targetFolder = outputFolder ? path.resolve(outputFolder) : config.generatedFolder;
  const targetManifestFolder = manifestFolder ? path.resolve(manifestFolder) : targetFolder;

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
  const converted = [];
  for (const program of discovered) {
    const plan = conversionPlan(config, program, { ...overrides, transactions });
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
    if (targetManifestFolder !== targetFolder) await fs.mkdir(targetManifestFolder, { recursive: true });
    for (const { result } of converted) {
      if (!result.classSource) continue;
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
      const manifestFile = outputFile
        ? `${classFile}.manifest.json`
        : path.join(targetManifestFolder, `${String(targetClass).toLowerCase()}.manifest.json`);
      await writeAtomically(manifestFile, `${JSON.stringify(result.manifest, null, 2)}\n`);
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
