import fs from "node:fs/promises";
import path from "node:path";
import { diagnostic } from "./diagnostics.mjs";
import { parseTransactionXml } from "./dynpro-metadata.mjs";

export const DEFAULT_CONFIG_FILENAME = "abap_transpile.json";
export const GENERATED_FOLDER_SUFFIX = "_converter";

const PROGRAM_SUFFIX = ".prog.abap";
const CLASS_SUFFIX = ".clas.abap";
const TRANSACTION_SUFFIX = ".tran.xml";

// The program name has to be known before conversion so a caller-supplied
// className(programName) callback can run, so it is read with a regexp here
// rather than taken from classifyProgram. The conversion result remains
// authoritative for programKind; an INCLUDE serialised as `<name>.prog.abap`
// simply has no REPORT/PROGRAM header and is therefore not an entry point.
const ENTRY_POINT = /^[ \t]*(?:REPORT|PROGRAM)\s+([A-Za-z0-9_/]+)/m;

function configDiagnostic(filename, code, message, suggestion, construct = "abap_transpile.json") {
  return diagnostic({ code, filename, construct, message, suggestion, phase: "config" });
}

function posix(value) {
  return String(value).replaceAll("\\", "/");
}

function withoutTrailingSeparator(value) {
  return String(value).replace(/[\\/]+$/, "");
}

function compileFilters(values, key, filename, diagnostics) {
  const list = values === undefined ? [] : values;
  if (!Array.isArray(list)) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E114",
      `${key} must be an array of regular expressions`,
      `Use "${key}": [] to match every file.`,
      key,
    ));
    return [];
  }
  const compiled = [];
  for (const entry of list) {
    if (typeof entry !== "string") {
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E114",
        `${key} entries must be strings, got ${entry === null ? "null" : typeof entry}`,
        "Remove the entry or write it as a regular expression string.",
        key,
      ));
      continue;
    }
    try {
      compiled.push(new RegExp(entry, "i"));
    } catch (error) {
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E114",
        `${key} entry ${JSON.stringify(entry)} is not a valid regular expression: ${error.message}`,
        "Escape the regular expression metacharacters or correct the pattern.",
        key,
      ));
    }
  }
  return compiled;
}

// The same shape abap_transpile accepts: each lib is read from `folder` when
// that exists, otherwise cloned from `url`. Cloning happens in loadLibraries,
// not here, so reading a configuration never touches the network.
function parseLibs(declared, filename, diagnostics) {
  if (declared === undefined) return [];
  if (!Array.isArray(declared)) {
    diagnostics.push(configDiagnostic(filename, "GGCONV-E117", "libs must be an array of libraries", 'Use "libs": [{ "url": "https://github.com/..." }].', "libs"));
    return [];
  }
  const libs = [];
  for (const entry of declared) {
    if (entry === null || typeof entry !== "object" || Array.isArray(entry)) {
      diagnostics.push(configDiagnostic(filename, "GGCONV-E117", "libs entries must be objects", 'Write the entry as { "url": "..." } or { "folder": "..." }.', "libs"));
      continue;
    }
    const url = typeof entry.url === "string" && entry.url !== "" ? entry.url : undefined;
    const folder = typeof entry.folder === "string" && entry.folder !== "" ? entry.folder : undefined;
    if (url === undefined && folder === undefined) {
      diagnostics.push(configDiagnostic(filename, "GGCONV-E117", "a lib must define a non-empty url or folder", "Add the repository url, or the folder it is checked out in.", "libs"));
      continue;
    }
    let files = ["/src/**"];
    if (typeof entry.files === "string" && entry.files !== "") files = [entry.files];
    else if (Array.isArray(entry.files)) files = entry.files.filter((item) => typeof item === "string" && item !== "");
    libs.push({
      url,
      folder,
      files,
      excludeFilters: compileFilters(entry.exclude_filter, "libs exclude_filter", filename, diagnostics),
    });
  }
  return libs;
}

