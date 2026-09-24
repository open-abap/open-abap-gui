import fs from "node:fs/promises";
import path from "node:path";
import { diagnostic } from "./diagnostics.mjs";
import { parseTransactionXml } from "./dynpro-metadata.mjs";

export const DEFAULT_CONFIG_FILENAME = "abap_transpile.json";

const PROGRAM_SUFFIX = ".prog.abap";
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

// True when `inner` is `outer` or lies somewhere below it.
function isWithin(inner, outer) {
  const relative = path.relative(outer, inner);
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

function parseFolders(declared, key, root, filename, diagnostics) {
  const folders = typeof declared === "string" ? [declared] : declared;
  const resolved = [];
  if (!Array.isArray(folders) || folders.length === 0) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E112",
      declared === undefined
        ? `${key} is required; the converter has no sources to scan without it`
        : `${key} must be a folder name or a non-empty array of folder names`,
      `Add "${key.split(".").pop()}": ["src"] naming the folders that hold the ABAP sources.`,
      key,
    ));
    return resolved;
  }
  for (const entry of folders) {
    if (typeof entry !== "string" || entry.trim() === "") {
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E112",
        `${key} entries must be non-empty strings, got ${entry === null ? "null" : typeof entry}`,
        "Remove the entry or replace it with a folder name.",
        key,
      ));
      continue;
    }
    const folder = path.resolve(root, entry);
    if (!resolved.includes(folder)) resolved.push(folder);
  }
  return resolved;
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
    converterInputFolders: [],
    libs: [],
    generatedFolder: undefined,
    diagnostics,
    valid: false,
  };
}

/**
 * Read the transpiler configuration the converter shares with abap_transpile.
 *
 * The converter's own settings are the `converter` object: programs are found
 * in `converter.input_folder`, and the generated classes are written to
 * `converter.output_folder`, which the converter owns. The top-level
 * `input_folder` and `libs` are the transpiler's; the converter reads them only
 * to resolve INCLUDEs and to check that the transpiler compiles its output.
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

  const inputFolders = parseFolders(parsed.input_folder, "input_folder", root, filename, diagnostics);

  const converter = parsed.converter;
  let converterInputFolders = [];
  let generatedFolder;
  if (converter === null || typeof converter !== "object" || Array.isArray(converter)) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E118",
      converter === undefined
        ? "converter is required; it names the folders the converter reads programs from and writes classes to"
        : "converter must be an object",
      'Add "converter": { "input_folder": ["reports"], "output_folder": "generated" }.',
      "converter",
    ));
  } else {
    converterInputFolders = parseFolders(converter.input_folder, "converter.input_folder", root, filename, diagnostics);
    const declaredOutput = converter.output_folder;
    if (typeof declaredOutput !== "string" || declaredOutput.trim() === "") {
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E113",
        declaredOutput === undefined
          ? "converter.output_folder is required; it is where the generated classes are written"
          : "converter.output_folder must be a non-empty string",
        'Add "output_folder": "generated" to the converter object.',
        "converter.output_folder",
      ));
    } else {
      generatedFolder = path.resolve(root, withoutTrailingSeparator(declaredOutput.trim()));
    }
  }

  const libs = parseLibs(parsed.libs, filename, diagnostics);

  // A full run clears the generated folder, so it must not hold, or sit inside,
  // anything else the configuration names: that would delete sources. The one
  // expected overlap is the generated folder listed as a transpiler input.
  if (generatedFolder) {
    const clashes = [
      ...converterInputFolders.map((folder) => ({ folder, key: "converter.input_folder" })),
      ...inputFolders
        .filter((folder) => folder !== generatedFolder && !converterInputFolders.includes(folder))
        .map((folder) => ({ folder, key: "input_folder" })),
    ].filter(({ folder }) => isWithin(folder, generatedFolder) || isWithin(generatedFolder, folder));
    for (const { folder, key } of clashes) {
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E119",
        `converter.output_folder ${posix(path.relative(root, generatedFolder)) || "."} overlaps ${key} entry ${posix(path.relative(root, folder)) || "."}; the converter clears its output folder, which would delete those sources`,
        "Give the converter an output folder of its own, outside every input folder.",
        "converter.output_folder",
      ));
    }
  }

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

  const declaredFolders = [
    ...inputFolders.map((folder) => ({ folder, key: "input_folder" })),
    ...converterInputFolders.filter((folder) => !inputFolders.includes(folder)).map((folder) => ({ folder, key: "converter.input_folder" })),
  ];
  for (const { folder, key } of declaredFolders) {
    try {
      const stats = await fs.stat(folder);
      if (stats.isDirectory()) continue;
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E112",
        `${key} entry ${posix(path.relative(root, folder))} is not a directory`,
        "Name a directory that holds ABAP sources.",
        key,
      ));
    } catch {
      // The generated folder is created by the conversion run itself, so its
      // absence before the first run is expected and not a configuration error.
      if (folder === generatedFolder) continue;
      diagnostics.push(configDiagnostic(
        filename,
        "GGCONV-E112",
        `${key} entry ${posix(path.relative(root, folder))} does not exist`,
        "Correct the path; like abap_transpile, it is resolved against the working directory.",
        key,
      ));
    }
  }

  return {
    filename,
    root,
    inputFolders,
    converterInputFolders,
    libs,
    generatedFolder,
    diagnostics,
    valid: !diagnostics.some((item) => item.severity === "error"),
  };
}

async function collectProgramFiles(directory, generatedFolder, found, visited, suffix = PROGRAM_SUFFIX) {
  const resolved = path.resolve(directory);
  // The converter owns the generated folder; scanning it would feed its own
  // output back in as input on every run after the first.
  const skipped = [generatedFolder].flat().filter(Boolean).map((folder) => path.resolve(folder));
  if (skipped.includes(resolved)) return;
  const suffixes = [suffix].flat();
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
    else if (suffixes.some((item) => entry.name.toLowerCase().endsWith(item))) found.set(child, true);
  }
}

/**
 * Map each program to the transaction that starts it, read from the
 * `.tran.xml` files in the converter input folders. A program started by
 * several transactions gets the alphabetically first one, so the choice does
 * not depend on directory order. Unreadable files are skipped: a transaction
 * only supplies a default the converter could otherwise derive.
 */
