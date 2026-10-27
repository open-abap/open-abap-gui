import fs from "node:fs/promises";
import path from "node:path";
import { Statements } from "@abaplint/core";
import { lexedAst } from "./abap/ast.js";
import { diagnostic } from "./diagnostics.js";
import { parseTransactionXml } from "./dynpro-metadata.js";
import type { Transaction } from "./dynpro-metadata.js";
import type { ConvertOptions, Diagnostic } from "./types.js";

export interface LibraryConfig {
  url: string | undefined;
  folder: string | undefined;
  files: string[];
  excludeFilters: RegExp[];
}

/** The converter's view of an abap_transpile.json. */
export interface TranspileConfig {
  filename: string;
  root: string;
  inputFolders: string[];
  converterInputFolders: string[];
  converterExcludeFilters: RegExp[];
  libs: LibraryConfig[];
  generatedFolder: string | undefined;
  language?: string;
  modulePools?: boolean;
  diagnostics: Diagnostic[];
  valid: boolean;
  /** The include folders of the libs, set by the caller after loadLibraries. */
  libraryFolders?: string[];
}

/** A program found in the converter input folders. */
export interface DiscoveredProgram {
  filename: string;
  relativePath: string;
  source: string;
  programName: string;
}

type PerProgram<T> = T | ((programName: string) => T | undefined);

/** Values that override what the configuration and the converter derive. */
export interface ConversionOverrides extends Omit<ConvertOptions, "className" | "transactionCode" | "description"> {
  className?: PerProgram<string>;
  transactionCode?: PerProgram<string>;
  description?: PerProgram<string>;
  transactions?: Map<string, Transaction>;
  includeFolders?: string[];
}

export const DEFAULT_CONFIG_FILENAME = "abap_transpile.json";

const PROGRAM_SUFFIX = ".prog.abap";
const TRANSACTION_SUFFIX = ".tran.xml";

// As in SAP, the object decides the program name: `<name>.prog.abap`. The name
// in the REPORT statement is irrelevant; a copied report keeps its original's,
// and a program whose REPORT sits in its TOP include has none of its own.
// Whether the object is an entry point is its program type, SUBC in the
// .prog.xml: executable programs (1) are converted, module pools (M) only with
// converter.module_pools, includes (I) and subroutine pools (S) never. Only a
// program without a .prog.xml falls back to the source, and counts as an entry
// point when it has a REPORT/PROGRAM statement of its own.
function isEntryPoint(source: string): boolean {
  return (lexedAst(source)?.statements ?? []).some((statement) => statement.get() instanceof Statements.Report || statement.get() instanceof Statements.Program);
}

function configDiagnostic(filename: string, code: string, message: string, suggestion: string, construct = "abap_transpile.json"): Diagnostic {
  return diagnostic({ code, filename, construct, message, suggestion, phase: "config" });
}

function posix(value: string): string {
  return String(value).replaceAll("\\", "/");
}

function withoutTrailingSeparator(value: string): string {
  return String(value).replace(/[\\/]+$/, "");
}