function emptyConfig(filename, root, diagnostics) {
  return {
    filename,
    root,
    inputFolders: [],
    inputFilters: [],
    excludeFilters: [],
    libs: [],
    outputFolder: undefined,
    generatedFolder: undefined,
    diagnostics,
    valid: false,
  };
}

/**
 * Read the transpiler configuration the converter shares with abap_transpile.
 *
 * The file is read, never written, and never validated beyond the keys the
 * converter itself needs: an unknown key belongs to a newer transpiler and is
 * ignored rather than rejected. Problems are returned as diagnostics so a
 * caller can report them the same way it reports conversion diagnostics.
 *
 * Folder names are resolved against the working directory, not against the
 * configuration file, because that is what abap_transpile does: it globs
 * `<input_folder>/**` from process.cwd(). The checked-in gg-gui configuration
 * relies on it — the file sits in converter/gg-gui-validation/ while its
 * input_folder names `src` at the repository root. Resolving the two tools'
 * paths differently would make one file mean two different things.
 */
export async function loadTranspileConfig(configPath = DEFAULT_CONFIG_FILENAME, { cwd = process.cwd() } = {}) {
  const root = path.resolve(cwd);
  const filename = path.resolve(root, configPath);
  const diagnostics = [];

  let raw;
  try {
    raw = await fs.readFile(filename, "utf8");
  } catch (error) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E110",
      `unable to read transpiler configuration: ${error.message}`,
      "Pass --config with the path to an abap_transpile.json file.",
    ));
    return emptyConfig(filename, root, diagnostics);
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E111",
      `transpiler configuration is not valid JSON: ${error.message}`,
      "abap_transpile.json is strict JSON; comments and trailing commas are not allowed.",
    ));
    return emptyConfig(filename, root, diagnostics);
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E111",
      `transpiler configuration must be a JSON object, got ${Array.isArray(parsed) ? "an array" : typeof parsed}`,
      "Wrap the settings in a single JSON object.",
    ));
    return emptyConfig(filename, root, diagnostics);
  }

  const declared = parsed.input_folder;
  const folders = typeof declared === "string" ? [declared] : declared;
  const inputFolders = [];
  if (!Array.isArray(folders) || folders.length === 0) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E112",
      declared === undefined
        ? "input_folder is required; the converter has no sources to scan without it"
        : "input_folder must be a folder name or a non-empty array of folder names",
      'Add "input_folder": ["src"] naming the folders that hold the ABAP sources.',
      "input_folder",
    ));
  } else {
    for (const entry of folders) {
      if (typeof entry !== "string" || entry.trim() === "") {
        diagnostics.push(configDiagnostic(
          filename,
          "GGCONV-E112",
          `input_folder entries must be non-empty strings, got ${entry === null ? "null" : typeof entry}`,
          "Remove the entry or replace it with a folder name.",
          "input_folder",
        ));
        continue;
      }
      const resolved = path.resolve(root, entry);
      if (!inputFolders.includes(resolved)) inputFolders.push(resolved);
    }
  }

  const declaredOutput = parsed.output_folder;
  let outputFolder;
  let generatedFolder;
  if (typeof declaredOutput !== "string" || declaredOutput.trim() === "") {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E113",
      declaredOutput === undefined
        ? "output_folder is required; the converter derives its own output folder from it"
        : "output_folder must be a non-empty string",
      'Add "output_folder": "output"; the converter writes to "output_converter".',
      "output_folder",
    ));
  } else {
    const trimmed = withoutTrailingSeparator(declaredOutput.trim());
    outputFolder = path.resolve(root, trimmed);
    generatedFolder = path.resolve(root, `${trimmed}${GENERATED_FOLDER_SUFFIX}`);
  }

  const inputFilters = compileFilters(parsed.input_filter, "input_filter", filename, diagnostics);
  const excludeFilters = compileFilters(parsed.exclude_filter, "exclude_filter", filename, diagnostics);
  const libs = parseLibs(parsed.libs, filename, diagnostics);

  // The generated classes are only compiled if the transpiler also reads them,
  // which it does only when the folder is one of its input folders. The
  // converter cannot edit the config, so it reports the exact entry to add.
  if (generatedFolder && inputFolders.length && !inputFolders.includes(generatedFolder)) {
    diagnostics.push(diagnostic({
      code: "GGCONV-W110",
      severity: "warning",
      filename,
      construct: "input_folder",
      message: `generated classes are written to ${posix(path.relative(root, generatedFolder)) || posix(generatedFolder)} but that folder is not listed in input_folder, so abap_transpile will not compile them`,
      suggestion: `Add "${posix(path.relative(root, generatedFolder))}" to input_folder.`,
      phase: "config",
    }));
  }

  for (const folder of inputFolders) {
    try {
      const stats = await fs.stat(folder);
      if (stats.isDirectory()) continue;
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E112",
        `input_folder entry ${posix(path.relative(root, folder))} is not a directory`,
        "Name a directory that holds ABAP sources.",
        "input_folder",
      ));
    } catch {
      // The generated folder is created by the conversion run itself, so its
      // absence before the first run is expected and not a configuration error.
      if (folder === generatedFolder) continue;
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E112",
        `input_folder entry ${posix(path.relative(root, folder))} does not exist`,
        "Correct the path; like abap_transpile, it is resolved against the working directory.",
        "input_folder",
      ));
    }
  }

  return {
    filename,
    root,
    inputFolders,
    inputFilters,
    excludeFilters,
    libs,
    outputFolder,
    generatedFolder,
    diagnostics,
    valid: !diagnostics.some((item) => item.severity === "error"),
  };
}

