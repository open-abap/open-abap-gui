import fs from "node:fs/promises";
import { normalizeOptions, defaultClassName, defaultTransactionCode, normalizeObjectName, normalizeTransactionCode } from "./options.mjs";
import { diagnostic, sortDiagnostics } from "./diagnostics.mjs";
import { resolveSources } from "./source-resolver.mjs";
import { parseUnits, readConfig } from "./parser.mjs";
import { emptyReportIR } from "./ir/report-ir.mjs";
import { classifyProgram } from "./passes/classify-program.mjs";
import { collectDeclarations } from "./passes/collect-declarations.mjs";
import { collectSelectionScreens } from "./passes/collect-selection-screens.mjs";
import { collectEvents } from "./passes/collect-events.mjs";
import { collectLocalClasses } from "./passes/collect-local-classes.mjs";
import { collectRoutines } from "./passes/collect-routines.mjs";
import { collectModules } from "./passes/collect-modules.mjs";
import { buildSourceIndex } from "./source-index.mjs";
import { buildStatePlan } from "./passes/lower-state.mjs";
import { collectContinuations } from "./passes/lower-continuations.mjs";
import { selectInterfaces } from "./passes/select-interfaces.mjs";
import { resolveTypes } from "./passes/resolve-types.mjs";
import { analyzeReferences } from "./passes/analyze-references.mjs";
import { buildControlFlowGraphs } from "./passes/control-flow.mjs";
import { analyzeFieldSymbols } from "./passes/analyze-field-symbols.mjs";
import { scanCapabilities } from "./capability.mjs";
import { emitClassSource, emitHelperSources, emitPartialSkeleton, lowerToScaffoldIR } from "./emit/class-source.mjs";
import { createManifest } from "./emit/manifest.mjs";
import { dynproProgramIR } from "./ir/dynpro-ir.mjs";
import { loadDynproMetadata } from "./dynpro-metadata.mjs";

const SAFE_ENTRY_FAILURE_CODES = new Set([
  "GGCONV-E100", "GGCONV-E101", "GGCONV-E102", "GGCONV-E103", "GGCONV-E104",
  "GGCONV-E105", "GGCONV-E106", "GGCONV-E107", "GGCONV-E108", "GGCONV-E109",
  "GGCONV-E201", "GGCONV-E202", "GGCONV-E203", "GGCONV-E204", "GGCONV-E301",
  "GGCONV-E502", "GGCONV-E503",
]);

function requiresDiagnosticShell(diagnostics) {
  return diagnostics.some((item) => item.severity === "error" && SAFE_ENTRY_FAILURE_CODES.has(item.code));
}

function headerSettings(raw) {
  const text = raw?.replace(/\s+/g, " ").toUpperCase() ?? "";
  const lineSize = /LINE-SIZE\s+(\d+)/.exec(text)?.[1];
  const lineCount = /LINE-COUNT\s+(\d+)(?:\((\d+)\))?/.exec(text);
  return {
    raw: raw ?? "",
    lineSize: lineSize ? Number(lineSize) : undefined,
    lineCount: lineCount ? Number(lineCount[1]) : undefined,
    footerLines: lineCount?.[2] ? Number(lineCount[2]) : undefined,
    noStandardPageHeading: /NO STANDARD PAGE HEADING/.test(text),
  };
}

function includeIdentity(filename) {
  return String(filename ?? "").replaceAll("\\", "/").toUpperCase();
}

function includeBase(filename) {
  return includeIdentity(filename).split("/").at(-1)?.replace(/\.(?:INCL\.)?ABAP$/, "") ?? "";
}

function orderedStatements(parsedUnits) {
  const units = new Map(parsedUnits.map((unit) => [includeIdentity(unit.filename), unit]));
  const childFor = (parent, name) => {
    const expected = String(name).toUpperCase();
    return parsedUnits.find((unit) => includeIdentity(unit.ancestry?.at(-1)) === includeIdentity(parent)
      && (includeIdentity(unit.filename) === expected || includeBase(unit.filename) === expected));
  };
  const expand = (unit, active = new Set()) => {
    const identity = includeIdentity(unit.filename);
    if (active.has(identity)) return [];
    const nextActive = new Set(active).add(identity);
    const result = [];
    for (const statement of unit.statements) {
      result.push(statement);
      if (statement.kind !== "Include") continue;
      const name = /^\s*INCLUDE\s+([^\s.]+)\s*\./i.exec(statement.text)?.[1];
      const child = name ? childFor(unit.filename, name) : undefined;
      if (child) result.push(...expand(child, nextActive));
    }
    return result;
  };
  const root = parsedUnits[0];
  return root ? expand(root) : [...units.values()].flatMap((unit) => unit.statements);
}