export async function discoverTransactions(config) {
  const found = new Map();
  const visited = new Set();
  for (const folder of config.converterInputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited, TRANSACTION_SUFFIX);
  }
  const byProgram = new Map();
  for (const filename of [...found.keys()].sort((left, right) => left.localeCompare(right))) {
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

/**
 * Find the executable programs in the converter input folders, in a
 * deterministic order. The transpiler's input_filter and exclude_filter do not
 * apply: they select what abap_transpile compiles, and the converter input is
 * a folder of its own.
 */
export async function discoverPrograms(config) {
  const found = new Map();
  const visited = new Set();
  for (const folder of config.converterInputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited);
  }

  const selected = [...found.keys()]
    .sort((left, right) => left.localeCompare(right))
    .map((filename) => ({ filename, relativePath: posix(path.relative(config.root, filename)) }));

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

const GLOBAL_OBJECT_SUFFIXES = [".clas.abap", ".intf.abap"];

/**
 * Map the name of each global class and interface in the sources
 * abap_transpile compiles to its file, so a generated class cannot silently
 * take the place of one: two files for one class are accepted by abaplint,
 * which then compiles whichever it read first. The generated folder and
 * `skipFolders` are left out, as their classes are the converter's own output.
 * Interfaces are included because they share the class namespace.
 */
export async function discoverGlobalObjects(config, skipFolders = []) {
  const found = new Map();
  const visited = new Set();
  const skipped = [config.generatedFolder, ...skipFolders];
  for (const folder of [...(config.converterInputFolders ?? []), ...(config.inputFolders ?? []), ...(config.libraryFolders ?? [])]) {
    await collectProgramFiles(folder, skipped, found, visited, GLOBAL_OBJECT_SUFFIXES);
  }
  const objects = new Map();
  for (const filename of [...found.keys()].sort((left, right) => left.localeCompare(right))) {
    const basename = path.basename(filename);
    const suffix = GLOBAL_OBJECT_SUFFIXES.find((item) => basename.toLowerCase().endsWith(item));
    // abapGit writes a namespace /ABC/ as #abc#.
    const name = basename.slice(0, -suffix.length).replaceAll("#", "/").toUpperCase();
    if (!objects.has(name)) objects.set(name, filename);
  }
  return objects;
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
    // A report's includes sit next to it or among the sources the transpiler
    // compiles, so the converter input is searched first, then the rest.
    includePaths: [...new Set([
      ...(config.converterInputFolders ?? []),
      ...(config.inputFolders ?? []),
      ...(config.libraryFolders ?? []),
    ])],
    configPath: path.join(config.root, "abaplint.jsonc"),
    className: resolveOverride(className, program.programName),
    transactionCode: resolveOverride(transactionCode, program.programName) ?? transaction?.transactionCode,
    ...(resolvedDescription === undefined ? {} : { description: resolvedDescription }),
    mode: mode ?? "strict",
    ...(partialStrategy === undefined ? {} : { partialStrategy }),
    ...(ddicTypes === undefined ? {} : { ddicTypes }),
  };
}