async function collectProgramFiles(directory, generatedFolder, found, visited, suffix = PROGRAM_SUFFIX) {
  const resolved = path.resolve(directory);
  // The converter owns the generated folder; scanning it would feed its own
  // output back in as input on every run after the first.
  if (generatedFolder && resolved === generatedFolder) return;
  if (visited.has(resolved)) return;
  visited.add(resolved);
  let entries;
  try {
    entries = await fs.readdir(resolved, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    const child = path.join(resolved, entry.name);
    if (entry.isDirectory()) await collectProgramFiles(child, generatedFolder, found, visited, suffix);
    else if (entry.name.toLowerCase().endsWith(suffix)) found.set(child, true);
  }
}

/**
 * Name every global class the transpiler compiles alongside the converted
 * programs: the `.clas.abap` files the input folders and filters select, plus
 * the classes the libs provide. A method call to one of them compiles unchanged
 * in the generated class. The generated folder is skipped, so the result does
 * not depend on the output of an earlier run.
 */
export async function discoverGlobalClassNames(config) {
  const found = new Map();
  const visited = new Set();
  for (const folder of config.inputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited, CLASS_SUFFIX);
  }
  const names = new Set(config.libraryClassNames ?? []);
  for (const filename of found.keys()) {
    const candidate = posix(filename);
    if (config.inputFilters?.length && !config.inputFilters.some((item) => item.test(candidate))) continue;
    if (config.excludeFilters?.some((item) => item.test(candidate))) continue;
    names.add(classNameFromFilename(filename));
  }
  return [...names].sort();
}

/**
 * Map each program to the transaction that starts it, read from the
 * `.tran.xml` files the input folders and filters select. A program started by
 * several transactions gets the alphabetically first one, so the choice does
 * not depend on directory order. Unreadable files are skipped: a transaction
 * only supplies a default the converter could otherwise derive.
 */