function buildReportIR(parsed, resolved, options, diagnostics) {
  const serializable = (statement) => {
    const { node: _parserNode, ...plain } = statement;
    return plain;
  };
  const allStatements = orderedStatements(parsed.units).map(serializable);
  const classification = classifyProgram(allStatements);
  const ir = emptyReportIR({
    filename: options.filename,
    source: resolved.units[0]?.source ?? options.source ?? "",
    sourceHash: resolved.sourceHash,
    newline: resolved.newline,
  });
  ir.programName = classification.programName;
  ir.programKind = classification.programKind;
  ir.units = parsed.units.map((unit) => ({ filename: unit.filename, ancestry: unit.ancestry }));
  ir.statements = allStatements;
  ir.header = headerSettings(classification.header?.text);
  ir.guiStatusMetadata = options.guiStatusMetadata ?? options.guiStatuses ?? {};
  collectLocalClasses(ir, allStatements);
  collectEvents(ir, allStatements);
  collectRoutines(ir);
  ir.declarations = collectDeclarations(allStatements);
  ir.selections = collectSelectionScreens(ir.declarations);
  ir.safeFieldSymbols = [...analyzeFieldSymbols(ir)].sort();
  ir.modules = collectModules(allStatements);
  ir.sourceIndex = buildSourceIndex(ir);
  ir.statePlan = buildStatePlan(ir);
  ir.references = analyzeReferences(ir);
  ir.continuations = collectContinuations(allStatements, [
    ...ir.statePlan.globals,
    ...ir.statePlan.selections,
  ]);
  ir.controlFlowGraphs = buildControlFlowGraphs(ir);
  ir.hiddenNames = [...new Set(allStatements.flatMap((statement) => {
    if (statement.kind !== "Hide") return [];
    return (statement.text.match(/\b[A-Z][A-Z0-9_]*\b/gi) ?? [])
      .filter((name) => !/^HIDE$/i.test(name))
      .map((name) => name.toUpperCase());
  }))].sort();
  resolveTypes(ir, options, diagnostics);
  return ir;
}

function metadataTextPool(ir, options) {
  return options.textPool
    ?? options.textSymbols
    ?? ir.screenMetadata?.textPool
    ?? ir.dynproMetadata?.textPool;
}

function textFallbackDiagnostics(ir, options) {
  const result = [];
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      if ((item.kind === "parameter" || item.kind === "select-option") && item.text === item.name) {
        result.push(diagnostic({
          code: "GGCONV-W101",
          severity: "warning",
          filename: options.filename,
          start: item.span?.start,
          end: item.span?.end,
          construct: item.name,
          message: `selection text for ${item.name} was not supplied; the identifier is used as deterministic fallback text`,
          suggestion: "Pass textPool metadata to resolve the original selection label.",
          phase: "selection-screen",
        }));
      }
      for (const field of ["text", "title"]) {
        if (typeof item[field] === "string" && /^TEXT[-_]/i.test(item[field])) {
          result.push(diagnostic({
            code: "GGCONV-W101",
            severity: "warning",
            filename: options.filename,
            start: item.span?.start,
            end: item.span?.end,
            construct: item[field],
            message: `text-pool entry ${item[field]} was not supplied; deterministic fallback text is emitted`,
            suggestion: "Pass textPool metadata to resolve the original selection text.",
            phase: "selection-screen",
          }));
        }
      }
    }
  }
  return result;
}

function textPoolKey(key) {
  return String(key ?? "").replace(/^TEXT[-_]/i, "").toUpperCase();
}

