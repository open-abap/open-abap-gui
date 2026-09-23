#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { convertConfiguredPrograms } from "../src/batch.mjs";
import { DEFAULT_CONFIG_FILENAME, discoverPrograms, loadTranspileConfig } from "../src/config.mjs";
import { diagnosticsToJSON, diagnosticsToText, sortDiagnostics } from "../src/diagnostics.mjs";
import { loadLibraries } from "../src/libs.mjs";

function usage() {
  return `Usage: node converter/bin/convert.mjs [options]

Converts every executable program an abap_transpile.json selects. Generated
classes are written to the configured output_folder with a "_converter" suffix.

Options:
  --config <file>          abap_transpile.json (default: ./${DEFAULT_CONFIG_FILENAME})
  --program <name>         convert only this program (repeatable; report name
                           or path fragment)
  --output-folder <dir>    write classes here instead of <output_folder>_converter
  --ddic <file.json>       DDIC types as {"TABLE":{"type":"...",
                           "fields":{"FIELD":"..."}}}
  --mode strict|partial    conversion mode (default: strict)
  --diagnostics text|json  diagnostic format (default: text)
  --check                  analyze and print the summary, write nothing
  --help                   show this help

Single-program options (require exactly one --program):
  --class <name>           target global class name
  --tcode <code>           transaction code
  --description <text>     transaction description
  --output <path>          write this one .clas.abap instead of the folder
`;
}

function positionalError(value) {
  return `convert.mjs takes no positional arguments, got ${JSON.stringify(value)}.
  was:  convert.mjs report.prog.abap --check
  now:  convert.mjs --config ${DEFAULT_CONFIG_FILENAME} --program report --check
`;
}

const VALUE_OPTIONS = new Set([
  "config", "diagnostics", "mode", "class", "output", "output-folder", "tcode", "description", "ddic",
]);
const SINGLE_PROGRAM_OPTIONS = ["class", "tcode", "description", "output"];

function parseArgs(argv) {
  const options = { diagnostics: "text", programs: [] };
  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];
    if (arg === "--help" || arg === "-h") options.help = true;
    else if (arg === "--check") options.check = true;
    else if (arg === "--program") options.programs.push(argv[++index]);
    else if (arg.startsWith("--")) {
      const key = arg.slice(2);
      if (!VALUE_OPTIONS.has(key)) throw new Error(`unknown option ${arg}`);
      options[key] = argv[++index];
    } else throw new Error(positionalError(arg));
  }
  return options;
}

async function readDdicTypes(filename) {
  if (!filename) return undefined;
  const parsed = JSON.parse(await fs.readFile(path.resolve(filename), "utf8"));
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error(`--ddic must contain a JSON object of DDIC type metadata, got ${Array.isArray(parsed) ? "an array" : typeof parsed}`);
  }
  return parsed;
}

function matchesRequest(program, request) {
  const wanted = String(request).toLowerCase();
  return program.programName.toLowerCase() === wanted
    || program.relativePath.toLowerCase() === wanted
    || path.basename(program.relativePath).toLowerCase() === wanted
    || program.relativePath.toLowerCase().endsWith(`/${wanted}`);
}

let options;
try {
  options = parseArgs(process.argv.slice(2));
} catch (error) {
  console.error(error.message);
  process.exit(2);
}
if (options.help) {
  console.log(usage());
  process.exit(0);
}
if (options.diagnostics !== "text" && options.diagnostics !== "json") {
  console.error("--diagnostics must be text or json");
  process.exit(2);
}
if (options.programs.some((item) => typeof item !== "string" || !item)) {
  console.error("--program requires a program name");
  process.exit(2);
}
const singleOnly = SINGLE_PROGRAM_OPTIONS.filter((key) => options[key] !== undefined);
if (singleOnly.length && options.programs.length !== 1) {
  console.error(`${singleOnly.map((key) => `--${key}`).join(", ")} require exactly one --program, got ${options.programs.length}`);
  process.exit(2);
}

const config = await loadTranspileConfig(options.config ?? DEFAULT_CONFIG_FILENAME);
// stderr, so a --check summary on stdout stays parseable JSON.
if (options.config === undefined && !config.diagnostics.some((item) => item.code === "GGCONV-E110")) {
  console.error(`using ${config.filename} (no --config given)`);
}
// GGCONV-W110 warns that abap_transpile will not compile the generated
// classes. A --check run writes none, so the warning has nothing to say.
const configDiagnostics = config.diagnostics.filter((item) => !(options.check && item.code === "GGCONV-W110"));
if (configDiagnostics.length) {
  console.error(options.diagnostics === "json"
    ? diagnosticsToJSON(configDiagnostics)
    : diagnosticsToText(configDiagnostics));
}
if (!config.valid) process.exit(2);

const discovered = await discoverPrograms(config);
let programs = discovered;
if (options.programs.length) {
  programs = [];
  for (const request of options.programs) {
    const matches = discovered.filter((program) => matchesRequest(program, request));
    if (!matches.length) {
      console.error(`no program matching ${JSON.stringify(request)} was found in the configured input folders`);
      process.exit(2);
    }
    for (const match of matches) if (!programs.includes(match)) programs.push(match);
  }
}
if (!programs.length) {
  console.error(`no executable programs were found in the configured input folders`);
  process.exit(2);
}

let ddicTypes;
try {
  ddicTypes = await readDdicTypes(options.ddic);
} catch (error) {
  console.error(error.message);
  process.exit(2);
}

let libraries;
try {
  libraries = loadLibraries(config, { log: (message) => console.error(message) });
} catch (error) {
  console.error(error.message);
  process.exit(2);
}
config.libraryFolders = libraries.folders;
config.libraryClassNames = libraries.classNames;

let summary;
try {
  summary = await convertConfiguredPrograms({
    config,
    programs,
    write: !options.check,
    // --program converts a subset, so the rest of the generated folder is still
    // current output and must survive.
    clear: options.programs.length === 0,
    outputFolder: options["output-folder"],
    outputFile: options.output,
    overrides: {
      mode: options.mode,
      ddicTypes,
      className: options.class,
      transactionCode: options.tcode,
      description: options.description,
    },
  });
} finally {
  libraries.cleanup();
}

const diagnostics = sortDiagnostics([
  ...summary.diagnostics,
  ...summary.programs.flatMap((program) => program.diagnostics),
]);
if (diagnostics.length) {
  console.error(options.diagnostics === "json" ? diagnosticsToJSON(diagnostics) : diagnosticsToText(diagnostics));
}

if (options.check) {
  console.log(JSON.stringify({
    programs: summary.programs,
    summary: {
      programCount: summary.programs.length,
      supportedCount: summary.supportedCount,
      diagnosticCount: diagnostics.length,
    },
  }, null, 2));
}

if (summary.diagnostics.length || summary.supportedCount !== summary.programs.length) process.exitCode = 1;