// True when `inner` is `outer` or lies somewhere below it.
function isWithin(inner: string, outer: string): boolean {
  const relative = path.relative(outer, inner);
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

function parseFolders(declared: unknown, key: string, root: string, filename: string, diagnostics: Diagnostic[]): string[] {
  const folders = typeof declared === "string" ? [declared] : declared;
  const resolved: string[] = [];
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

function compileFilters(values: unknown, key: string, filename: string, diagnostics: Diagnostic[]): RegExp[] {
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
  const compiled: RegExp[] = [];
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
        `${key} entry ${JSON.stringify(entry)} is not a valid regular expression: ${(error as Error).message}`,
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
function parseLibs(declared: unknown, filename: string, diagnostics: Diagnostic[]): LibraryConfig[] {
  if (declared === undefined) return [];
  if (!Array.isArray(declared)) {
    diagnostics.push(configDiagnostic(filename, "GGCONV-E117", "libs must be an array of libraries", 'Use "libs": [{ "url": "https://github.com/..." }].', "libs"));
    return [];
  }
  const libs: LibraryConfig[] = [];
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
    else if (Array.isArray(entry.files)) files = entry.files.filter((item: unknown) => typeof item === "string" && item !== "");
    libs.push({
      url,
      folder,
      files,
      excludeFilters: compileFilters(entry.exclude_filter, "libs exclude_filter", filename, diagnostics),
    });
  }
  return libs;
}

function emptyConfig(filename: string, root: string, diagnostics: Diagnostic[]): TranspileConfig {
  return {
    filename,
    root,
    inputFolders: [],
    converterInputFolders: [],
    converterExcludeFilters: [],
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
export async function loadTranspileConfig(configPath = DEFAULT_CONFIG_FILENAME, { cwd = process.cwd() }: { cwd?: string } = {}): Promise<TranspileConfig> {
  const root = path.resolve(cwd);
  const filename = path.resolve(root, configPath);
  const diagnostics: Diagnostic[] = [];

  let raw;
  try {
    raw = await fs.readFile(filename, "utf8");
  } catch (error) {
    diagnostics.push(configDiagnostic(
      filename,
      "GGCONV-E110",
      `unable to read transpiler configuration: ${(error as Error).message}`,
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
      `transpiler configuration is not valid JSON: ${(error as Error).message}`,
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
  let converterInputFolders: string[] = [];
  let converterExcludeFilters: RegExp[] = [];
  let generatedFolder: string | undefined;
  let language: string | undefined;
  let modulePools = false;
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
    converterExcludeFilters = compileFilters(converter.exclude_filter, "converter.exclude_filter", filename, diagnostics);
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
    if (converter.language !== undefined) {
      if (typeof converter.language === "string" && /^[A-Za-z0-9]$/.test(converter.language)) {
        language = converter.language.toUpperCase();
      } else {
        diagnostics.push(configDiagnostic(
          filename,
          "GGCONV-E120",
          "converter.language must be a one-character SAP language key",
          'Use the key abapGit writes, such as "E" or "D", or leave it out.',
          "converter.language",
        ));
      }
    }
    if (converter.module_pools !== undefined) {
      if (typeof converter.module_pools === "boolean") {
        modulePools = converter.module_pools;
      } else {
        diagnostics.push(configDiagnostic(
          filename,
          "GGCONV-E121",
          "converter.module_pools must be true or false",
          "Set it to true to convert module pools (SUBC M), or leave it out.",
          "converter.module_pools",
        ));
      }
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
    converterExcludeFilters,
    libs,
    generatedFolder,
    ...(language === undefined ? {} : { language }),
    modulePools,
    diagnostics,
    valid: !diagnostics.some((item) => item.severity === "error"),
  };
}

async function collectProgramFiles(directory: string, generatedFolder: string | (string | undefined)[] | undefined, found: Map<string, boolean>, visited: Set<string>, suffix: string | string[] = PROGRAM_SUFFIX): Promise<void> {
  const resolved = path.resolve(directory);
  // The converter owns the generated folder; scanning it would feed its own
  // output back in as input on every run after the first.
  const skipped = [generatedFolder].flat().filter((folder): folder is string => Boolean(folder)).map((folder) => path.resolve(folder));
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
export async function discoverTransactions(config: TranspileConfig): Promise<Map<string, Transaction>> {
  const found = new Map<string, boolean>();
  const visited = new Set<string>();
  for (const folder of config.converterInputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited, TRANSACTION_SUFFIX);
  }
  const byProgram = new Map<string, Transaction>();
  for (const filename of [...found.keys()].sort((left, right) => left.localeCompare(right))) {
    let transaction;
    try {
      transaction = parseTransactionXml(await fs.readFile(filename, "utf8"), { language: config.language });
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
 * a folder of its own. `converter.exclude_filter` drops programs instead; like
 * the transpiler's filter, it is matched against the path relative to the
 * working directory, such as `src/zfoo.prog.abap`. An excluded program is
 * still searched for INCLUDEs, it is only not converted.
 */
export async function discoverPrograms(config: TranspileConfig): Promise<DiscoveredProgram[]> {
  const found = new Map<string, boolean>();
  const visited = new Set<string>();
  for (const folder of config.converterInputFolders ?? []) {
    await collectProgramFiles(folder, config.generatedFolder, found, visited);
  }

  const excludeFilters = config.converterExcludeFilters ?? [];
  const selected = [...found.keys()]
    .sort((left, right) => left.localeCompare(right))
    .map((filename) => ({ filename, relativePath: posix(path.relative(config.root, filename)) }))
    .filter((entry) => !excludeFilters.some((filter) => filter.test(entry.relativePath)));

  const entryPointTypes = new Set(config.modulePools ? ["1", "M"] : ["1"]);
  const programs: DiscoveredProgram[] = [];
  for (const entry of selected) {
    let source;
    try {
      source = await fs.readFile(entry.filename, "utf8");
    } catch {
      continue;
    }
    const programType = await readProgramType(entry.filename);
    if (programType === undefined ? !isEntryPoint(source) : !entryPointTypes.has(programType)) continue;
    // abapGit writes a namespace /ABC/ as #abc#.
    const programName = path.basename(entry.filename).slice(0, -PROGRAM_SUFFIX.length).replaceAll("#", "/").toUpperCase();
    programs.push({ ...entry, source, programName });
  }
  return programs;
}

// SUBC from the program's .prog.xml, or undefined when there is none.
async function readProgramType(filename: string): Promise<string | undefined> {
  try {
    const xml = await fs.readFile(filename.replace(/\.prog\.abap$/i, ".prog.xml"), "utf8");
    return /<SUBC>\s*([^<\s]*)\s*<\/SUBC>/.exec(xml)?.[1]?.toUpperCase();
  } catch {
    return undefined;
  }
}

const INCLUDE_SOURCE_SUFFIXES = [".prog.abap", ".incl.abap"];

/**
 * The folders an INCLUDE is searched in: every folder holding program sources
 * in the converter input, the transpiler input and the libraries, subfolders
 * included, as abapGit serialises each subpackage into a folder of its own.
 * The converter input comes first, then the rest, each in a deterministic order.
 */
export async function discoverIncludeFolders(config: TranspileConfig): Promise<string[]> {
  const folders: string[] = [];
  const visited = new Set<string>();
  for (const folder of [...(config.converterInputFolders ?? []), ...(config.inputFolders ?? []), ...(config.libraryFolders ?? [])]) {
    const found = new Map<string, boolean>();
    await collectProgramFiles(folder, config.generatedFolder, found, visited, INCLUDE_SOURCE_SUFFIXES);
    const directories = [...new Set([...found.keys()].map((filename) => path.dirname(filename)))]
      .sort((left, right) => left.localeCompare(right));
    for (const directory of [path.resolve(folder), ...directories]) {
      if (!folders.includes(directory)) folders.push(directory);
    }
  }
  return folders;
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
export async function discoverGlobalObjects(config: TranspileConfig, skipFolders: string[] = []): Promise<Map<string, string>> {
  const found = new Map<string, boolean>();
  const visited = new Set<string>();
  const skipped = [config.generatedFolder, ...skipFolders];
  for (const folder of [...(config.converterInputFolders ?? []), ...(config.inputFolders ?? []), ...(config.libraryFolders ?? [])]) {
    await collectProgramFiles(folder, skipped, found, visited, GLOBAL_OBJECT_SUFFIXES);
  }
  const objects = new Map<string, string>();
  for (const filename of [...found.keys()].sort((left, right) => left.localeCompare(right))) {
    const basename = path.basename(filename);
    const suffix = GLOBAL_OBJECT_SUFFIXES.find((item) => basename.toLowerCase().endsWith(item));
    // abapGit writes a namespace /ABC/ as #abc#.
    const name = basename.slice(0, -suffix!.length).replaceAll("#", "/").toUpperCase();
    if (!objects.has(name)) objects.set(name, filename);
  }
  return objects;
}

const DICTIONARY_SUFFIXES = [".dtel.xml", ".doma.xml", ".tabl.xml", ".ttyp.xml"];

/**
 * The abapGit-serialized dictionary objects in the converter input, the
 * transpiler input and the libraries, in that order. The converter reads one
 * only when a report refers to it, to resolve e.g. the built-in type behind a
 * data element a PARAMETERS statement names.
 */
export async function discoverDictionaryFiles(config: TranspileConfig): Promise<string[]> {
  const found = new Map<string, boolean>();
  const visited = new Set<string>();
  for (const folder of [...(config.converterInputFolders ?? []), ...(config.inputFolders ?? []), ...(config.libraryFolders ?? [])]) {
    const files = new Map<string, boolean>();
    await collectProgramFiles(folder, config.generatedFolder, files, visited, DICTIONARY_SUFFIXES);
    for (const filename of [...files.keys()].sort((left, right) => left.localeCompare(right))) found.set(filename, true);
  }
  return [...found.keys()];
}

function resolveOverride<T>(value: PerProgram<T> | undefined, programName: string): T | undefined {
  return typeof value === "function" ? (value as (name: string) => T | undefined)(programName) : value;
}

/**
 * Build the convertProgram input for one discovered program. This is the only
 * place option precedence is decided: an explicit override wins, otherwise the
 * value is derived from the configuration or left to the converter's defaults.
 */
export function conversionPlan(config: TranspileConfig, program: DiscoveredProgram, overrides: ConversionOverrides = {}): ConvertOptions {
  const {
    className,
    transactionCode,
    description,
    mode,
    partialStrategy,
    ddicTypes,
    transactions,
    includeFolders,
    language = config.language,
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
    // The object name, which the source cannot be trusted to repeat.
    programName: program.programName,
    dynproMetadataFilename: program.filename.replace(/\.prog\.abap$/i, ".prog.xml"),
    dynproScreenDirectory: path.dirname(program.filename),
    // A report's includes sit next to it or among the sources the transpiler
    // compiles, so the converter input is searched first, then the rest. The
    // batch passes every subfolder too, from discoverIncludeFolders.
    includePaths: includeFolders ?? [...new Set([
      ...(config.converterInputFolders ?? []),
      ...(config.inputFolders ?? []),
      ...(config.libraryFolders ?? []),
    ])],
    configPath: path.join(config.root, "abaplint.jsonc"),
    className: resolveOverride(className, program.programName),
    transactionCode: resolveOverride(transactionCode, program.programName) ?? transaction?.transactionCode,
    ...(resolvedDescription === undefined ? {} : { description: resolvedDescription }),
    ...(language === undefined ? {} : { language }),
    mode: mode ?? "strict",
    ...(partialStrategy === undefined ? {} : { partialStrategy }),
    ...(ddicTypes === undefined ? {} : { ddicTypes }),
  };
}