function textPoolLookup(textPool) {
  const entries = new Map();
  const add = (key, value) => {
    if (key !== undefined && value !== undefined && value !== "") {
      entries.set(textPoolKey(key), value);
    }
  };
  if (textPool instanceof Map) {
    for (const [key, value] of textPool) add(key, value);
  } else if (Array.isArray(textPool)) {
    for (const entry of textPool) add(entry?.key, entry?.entry ?? entry?.text ?? entry?.value);
  } else if (textPool && typeof textPool === "object") {
    for (const [key, value] of Object.entries(textPool)) add(key, value);
  }
  if (entries.size) return (key) => entries.get(textPoolKey(key));
  if (typeof textPool === "string") {
    const parsed = new Map();
    for (const line of textPool.replace(/^\uFEFF/, "").split(/\r?\n/)) {
      const match = /^\s*([^|=\t ]+)\s*(?:\||=|\t|\s{2,})\s*(.*?)\s*$/.exec(line);
      if (match && match[2]) parsed.set(textPoolKey(match[1]), match[2].replace(/^'(.*)'$/, "$1").replaceAll("''", "'"));
    }
    return (key) => parsed.get(textPoolKey(key));
  }
  return () => undefined;
}

function applyTextPool(ir, options) {
  const lookup = textPoolLookup(metadataTextPool(ir, options));
  const apply = (items) => {
    for (const item of items ?? []) {
      for (const field of ["text", "title"]) {
        if (typeof item[field] !== "string") continue;
        if (field === "text" && item.suppressTextPool) continue;
        const value = lookup(item[field])
          ?? lookup(item[field].replace(/^TEXT[-_]/i, ""))
          ?? (item.name ? lookup(`TEXT-${item.name}`) : undefined)
          ?? (item.name ? lookup(item.name) : undefined);
        if (typeof value === "string" && value !== "") item[field] = value;
      }
    }
  };
  for (const screen of ir.selections) {
    apply(screen.elements);
  }
  for (const screen of [...(ir.screenMetadata?.screens ?? []), ...(ir.dynproMetadata?.screens ?? [])]) {
    if (typeof screen.title === "string") screen.title = lookup(screen.title) ?? screen.title;
    if (screen.titlebar?.text) screen.titlebar.text = lookup(screen.titlebar.text) ?? screen.titlebar.text;
    apply(screen.elements);
  }
  for (const titlebar of Object.values(ir.screenMetadata?.titlebars ?? {})) {
    if (titlebar && typeof titlebar.text === "string") titlebar.text = lookup(titlebar.text) ?? titlebar.text;
  }
}

function applySelectionMetadata(ir, options) {
  const metadata = options.selectionMetadata ?? options.selectionScreenMetadata;
  if (!metadata || typeof metadata !== "object") return;
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      const details = metadata[item.name?.toUpperCase()];
      if (!details || typeof details !== "object") continue;
      if (Array.isArray(details.fixedValues ?? details.values)) item.fixedValues = details.fixedValues ?? details.values;
      if (details.dataType && typeof details.dataType === "object") item.dataType = { ...item.dataType, ...details.dataType };
    }
  }
}

function applyFunctionKeyMetadata(ir) {
  const assignments = new Map();
  for (const statement of ir.statements) {
    const match = /SSCRFIELDS-FUNCTXT_(\d+)\s*=\s*('(?:''|[^'])*')/i.exec(statement.text);
    if (match) assignments.set(Number(match[1]), match[2].slice(1, -1).replaceAll("''", "'"));
  }
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      if (item.layout !== "function_key") continue;
      const number = Number(item.number);
      if (assignments.has(number)) item.text = assignments.get(number);
      item.ucomm = `FC${String(number).padStart(2, "0")}`;
    }
  }
}

function messageMetadataEntry(metadata, id, number) {
  if (!metadata) return undefined;
  const classes = metadata instanceof Map ? metadata : metadata.messages ?? metadata.classes ?? metadata;
  const messageClass = classes instanceof Map
    ? classes.get(id) ?? classes.get(id.toUpperCase())
    : classes?.[id] ?? classes?.[id.toUpperCase()];
  if (!messageClass) return undefined;
  const messages = messageClass instanceof Map ? messageClass : messageClass.messages ?? messageClass;
  return messages instanceof Map
    ? messages.get(number) ?? messages.get(String(number).padStart(3, "0"))
    : messages?.[number] ?? messages?.[String(number).padStart(3, "0")];
}