export async function discoverTransactions(config) {
  const found = new Map();
  const visited = new Set();
  for (const folder of config.inputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited, TRANSACTION_SUFFIX);
  }
  const byProgram = new Map();
  for (const filename of [...found.keys()].sort((left, right) => left.localeCompare(right))) {
    const candidate = posix(filename);
    if (config.inputFilters?.length && !config.inputFilters.some((item) => item.test(candidate))) continue;
    if (config.excludeFilters?.some((item) => item.test(candidate))) continue;
    let transaction;
    try {
      transaction = parseTransactionXml(await fs.readFile(filename, "utf8"));
    } catch {
      continue;
    }
    if (!transaction) continue;
    const current = byProgram.get(transaction.program);
    if (!current || transaction.transactionCode < current.transactionCode) byProgram.set(transaction.program, transaction);
  }
  return byProgram;
}

export function classNameFromFilename(filename) {
  return path.basename(filename).slice(0, -CLASS_SUFFIX.length).replaceAll("#", "/").toUpperCase();
}

/**
 * Find the executable programs the configuration selects, in a deterministic
 * order. Filters are matched against the path relative to the configuration
 * file, with forward slashes, so a pattern can name a file or a folder.
 */
export async function discoverPrograms(config) {
  const found = new Map();
  const visited = new Set();
  for (const folder of config.inputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited);
  }

  const selected = [];
  for (const filename of [...found.keys()].sort((left, right) => left.localeCompare(right))) {
    // abap_transpile globs with { absolute: true, posix: true } and tests its
    // filters against that, so the same pattern has to select the same files
    // here. The relative path is for reporting only.
    const candidate = posix(filename);
    if (config.inputFilters?.length && !config.inputFilters.some((item) => item.test(candidate))) continue;
    if (config.excludeFilters?.some((item) => item.test(candidate))) continue;
    selected.push({ filename, relativePath: posix(path.relative(config.root, filename)) });
  }

  const programs = [];
  for (const entry of selected) {
    let source;
    try {
      source = await fs.readFile(entry.filename, "utf8");
    } catch {
      continue;
    }
    const programName = ENTRY_POINT.exec(source)?.[1]?.toUpperCase();
    if (!programName) continue;
    programs.push({ ...entry, source, programName });
  }
  return programs;
}

function resolveOverride(value, programName) {
  return typeof value === "function" ? value(programName) : value;
}

/**
 * Build the convertProgram input for one discovered program. This is the only
 * place option precedence is decided: an explicit override wins, otherwise the
 * value is derived from the configuration or left to the converter's defaults.
 */
export function conversionPlan(config, program, overrides = {}) {
  const {
    className,
    transactionCode,
    description,
    mode,
    partialStrategy,
    ddicTypes,
    transactions,
    ...rest
  } = overrides;
  // A transaction object that starts this program names its transaction code
  // and short text, ahead of what the converter would derive from the name.
  const transaction = transactions?.get(program.programName);
  const explicitDescription = resolveOverride(description, program.programName);
  const resolvedDescription = explicitDescription ?? transaction?.description;
  return {
    ...rest,
    // The filename is recorded in the generated class header and feeds the
    // compilation hash, so it must not be an absolute path: that would bake a
    // machine-specific string into generated ABAP and give the same source a
    // different hash on every checkout. Metadata discovery is anchored on the
    // absolute path separately, so it does not depend on the working directory.
    filename: program.relativePath ?? program.filename,
    source: program.source,
    dynproMetadataFilename: program.filename.replace(/\.prog\.abap$/i, ".prog.xml"),
    dynproScreenDirectory: path.dirname(program.filename),
    includePaths: [...config.inputFolders, ...(config.libraryFolders ?? [])],
    configPath: path.join(config.root, "abaplint.jsonc"),
    className: resolveOverride(className, program.programName),
    transactionCode: resolveOverride(transactionCode, program.programName) ?? transaction?.transactionCode,
    ...(resolvedDescription === undefined ? {} : { description: resolvedDescription }),
    mode: mode ?? "strict",
    ...(partialStrategy === undefined ? {} : { partialStrategy }),
    ...(ddicTypes === undefined ? {} : { ddicTypes }),
  };
}
