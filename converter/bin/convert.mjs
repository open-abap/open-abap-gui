#!/usr/bin/env node
import fs from "node:fs/promises";
import path from "node:path";
import { convertProgram } from "../src/api.mjs";
import { diagnosticsToJSON, diagnosticsToText } from "../src/diagnostics.mjs";

function usage() {
  return `Usage: node converter/bin/convert.mjs <report.prog.abap> [options]

Options:
  --class <name>                 Target global class name
  --output <path>                Write generated .clas.abap atomically
  --tcode <code>                 Transaction code
  --description <text>           Transaction description
  --mode strict|partial          Conversion mode (default: strict)
  --diagnostics text|json        Diagnostic format (default: text)
  --check                        Analyze without writing generated source
  --help                         Show this help
`;
}

function parseArgs(argv) {
  const options = { diagnostics: "text" };
  const positional = [];
  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];
    if (arg === "--help" || arg === "-h") options.help = true;
    else if (arg === "--check") options.check = true;
    else if (arg.startsWith("--")) {
      const key = arg.slice(2);
      if (key === "diagnostics" || key === "mode" || key === "class" || key === "output" || key === "tcode" || key === "description") options[key] = argv[++index];
      else throw new Error(`unknown option ${arg}`);
    } else positional.push(arg);
  }
  options.filename = positional[0];
  return options;
}

async function exists(filename) {
  try { await fs.access(filename); return true; } catch { return false; }
}

async function writeAtomically(filename, contents) {
  const temporary = `${filename}.tmp-${process.pid}`;
  await fs.writeFile(temporary, contents, "utf8");
  await fs.rename(temporary, filename);
}

const options = parseArgs(process.argv.slice(2));
if (options.help) {
  console.log(usage());
  process.exit(0);
}
if (!options.filename) {
  console.error(usage());
  process.exit(2);
}
if (options.diagnostics !== "text" && options.diagnostics !== "json") throw new Error("--diagnostics must be text or json");

const result = await convertProgram({
  filename: options.filename,
  className: options.class,
  transactionCode: options.tcode,
  description: options.description,
  mode: options.mode,
});
if (result.diagnostics.length) {
  const rendered = options.diagnostics === "json" ? diagnosticsToJSON(result.diagnostics) : diagnosticsToText(result.diagnostics);
  console.error(rendered);
}
if (options.check) {
  console.log(JSON.stringify({
    supported: result.supported,
    programKind: result.reportIR?.programKind,
    capabilities: result.reportIR?.capabilities ?? [],
    diagnostics: result.diagnostics,
    manifest: result.manifest,
  }, null, 2));
} else if (result.classSource && options.output) {
  const output = path.resolve(options.output);
  if (await exists(output)) {
    console.error(`refusing to overwrite existing output: ${output}`);
    process.exitCode = 2;
  } else {
    await fs.mkdir(path.dirname(output), { recursive: true });
    await writeAtomically(output, result.classSource);
    await writeAtomically(`${output}.manifest.json`, `${JSON.stringify(result.manifest, null, 2)}\n`);
  }
} else if (result.classSource) {
  process.stdout.write(result.classSource);
}
if (!result.supported) process.exitCode = 1;