function applyMessageMetadata(ir, options, diagnostics) {
  const references = ir.statements.map((statement) => {
    const match = /\bMESSAGE\s+(?:[AEISWX])?(\d{3})\(([A-Z0-9_\/]+)\)/i.exec(statement.text);
    return match ? { statement, id: match[2].toUpperCase(), number: match[1] } : undefined;
  }).filter(Boolean);
  if (!references.length) return;
  const metadata = options.messageMetadata ?? options.messageClasses ?? options.messages;
  for (const { statement, id, number } of references) {
    const entry = messageMetadataEntry(metadata, id, number);
    if (entry) continue;
    if (metadata) {
      diagnostics.push(diagnostic({
        code: "GGCONV-E306",
        filename: statement.filename,
        start: statement.span.start,
        end: statement.span.end,
        construct: `${id}(${number})`,
        message: `message text for ${id}(${number}) was not supplied by message metadata`,
        suggestion: "Pass messageMetadata with the message class and three-digit message number, or keep the runtime message class available.",
        phase: "messages",
      }));
    } else {
      diagnostics.push(diagnostic({
        code: "GGCONV-I101",
        severity: "info",
        filename: statement.filename,
        start: statement.span.start,
        end: statement.span.end,
        construct: `${id}(${number})`,
        message: `message text for ${id}(${number}) remains an external runtime dependency`,
        suggestion: "Pass messageMetadata to make the message text available during conversion and validation.",
        phase: "messages",
      }));
    }
  }
  ir.messageMetadata = metadata ? { supplied: true } : { supplied: false, references: references.map(({ id, number }) => `${id}(${number})`).sort() };
}

function validateNames(ir, options, diagnostics) {
  let className = options.className ? options.className.toUpperCase() : defaultClassName(ir.programName ?? "");
  if (!className) {
    diagnostics.push(diagnostic({ code: "GGCONV-E101", filename: options.filename, construct: "target class", message: "a target class name is required for this report name", suggestion: "Pass className/--class with a valid ABAP global class name.", phase: "options" }));
  } else {
    try {
      className = normalizeObjectName(className, "class");
      const existingNames = Array.isArray(options.existingClassNames) ? options.existingClassNames : Array.isArray(options.existingClasses) ? options.existingClasses : [];
      if (existingNames.map((name) => String(name).toUpperCase()).includes(className)) {
        diagnostics.push(diagnostic({ code: "GGCONV-E106", filename: options.filename, construct: className, message: `target class ${className} already exists`, suggestion: "Choose a different target class or perform an explicit, separately authorized replacement.", phase: "options" }));
      }
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-E101", filename: options.filename, construct: className, message: error.message, suggestion: "Use an uppercase ABAP class name of at most 30 characters.", phase: "options" }));
    }
  }
  let transactionCode = options.transactionCode?.toUpperCase() ?? defaultTransactionCode(ir.programName ?? "");
  if (options.transactionCode) {
    try {
      transactionCode = normalizeTransactionCode(options.transactionCode);
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-E105", filename: options.filename, construct: "transaction code", message: error.message, suggestion: "Pass a valid scaffold transaction code.", phase: "options" }));
      transactionCode = undefined;
    }
  }
  if (!transactionCode) diagnostics.push(diagnostic({ code: "GGCONV-E105", filename: options.filename, construct: "transaction code", message: "the report name cannot be used as a scaffold transaction code", suggestion: "Pass transactionCode/--tcode explicitly.", phase: "options" }));
  ir.targetClassName = className;
  ir.transactionCode = transactionCode;
  const metadataDescription = ir.screenMetadata?.reportTitle ?? ir.dynproMetadata?.reportTitle;
  ir.description = !options.descriptionProvided && metadataDescription ? metadataDescription : options.description;
}

function validateSymbolCollisions(ir, diagnostics) {
  for (const [name, symbols] of Object.entries(ir.sourceIndex?.collisions ?? {})) {
    const relevant = symbols.filter((symbol) => !["type", "typebegin", "typeend", "selectionscreen"].includes(symbol.kind));
    if (relevant.length < 2) continue;
    const symbol = relevant[1];
    diagnostics.push(diagnostic({
      code: "GGCONV-E204",
      filename: symbol.filename,
      start: symbol.span.start,
      end: symbol.span.end,
      construct: name,
      message: `duplicate converted symbol ${name} would be ambiguous in class state or routine dispatch`,
      suggestion: "Rename one declaration/routine in the source or provide an explicit mapping before conversion.",
      phase: "symbols",
    }));
  }
}

function buildSourceMap(ir) {
  const sourceMap = [];
  for (const name of Object.keys(ir.events).filter((event) => ir.events[event].length)) {
    sourceMap.push({ source: name, output: `${ir.targetClassName}~${name}`, start: ir.events[name][0].span.start, end: ir.events[name].at(-1).span.end, segment: "event" });
    for (const statement of ir.events[name]) sourceMap.push({ source: name, output: `${ir.targetClassName}~${name}`, start: statement.span.start, end: statement.span.end, construct: statement.kind, segment: "statement" });
  }
  for (const routine of ir.routines) {
    for (const statement of routine.statements) sourceMap.push({ source: routine.name, output: `${ir.targetClassName}~${routine.methodName}`, start: statement.span.start, end: statement.span.end, construct: statement.kind, segment: "statement" });
  }
  sourceMap.sort((a, b) => a.start.line - b.start.line || a.start.column - b.start.column || a.segment.localeCompare(b.segment) || a.output.localeCompare(b.output));
  return sourceMap;
}

function addGeneratedLocations(classSource, sourceMap) {
  const lines = classSource.split("\n");
  const methodLines = new Map();
  for (let index = 0; index < lines.length; index++) {
    const match = /^\s*METHOD\s+(.+)\.$/i.exec(lines[index]);
    if (match) {
      const name = match[1].trim().toUpperCase();
      methodLines.set(name, index + 1);
      methodLines.set(name.split("~").at(-1), index + 1);
    }
  }
  return sourceMap.map((segment) => {
    const output = segment.output.toUpperCase();
    const line = methodLines.get(output) ?? methodLines.get(output.split("~").at(-1));
    return line ? { ...segment, outputStart: { line, column: 1 }, outputEnd: { line, column: 1 } } : segment;
  });
}

function mapGeneratedDiagnostic(item, sourceMap, generatedFilename) {
  const candidates = sourceMap.filter((segment) => segment.outputStart?.line <= item.start.line);
  const source = candidates.sort((a, b) => a.outputStart.line - b.outputStart.line).at(-1);
  if (!source) return { ...item, internalLocation: { filename: generatedFilename, start: item.start, end: item.end } };
  return {
    ...item,
    filename: source.filename ?? generatedFilename,
    start: source.start,
    end: source.end,
    generatedLocation: { filename: generatedFilename, start: item.start, end: item.end },
  };
}

export async function convertProgram(input = {}) {
  const options = normalizeOptions(input);
  const diagnostics = [];
  const startedAt = Date.now();
  let timeLimitReported = false;
  const timeLimit = () => options.maxDurationMs > 0 && Date.now() - startedAt > options.maxDurationMs;
  const reportTimeLimit = () => {
    if (!timeLimit() || timeLimitReported) return;
    timeLimitReported = true;
    diagnostics.push(limitDiagnostic("GGCONV-E109", "conversion", "conversion exceeded the configured time limit", "Raise maxDurationMs deliberately or split the source into smaller units."));
  };
  const limitDiagnostic = (code, construct, message, suggestion) => diagnostic({
    code,
    filename: options.filename,
    construct,
    message,
    suggestion,
    phase: "input",
  });
  let source = options.source;
  if (source === undefined) {
    try {
      source = await fs.readFile(options.filename, "utf8");
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-E100", filename: options.filename, construct: "source", message: `unable to read source: ${error.message}`, suggestion: "Pass source text or a readable filename.", phase: "input" }));
      return { classSource: undefined, manifest: undefined, diagnostics: sortDiagnostics(diagnostics), sourceMap: [], supported: false };
    }
  }
  const sourceBytes = Buffer.byteLength(source, "utf8");
  const sourceLines = source.split(/\r?\n/).length;
  if (sourceBytes > options.maxSourceBytes) diagnostics.push(limitDiagnostic(
    "GGCONV-E107",
    "source",
    `source is ${sourceBytes} bytes; the configured limit is ${options.maxSourceBytes}`,
    "Raise maxSourceBytes deliberately or split the source into includes before conversion.",
  ));
  if (sourceLines > options.maxSourceLines) diagnostics.push(limitDiagnostic(
    "GGCONV-E108",
    "source",
    `source has ${sourceLines} lines; the configured limit is ${options.maxSourceLines}`,
    "Raise maxSourceLines deliberately or split the source into includes before conversion.",
  ));
  if (diagnostics.some((item) => item.code === "GGCONV-E107" || item.code === "GGCONV-E108")) {
    return { classSource: undefined, manifest: undefined, diagnostics: sortDiagnostics(diagnostics), sourceMap: [], supported: false };
  }
  const resolved = await resolveSources({ source, filename: options.filename, resolveInclude: options.resolveInclude });
  diagnostics.push(...resolved.diagnostics);
  const resolvedBytes = resolved.units.reduce((total, unit) => total + Buffer.byteLength(unit.source, "utf8"), 0);
  const resolvedLines = resolved.units.reduce((total, unit) => total + unit.source.split("\n").length, 0);
  if (resolvedBytes > options.maxSourceBytes && !diagnostics.some((item) => item.code === "GGCONV-E107")) diagnostics.push(limitDiagnostic(
    "GGCONV-E107",
    "resolved source units",
    `resolved source units total ${resolvedBytes} bytes; the configured limit is ${options.maxSourceBytes}`,
    "Raise maxSourceBytes deliberately or split the source into smaller includes.",
  ));
  if (resolvedLines > options.maxSourceLines && !diagnostics.some((item) => item.code === "GGCONV-E108")) diagnostics.push(limitDiagnostic(
    "GGCONV-E108",
    "resolved source units",
    `resolved source units total ${resolvedLines} lines; the configured limit is ${options.maxSourceLines}`,
    "Raise maxSourceLines deliberately or split the source into smaller includes.",
  ));
  if (diagnostics.some((item) => item.code === "GGCONV-E107" || item.code === "GGCONV-E108")) {
    return { classSource: undefined, manifest: undefined, diagnostics: sortDiagnostics(diagnostics), sourceMap: [], supported: false };
  }
  reportTimeLimit();
  const config = await readConfig(options.configPath);
  const parsed = parseUnits(resolved.units, config);
  diagnostics.push(...parsed.diagnostics);
  reportTimeLimit();
  const ir = buildReportIR(parsed, resolved, options, diagnostics);
  if (ir.programKind === "module-pool") {
    if (options.dynproMetadata) ir.dynproMetadata = options.dynproMetadata;
    else if (typeof options.resolveDynpro === "function") {
      try {
        ir.dynproMetadata = await options.resolveDynpro({ programName: ir.programName, filename: options.filename, source: ir.source.source });
      } catch (error) {
        diagnostics.push(diagnostic({ code: "GGCONV-E503", filename: options.filename, construct: "dynpro metadata", message: `dynpro metadata resolver failed: ${error.message}`, suggestion: "Return explicit screen and flow metadata from the resolver.", phase: "dynpro" }));
      }
    } else if (options.loadDynproMetadata !== false) {
      try {
        ir.dynproMetadata = await loadDynproMetadata({
          filename: options.filename,
          metadataFilename: options.dynproMetadataFilename,
          screenDirectory: options.dynproScreenDirectory,
          screenFiles: options.dynproScreenFiles,
        });
      } catch (error) {
        diagnostics.push(diagnostic({ code: "GGCONV-E503", filename: options.filename, construct: "dynpro metadata", message: error.message, suggestion: "Fix the report-owned .prog.xml and .prog.screen_NNNN.abap metadata files or supply dynproMetadata explicitly.", phase: "dynpro" }));
      }
    }
    if (ir.dynproMetadata) ir.dynproIR = dynproProgramIR(ir);
  } else if (ir.programKind === "report" && options.screenMetadata) {
    ir.screenMetadata = options.screenMetadata;
  } else if (ir.programKind === "report" && options.loadDynproMetadata !== false) {
    try {
      ir.screenMetadata = await loadDynproMetadata({
        filename: options.filename,
        metadataFilename: options.dynproMetadataFilename,
        screenDirectory: options.dynproScreenDirectory,
        screenFiles: options.dynproScreenFiles,
      });
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-E503", filename: options.filename, construct: "dynpro metadata", message: error.message, suggestion: "Fix the report-owned .prog.xml and .prog.screen_NNNN.abap metadata files or supply screenMetadata explicitly.", phase: "dynpro" }));
    }
  }
  validateNames(ir, options, diagnostics);
  validateSymbolCollisions(ir, diagnostics);
  applyTextPool(ir, options);
  applySelectionMetadata(ir, options);
  applyFunctionKeyMetadata(ir);
  applyMessageMetadata(ir, options, diagnostics);
  diagnostics.push(...textFallbackDiagnostics(ir, options));
  diagnostics.push(...scanCapabilities(ir, ir.statements, options));
  reportTimeLimit();
  selectInterfaces(ir);
  if (!ir.programName) diagnostics.push(diagnostic({ code: "GGCONV-E101", filename: options.filename, construct: "REPORT", message: "input is not an executable REPORT", suggestion: "Start the source with REPORT and supply a valid program name.", phase: "classify" }));
  if (!["report", "module-pool"].includes(ir.programKind) && ir.programName) diagnostics.push(diagnostic({ code: "GGCONV-E102", filename: options.filename, construct: ir.programKind, message: `${ir.programKind} sources are not executable report inputs`, suggestion: "Pass a REPORT source, or convert includes and other program types in their owning executable program.", phase: "classify" }));
  if (ir.programKind === "module-pool" && !ir.dynproMetadata && !diagnostics.some((item) => item.code === "GGCONV-E502")) diagnostics.push(diagnostic({ code: "GGCONV-E502", filename: options.filename, construct: "PROGRAM", message: "dynpro metadata is required for module-pool conversion", suggestion: "Use the dynpro frontend with explicit screen metadata.", phase: "capability" }));
  const sorted = sortDiagnostics(diagnostics);
  const supported = !sorted.some((item) => item.severity === "error" || item.code.startsWith("GGCONV-E")) && Boolean(ir.targetClassName) && Boolean(ir.transactionCode);
  if (!supported && options.mode === "strict") {
    return { classSource: undefined, manifest: createManifest(ir, sorted, options), diagnostics: sorted, sourceMap: [], reportIR: ir, supported: false };
  }
  const useDiagnosticShell = !supported && options.mode === "partial" && options.partialStrategy === "skeleton" && requiresDiagnosticShell(sorted);
  const classSource = useDiagnosticShell
    ? emitPartialSkeleton(ir, options, sorted)
    : emitClassSource(ir, options);
  const helperSources = !useDiagnosticShell
    ? emitHelperSources(ir, options)
    : [];
  const sourceMap = addGeneratedLocations(classSource, buildSourceMap(ir));
  const generatedValidation = parseUnits([
    { filename: `${ir.targetClassName}.clas.abap`, source: classSource, ancestry: [], newline: "\n" },
    ...helperSources.map((helper) => ({ filename: `${helper.className}.clas.abap`, source: helper.source, ancestry: [], newline: "\n" })),
  ], config);
  diagnostics.push(...generatedValidation.diagnostics.map((item) => ({
    ...item,
    code: "GGCONV-E202",
    construct: item.construct,
    message: `generated class failed parser validation: ${item.message}`,
    suggestion: "Fix the lowering rule before using generated source.",
    phase: "validate-generated",
  })).map((item) => mapGeneratedDiagnostic(item, sourceMap, `${ir.targetClassName}.clas.abap`)));
  const finalDiagnostics = sortDiagnostics(diagnostics);
  const finalSupported = !finalDiagnostics.some((item) => item.severity === "error" || item.code.startsWith("GGCONV-E")) && Boolean(ir.targetClassName) && Boolean(ir.transactionCode);
  const manifest = createManifest(ir, finalDiagnostics, options);
  const scaffold = lowerToScaffoldIR(ir, options, sourceMap);
  return { classSource, helperSources, manifest, diagnostics: finalDiagnostics, sourceMap, reportIR: ir, scaffoldIR: scaffold, supported: finalSupported };
}
