import fs from "node:fs/promises";
import { normalizeOptions, defaultClassName, fullClassName, defaultTransactionCode,normalizeObjectName, normalizeTransactionCode } from "./options.js";
import { diagnostic, sortDiagnostics } from "./diagnostics.js";
import { resolveSources, systemIncludeUse } from "./source-resolver.js";
import { generatedSourceConfig, parseUnits, readConfig } from "./parser.js";
import { applyStyleFixes } from "./emit/style-fixes.js";
import { emptyReportIR } from "./ir/report-ir.js";
import { classifyProgram } from "./passes/classify-program.js";
import { collectDeclarations, renameStarWorkAreas } from "./passes/collect-declarations.js";
import { liftInlineDeclarations } from "./passes/lift-inline-declarations.js";
import { dictionaryIndex, lazyProgramScope } from "./passes/program-scope.js";
import { resolveSelectionTypes } from "./passes/resolve-selection-types.js";
import { collectSelectionScreens } from "./passes/collect-selection-screens.js";
import { collectEvents } from "./passes/collect-events.js";
import { collectLocalClasses } from "./passes/collect-local-classes.js";
import { collectRoutines } from "./passes/collect-routines.js";
import { analyzeRoutineWrites } from "./passes/analyze-routine-writes.js";
import { collectModules } from "./passes/collect-modules.js";
import { buildSourceIndex } from "./source-index.js";
import { buildStatePlan } from "./passes/lower-state.js";
import { collectContinuations } from "./passes/lower-continuations.js";
import { selectInterfaces } from "./passes/select-interfaces.js";
import { resolveTypes } from "./passes/resolve-types.js";
import { analyzeReferences } from "./passes/analyze-references.js";
import { buildControlFlowGraphs } from "./passes/control-flow.js";
import { analyzeFieldSymbols, fieldSymbolReferences } from "./passes/analyze-field-symbols.js";
import { collectHeaderLines } from "./passes/header-lines.js";
import { detectDynamicAlv } from "./passes/analyze-dynamic-alv.js";
import { scanCapabilities } from "./capability.js";
import { emitClassSource, emitHelperSources, emitPartialApplication, emitPartialSkeleton, lowerToScaffoldIR } from "./emit/class-source.js";
import { createManifest } from "./emit/manifest.js";
import { dynproProgramIR } from "./ir/dynpro-ir.js";
import { loadDynproMetadata } from "./dynpro-metadata.js";
import { Expressions, Nodes, Statements } from "@abaplint/core";
import { lexedAst, statementAst } from "./abap/ast.js";
import { fieldSymbolsIn, hiddenFields, inlineFieldSymbolsIn } from "./abap/statements.js";
import type { ParseResult, ParsedStatement, ParsedUnit } from "./parser.js";
import type { ResolvedSources, SystemInclude } from "./source-resolver.js";
import type { ConversionResult, ConvertOptions, Diagnostic, Metadata, NormalizedOptions, ReportHeader, ReportIR, SourceMapSegment, SourceUnit, Statement } from "./types.js";

const SAFE_ENTRY_FAILURE_CODES = new Set([
  "GGCONV-E100", "GGCONV-E101", "GGCONV-E102", "GGCONV-E103", "GGCONV-E104",
  "GGCONV-E106", "GGCONV-E107", "GGCONV-E108", "GGCONV-E109",
  "GGCONV-E201", "GGCONV-E202", "GGCONV-E203", "GGCONV-E204", "GGCONV-E205",
  "GGCONV-E502", "GGCONV-E503",
]);

// The parser validation behind GGCONV-E202 only proves the generated source
// parses. A field symbol whose declaration was dropped while its uses survived
// still parses and still fails activation, so the emitted class is also checked
// for that structurally.
export function undeclaredFieldSymbols(source: string): [string, number][] {
  const ast = lexedAst(source);
  const result: [string, number][] = [];
  let declared = new Set<string>();
  let used = new Map<string, number>();
  const closeMethod = () => result.push(...[...used].filter(([name]) => !declared.has(name)));
  for (const statement of ast?.statements ?? []) {
    const text = ast!.source(statement);
    // A declaration in one method does not reach another.
    if (statement.get() instanceof Statements.MethodImplementation) {
      closeMethod();
      declared = new Set();
      used = new Map();
      continue;
    }
    const names = fieldSymbolsIn(text);
    if (statement.get() instanceof Statements.FieldSymbol) {
      names.forEach((name) => declared.add(name));
      continue;
    }
    inlineFieldSymbolsIn(text).forEach((name) => declared.add(name));
    for (const entry of ast!.tokens().filter((item) => item.statement === statement && /^<[A-Z][A-Z0-9_]*>$/i.test(item.token.getStr()))) {
      const name = entry.token.getStr().slice(1, -1).toUpperCase();
      if (!used.has(name)) used.set(name, entry.token.getStart().getRow());
    }
  }
  closeMethod();
  return result;
}

function undeclaredFieldSymbolDiagnostics(sources: SourceUnit[]): Diagnostic[] {
  return sources.flatMap(({ filename, source }) => undeclaredFieldSymbols(source).map(([name, line]) => diagnostic({
    code: "GGCONV-E205",
    filename,
    start: { line, column: 1 },
    construct: `<${name.toLowerCase()}>`,
    message: `generated class references field symbol <${name.toLowerCase()}> without declaring it`,
    suggestion: "Emit the field-symbol declaration, or omit the statements that use it together with its binding.",
    phase: "validate-generated",
  })));
}

// A system include no library ships is skipped by the source resolver; it is
// only missed if the generated class still uses one of its constants.
function systemIncludeDiagnostics(systemIncludes: SystemInclude[] = [], generatedUnits: SourceUnit[], ir: ReportIR): Diagnostic[] {
  const declared = new Set(Object.keys(ir.sourceIndex?.byName ?? {}));
  return systemIncludes.map((include) => {
    const used = systemIncludeUse(include, generatedUnits.map((unit) => unit.source), declared);
    return used
      ? diagnostic({
        code: "GGCONV-E102",
        filename: include.filename,
        start: include.start,
        construct: `INCLUDE <${include.name.toLowerCase()}>`,
        message: `system include <${include.name.toLowerCase()}> is not available, and the generated class uses its constant ${used}`,
        suggestion: `Replace ${used} by its value, or declare it in the program.`,
        phase: "source-resolution",
      })
      : diagnostic({
        code: "GGCONV-W109",
        severity: "warning",
        filename: include.filename,
        start: include.start,
        construct: `INCLUDE <${include.name.toLowerCase()}>`,
        message: `system include <${include.name.toLowerCase()}> is not available; it is skipped, as the generated class uses none of its constants`,
        suggestion: "Remove the INCLUDE from the program.",
        phase: "source-resolution",
      });
  });
}

function requiresDiagnosticShell(diagnostics: Diagnostic[]): boolean {
  return diagnostics.some((item) => SAFE_ENTRY_FAILURE_CODES.has(item.code));
}

function escapedRegExp(value: string): string {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function generatedMethodBody(source: string, methodName: string): string[] | undefined {
  const match = new RegExp(
    `^\\s*METHOD\\s+${escapedRegExp(methodName)}\\s*\\.([\\s\\S]*?)^\\s*ENDMETHOD\\s*\\.`,
    "im",
  ).exec(source);
  if (!match) return undefined;
  return match[1]
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("*"));
}

function conversionCompletenessDiagnostics(ir: ReportIR, classSource: string, filename: string): Diagnostic[] {
  const metadata = ir.programKind === "module-pool" ? ir.dynproMetadata : ir.screenMetadata;
  if (!metadata || !classSource) return [];
  const interfaceName = ir.programKind === "module-pool" ? "zif_gg_dynpro_v1" : "zif_gg_screen_provider_v1";
  const phases = [
    {key: "pbo", method: "process_output_module", label: "PBO"},
    {key: "pai", method: "process_input_module", label: "PAI"},
  ];
  return phases.flatMap(({key, method, label}) => {
    const screens = (metadata.flowLogic ?? []).filter((flow: Metadata) => (flow[key] ?? []).length > 0);
    if (!screens.length) return [];
    const body = generatedMethodBody(classSource, `${interfaceName}~${method}`);
    const executable = body?.some((line) => !/^RETURN\.$/i.test(line)) ?? false;
    if (executable) return [];
    const declared = screens.flatMap((flow: Metadata) => (flow[key] ?? []).map((entry: Metadata) => String(entry.name ?? entry).toUpperCase()));
    return [diagnostic({
      code: "GGCONV-E517",
      filename,
      construct: `${label} modules ${declared.join(", ")}`,
      message: `${label} screen modules are declared but the generated ${method} body is empty`,
      suggestion: "Preserve the declared module statements or keep the report on the known-failing conversion list until the lowering rule is implemented.",
      phase: "validate-generated",
    })];
  });
}

// The list settings of REPORT or PROGRAM: LINE-SIZE n, LINE-COUNT n(f),
// NO STANDARD PAGE HEADING and MESSAGE-ID.
function headerSettings(raw: string | undefined): ReportHeader {
  const ast = statementAst(String(raw ?? "").trim());
  const children = ast?.node.getChildren() ?? [];
  const number = (node: unknown) => node instanceof Nodes.ExpressionNode && node.get() instanceof Expressions.Integer ? Number(ast!.source(node)) : undefined;
  const lineCount = ast?.after("LINE-COUNT", ast.node);
  const at = lineCount ? children.indexOf(lineCount as Nodes.ExpressionNode) : -1;
  const footer = at >= 0 && children[at + 1]?.getFirstToken().getStr() === "(" ? number(children[at + 2]) : undefined;
  return {
    raw: raw ?? "",
    lineSize: number(ast?.after("LINE-SIZE", ast.node)),
    lineCount: number(lineCount),
    footerLines: footer,
    noStandardPageHeading: Boolean(ast?.hasPhrase("NO STANDARD PAGE HEADING")),
    messageId: ast?.operand("MESSAGE-ID")?.toUpperCase(),
  };
}

function includeIdentity(filename: string | undefined): string {
  return String(filename ?? "").replaceAll("\\", "/").toUpperCase();
}

function includeBase(filename: string): string {
  return includeIdentity(filename).split("/").at(-1)?.replace(/\.(?:(?:INCL|PROG)\.)?ABAP$/, "") ?? "";
}

function orderedStatements(parsedUnits: ParsedUnit[]): ParsedStatement[] {
  const units = new Map(parsedUnits.map((unit) => [includeIdentity(unit.filename), unit]));
  const childFor = (parent: string, name: string) => {
    const expected = String(name).toUpperCase();
    return parsedUnits.find((unit) => includeIdentity(unit.ancestry?.at(-1)) === includeIdentity(parent)
      && (includeIdentity(unit.filename) === expected || includeBase(unit.filename) === expected));
  };
  const expand = (unit: ParsedUnit, active = new Set<string>()): ParsedStatement[] => {
    const identity = includeIdentity(unit.filename);
    if (active.has(identity)) return [];
    const nextActive = new Set(active).add(identity);
    const result: ParsedStatement[] = [];
    for (const statement of unit.statements) {
      result.push(statement);
      if (statement.kind !== "Include") continue;
      const name = statementAst(statement.text)?.sourceOf(Expressions.IncludeName);
      const child = name ? childFor(unit.filename, name) : undefined;
      if (child) result.push(...expand(child, nextActive));
    }
    return result;
  };
  const root = parsedUnits[0];
  return root ? expand(root) : [...units.values()].flatMap((unit) => unit.statements);
}

function buildReportIR(parsed: ParseResult, resolved: ResolvedSources, options: NormalizedOptions): ReportIR {
  const serializable = (statement: ParsedStatement): Statement => {
    const { node: _parserNode, ...plain } = statement;
    return plain;
  };
  const allStatements = orderedStatements(parsed.units).map(serializable);
  renameStarWorkAreas(allStatements);
  const classification = classifyProgram(allStatements);
  const ir = emptyReportIR({
    filename: options.filename,
    source: resolved.units[0]?.source ?? options.source ?? "",
    sourceHash: resolved.sourceHash,
    newline: resolved.newline,
  });
  // A caller that knows the program object names it; the REPORT statement
  // may be a copy's leftover or sit in an include.
  ir.programName = options.programName ?? classification.programName;
  ir.programKind = classification.programKind;
  ir.units = parsed.units.map((unit) => ({ filename: unit.filename, ancestry: unit.ancestry }));
  ir.statements = allStatements;
  ir.header = headerSettings(classification.header?.text);
  ir.guiStatusMetadata = options.guiStatusMetadata ?? options.guiStatuses ?? {};
  collectLocalClasses(ir, allStatements);
  collectEvents(ir, allStatements);
  // A FORM's STRUCTURE s is typed LIKE s when s is a data object.
  ir.declarations = collectDeclarations(allStatements);
  collectRoutines(ir);
  collectHeaderLines(ir);
  ir.dynamicAlv = detectDynamicAlv(ir);
  ir.selections = collectSelectionScreens(ir.declarations);
  ir.safeFieldSymbols = [...new Set([
    ...analyzeFieldSymbols(ir),
    ...(ir.dynamicAlv?.fieldSymbols ?? []),
  ])].sort();
  ir.fieldSymbolReferences = fieldSymbolReferences(ir, ir.dynamicAlv?.fieldSymbols ?? []);
  ir.modules = collectModules(allStatements);
  const moduleStatements = new Set(ir.modules.flatMap((module) => module.statements));
  const programScope = lazyProgramScope(parsed.units, parsed.config, dictionaryIndex(options.dictionaryFiles));
  analyzeRoutineWrites(ir, programScope);
  ir.declarations.push(...liftInlineDeclarations(programScope, ir.eventBlocks
    .flatMap((block) => block.statements)
    .filter((statement) => !statement.localClassName && !moduleStatements.has(statement))));
  ir.sourceIndex = buildSourceIndex(ir);
  ir.statePlan = buildStatePlan(ir);
  ir.references = analyzeReferences(ir);
  ir.continuations = collectContinuations(allStatements, [
    ...ir.statePlan.globals,
    ...ir.statePlan.selections,
  ]);
  ir.controlFlowGraphs = buildControlFlowGraphs(ir);
  // The fields HIDE names, structure components by their full path.
  ir.hiddenNames = [...new Set(allStatements.flatMap((statement) => {
    if (statement.kind !== "Hide") return [];
    return hiddenFields(statement.text)
      .filter((part) => /^[A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)*$/i.test(part))
      .map((part) => part.toUpperCase());
  }))].sort();
  resolveTypes(ir, options);
  resolveSelectionTypes(ir, programScope);
  return ir;
}

function metadataTextPool(ir: ReportIR, options: NormalizedOptions): unknown {
  return options.textPool
    ?? ir.screenMetadata?.textPool
    ?? ir.dynproMetadata?.textPool;
}

function textFallbackDiagnostics(ir: ReportIR, options: NormalizedOptions): Diagnostic[] {
  const result: Diagnostic[] = [];
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
        const value = item[field];
        if (typeof value === "string" && /^TEXT[-_]/i.test(value)) {
          result.push(diagnostic({
            code: "GGCONV-W101",
            severity: "warning",
            filename: options.filename,
            start: item.span?.start,
            end: item.span?.end,
            construct: value,
            message: `text-pool entry ${value} was not supplied; deterministic fallback text is emitted`,
            suggestion: "Pass textPool metadata to resolve the original selection text.",
            phase: "selection-screen",
          }));
        }
      }
    }
  }
  return result;
}

function textPoolKey(key: unknown): string {
  return String(key ?? "").replace(/^TEXT[-_]/i, "").toUpperCase();
}

function textPoolLookup(textPool: unknown): (key: unknown) => string | undefined {
  const entries = new Map<string, string>();
  const add = (key: unknown, value: unknown) => {
    if (key !== undefined && value !== undefined && value !== "") {
      entries.set(textPoolKey(key), String(value));
    }
  };
  if (textPool instanceof Map) {
    for (const [key, value] of textPool) add(key, value);
  } else if (Array.isArray(textPool)) {
    for (const entry of textPool as Metadata[]) add(entry?.key, entry?.entry ?? entry?.text ?? entry?.value);
  } else if (textPool && typeof textPool === "object") {
    for (const [key, value] of Object.entries(textPool)) add(key, value);
  }
  if (entries.size) return (key) => entries.get(textPoolKey(key));
  if (typeof textPool === "string") {
    const parsed = new Map<string, string>();
    for (const line of textPool.replace(/^\uFEFF/, "").split(/\r?\n/)) {
      const match = /^\s*([^|=\t ]+)\s*(?:\||=|\t|\s{2,})\s*(.*?)\s*$/.exec(line);
      if (match && match[2]) parsed.set(textPoolKey(match[1]), match[2].replace(/^'(.*)'$/, "$1").replaceAll("''", "'"));
    }
    return (key) => parsed.get(textPoolKey(key));
  }
  return () => undefined;
}

function applyTextPool(ir: ReportIR, options: NormalizedOptions): void {
  const lookup = textPoolLookup(metadataTextPool(ir, options));
  const apply = (items: Metadata[] | undefined) => {
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
  for (const titlebar of Object.values<Metadata>(ir.screenMetadata?.titlebars ?? {})) {
    if (titlebar && typeof titlebar.text === "string") titlebar.text = lookup(titlebar.text) ?? titlebar.text;
  }
}

function applySelectionMetadata(ir: ReportIR, options: NormalizedOptions): void {
  const metadata = options.selectionMetadata;
  if (!metadata || typeof metadata !== "object") return;
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      const details = item.name ? metadata[item.name.toUpperCase()] : undefined;
      if (!details || typeof details !== "object") continue;
      if (details.dataType && typeof details.dataType === "object") item.dataType = { ...item.dataType, ...details.dataType };
    }
  }
}

function applyFunctionKeyMetadata(ir: ReportIR): void {
  const assignments = new Map<number, string>();
  // SSCRFIELDS-FUNCTXT_nn = 'text'.
  for (const statement of ir.statements) {
    const ast = statement.kind === "Move" ? statementAst(statement.text) : undefined;
    const key = /^SSCRFIELDS-FUNCTXT_(\d+)$/i.exec(ast?.sourceOf(Expressions.Target) ?? "")?.[1];
    const literal = ast?.findDirect(Expressions.Source)?.findDirectExpression(Expressions.Constant)?.getFirstChild();
    const text = literal && ast!.source(literal);
    if (key && text?.startsWith("'")) assignments.set(Number(key), text.slice(1, -1).replaceAll("''", "'"));
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

// ZCL_FOO -> ZCL_FOO_1, _2, ...; the stem is shortened to keep 30 characters.
function nextFreeClassName(name: string, taken: Set<string>): string {
  for (let index = 1; ; index++) {
    const suffix = `_${index}`;
    const candidate = `${name.slice(0, 30 - suffix.length)}${suffix}`;
    if (!taken.has(candidate)) return candidate;
  }
}

function validateNames(ir: ReportIR, options: NormalizedOptions, diagnostics: Diagnostic[]): void {
  let className = options.className ? options.className.toUpperCase() : defaultClassName(ir.programName ?? "");
  let renamedFrom;
  if (!className) {
    diagnostics.push(diagnostic({ code: "GGCONV-E101", filename: options.filename, construct: "target class", message: "a target class name is required for this report name", suggestion: "Pass className/--class with a valid ABAP global class name.", phase: "options" }));
  } else {
    try {
      className = normalizeObjectName(className, "class");
      const existingNames = new Set((Array.isArray(options.existingClassNames) ? options.existingClassNames : Array.isArray(options.existingClasses) ? options.existingClasses : [])
        .map((name) => String(name).toUpperCase()));
      if (existingNames.has(className) && options.className) {
        // An explicit name is what the caller asked for, so it is not replaced.
        diagnostics.push(diagnostic({ code: "GGCONV-E106", filename: options.filename, construct: className, message: `target class ${className} already exists`, suggestion: "Choose a different target class or perform an explicit, separately authorized replacement.", phase: "options" }));
      } else if (existingNames.has(className)) {
        renamedFrom = className;
        className = nextFreeClassName(className, existingNames);
      }
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-E101", filename: options.filename, construct: className, message: (error as Error).message, suggestion: "Use an uppercase ABAP class name of at most 30 characters.", phase: "options" }));
    }
  }
  // A report gets a transaction code only when one is given or a transaction
  // object starts it; otherwise it is generated with zif_gg_program_v1 and
  // listed as a report without a transaction. A module pool can only be
  // started through a transaction, so it defaults to its program name.
  const programRegistered = ir.programKind === "report" && Boolean(ir.programName);
  const withoutTransaction = programRegistered
    ? "the class is generated without zif_gg_transaction_v1, as a report without a transaction"
    : "the class is generated without zif_gg_transaction_v1, so it cannot be started as a transaction and the transaction registry cannot resolve a SUBMIT of it";
  let transactionCode;
  if (options.transactionCode) {
    try {
      transactionCode = normalizeTransactionCode(options.transactionCode);
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-W105", severity: "warning", filename: options.filename, construct: "transaction code", message: `${(error as Error).message}; ${withoutTransaction}`, suggestion: "Pass a valid scaffold transaction code.", phase: "options" }));
    }
  } else if (ir.programKind === "module-pool") {
    transactionCode = defaultTransactionCode(ir.programName ?? "");
    if (!transactionCode) diagnostics.push(diagnostic({ code: "GGCONV-W105", severity: "warning", filename: options.filename, construct: "transaction code", message: `the program name cannot be used as a scaffold transaction code; ${withoutTransaction}`, suggestion: "Pass transactionCode/--tcode explicitly.", phase: "options" }));
  }
  // SUBMIT derives the class from the program name, so a renamed or shortened
  // class is only found through the program in its transaction or program
  // metadata.
  const reachability = transactionCode
    ? "SUBMIT finds it through the transaction registry"
    : programRegistered
      ? "SUBMIT finds it through the program registry"
      : "without a transaction code, SUBMIT cannot find it";
  if (renamedFrom) {
    const location = options.existingClassFiles?.[renamedFrom];
    diagnostics.push(diagnostic({
      code: "GGCONV-W106",
      severity: "warning",
      filename: options.filename,
      construct: renamedFrom,
      message: `class ${renamedFrom} already exists${location ? ` in ${location}` : ""}; the report is generated as ${className} instead, and ${reachability}`,
      suggestion: "Pass className/--class to choose the name yourself.",
      phase: "options",
    }));
  }
  const fullName = options.className ? undefined : fullClassName(ir.programName ?? "");
  if (fullName && fullName.length > 30 && className && !diagnostics.some((item) => item.code === "GGCONV-E101")) {
    diagnostics.push(diagnostic({
      code: "GGCONV-W107",
      severity: "warning",
      filename: options.filename,
      construct: fullName,
      message: `class name ${fullName} exceeds 30 characters; the report is generated as ${className} instead, and ${reachability}`,
      suggestion: "Pass className/--class to choose the name yourself.",
      phase: "options",
    }));
  }
  ir.targetClassName = className;
  ir.transactionCode = transactionCode;
  const metadataDescription = ir.screenMetadata?.reportTitle ?? ir.dynproMetadata?.reportTitle;
  ir.reportTitle = metadataDescription;
  ir.description = options.descriptionProvided ? options.description : metadataDescription;
  if (ir.description === undefined || ir.description === "") {
    ir.description = ir.programName ?? transactionCode ?? className;
    if (ir.description) {
      diagnostics.push(diagnostic({
        code: "GGCONV-W108",
        severity: "warning",
        filename: options.filename,
        construct: ir.description,
        message: `no title was found for ${ir.description}; its name is used as the description`,
        suggestion: "Add a title (text pool entry R) to the .prog.xml, a short text to its transaction, or pass description/--description.",
        phase: "options",
      }));
    }
  }
}

function validateSymbolCollisions(ir: ReportIR, diagnostics: Diagnostic[]): void {
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

function buildSourceMap(ir: ReportIR): SourceMapSegment[] {
  const sourceMap: SourceMapSegment[] = [];
  for (const name of Object.keys(ir.events).filter((event) => ir.events[event].length)) {
    sourceMap.push({ source: name, output: `${ir.targetClassName}~${name}`, start: ir.events[name][0].span.start, end: ir.events[name].at(-1)!.span.end, segment: "event" });
    for (const statement of ir.events[name]) sourceMap.push({ source: name, output: `${ir.targetClassName}~${name}`, start: statement.span.start, end: statement.span.end, construct: statement.kind, segment: "statement" });
  }
  for (const routine of ir.routines) {
    for (const statement of routine.statements) sourceMap.push({ source: routine.name, output: `${ir.targetClassName}~${routine.methodName}`, start: statement.span.start, end: statement.span.end, construct: statement.kind, segment: "statement" });
  }
  sourceMap.sort((a, b) => a.start.line - b.start.line || a.start.column - b.start.column || a.segment.localeCompare(b.segment) || a.output.localeCompare(b.output));
  return sourceMap;
}

function addGeneratedLocations(classSource: string, sourceMap: SourceMapSegment[]): SourceMapSegment[] {
  const lines = classSource.split("\n");
  const methodLines = new Map<string, number>();
  for (let index = 0; index < lines.length; index++) {
    const match = /^\s*METHOD\s+(.+)\.$/i.exec(lines[index]);
    if (match) {
      const name = match[1].trim().toUpperCase();
      methodLines.set(name, index + 1);
      methodLines.set(name.split("~").at(-1)!, index + 1);
    }
  }
  return sourceMap.map((segment) => {
    const output = segment.output.toUpperCase();
    const line = methodLines.get(output) ?? methodLines.get(output.split("~").at(-1)!);
    return line ? { ...segment, outputStart: { line, column: 1 }, outputEnd: { line, column: 1 } } : segment;
  });
}

// The METHOD a generated line belongs to, if any.
function generatedMethodAt(source: string | undefined, line: number): string | undefined {
  const lines = String(source ?? "").split("\n").slice(0, line);
  for (let index = lines.length - 1; index >= 0; index--) {
    if (/^\s*ENDMETHOD\s*\./i.test(lines[index]) && index < line - 1) return undefined;
    const match = /^\s*METHOD\s+([^\s.]+)\s*\./i.exec(lines[index]);
    if (match) return match[1].toLowerCase();
  }
  return undefined;
}

// Says where in the generated source validation failed and what it rejected:
// the source location the diagnostic is mapped to is only the routine or
// event that produced the method.
export function generatedValidationDiagnostic(item: Diagnostic, unit: SourceUnit | undefined): Diagnostic {
  const method = generatedMethodAt(unit?.source, item.start.line);
  const where = `${item.filename} line ${item.start.line}${method ? `, METHOD ${method}` : ""}`;
  const rejected = item.construct && item.construct !== "parser input" ? `: ${item.construct}` : "";
  return {
    ...item,
    code: "GGCONV-E202",
    construct: item.construct,
    message: `generated class failed parser validation (${where}): ${item.message}${rejected}`,
    suggestion: "Fix the lowering rule before using generated source.",
    phase: "validate-generated",
  };
}

function normalizedStatementText(text: string | undefined): string {
  return String(text ?? "").replace(/\s+/g, " ").trim().toUpperCase();
}

function mapGeneratedDiagnostic(item: Diagnostic, sourceMap: SourceMapSegment[], generatedFilename: string, statements: Statement[] = []): Diagnostic {
  // A helper class has line numbers of its own, which the source map of the
  // main class does not describe.
  if (item.filename !== generatedFilename) return { ...item, internalLocation: { filename: item.filename, start: item.start, end: item.end } };
  const candidates = sourceMap.filter((segment) => segment.outputStart !== undefined && segment.outputStart.line <= item.start.line);
  const methodLine = Math.max(...candidates.map((segment) => segment.outputStart!.line));
  const method = candidates.filter((segment) => segment.outputStart!.line === methodLine);
  // The statement carried over as the rejected one, else the start of the
  // routine or event the method was generated from.
  const rejected = normalizedStatementText(item.construct);
  const statementAt = (segment: SourceMapSegment) => statements.find((statement) => statement.span?.start?.line === segment.start.line
    && statement.span?.start?.column === segment.start.column);
  const source = method.find((segment) => segment.segment === "statement" && rejected
      && normalizedStatementText(statementAt(segment)?.text) === rejected)
    ?? method.find((segment) => segment.segment === "event")
    ?? method[0];
  if (!source) return { ...item, internalLocation: { filename: generatedFilename, start: item.start, end: item.end } };
  return {
    ...item,
    filename: source.filename ?? generatedFilename,
    start: source.start,
    end: source.end,
    generatedLocation: { filename: generatedFilename, start: item.start, end: item.end },
  };
}

export async function convertProgram(input: ConvertOptions = {}): Promise<ConversionResult> {
  const options = normalizeOptions(input);
  const diagnostics: Diagnostic[] = [];
  const startedAt = Date.now();
  let timeLimitReported = false;
  const timeLimit = () => options.maxDurationMs > 0 && Date.now() - startedAt > options.maxDurationMs;
  const reportTimeLimit = () => {
    if (!timeLimit() || timeLimitReported) return;
    timeLimitReported = true;
    diagnostics.push(limitDiagnostic("GGCONV-E109", "conversion", "conversion exceeded the configured time limit", "Raise maxDurationMs deliberately or split the source into smaller units."));
  };
  const limitDiagnostic = (code: string, construct: string, message: string, suggestion: string) => diagnostic({
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
      diagnostics.push(diagnostic({ code: "GGCONV-E100", filename: options.filename, construct: "source", message: `unable to read source: ${(error as Error).message}`, suggestion: "Pass source text or a readable filename.", phase: "input" }));
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
  const resolved = await resolveSources({ source, filename: options.filename, resolveInclude: options.resolveInclude, includePaths: options.includePaths });
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
  const ir = buildReportIR(parsed, resolved, options);
  if (ir.programKind === "module-pool") {
    if (options.dynproMetadata) ir.dynproMetadata = options.dynproMetadata;
    else if (typeof options.resolveDynpro === "function") {
      try {
        ir.dynproMetadata = await options.resolveDynpro({ programName: ir.programName, filename: options.filename, source: ir.source.source });
      } catch (error) {
        diagnostics.push(diagnostic({ code: "GGCONV-E503", filename: options.filename, construct: "dynpro metadata", message: `dynpro metadata resolver failed: ${(error as Error).message}`, suggestion: "Return explicit screen and flow metadata from the resolver.", phase: "dynpro" }));
      }
    } else if (options.loadDynproMetadata !== false) {
      try {
        ir.dynproMetadata = await loadDynproMetadata({
          filename: options.filename,
          language: options.language,
          metadataFilename: options.dynproMetadataFilename,
          screenDirectory: options.dynproScreenDirectory,
          screenFiles: options.dynproScreenFiles,
        });
      } catch (error) {
        diagnostics.push(diagnostic({ code: "GGCONV-E503", filename: options.filename, construct: "dynpro metadata", message: (error as Error).message, suggestion: "Fix the report-owned .prog.xml and .prog.screen_NNNN.abap metadata files or supply dynproMetadata explicitly.", phase: "dynpro" }));
      }
    }
    if (ir.dynproMetadata) ir.dynproIR = dynproProgramIR(ir);
  } else if (ir.programKind === "report" && options.screenMetadata) {
    ir.screenMetadata = options.screenMetadata;
  } else if (ir.programKind === "report" && options.loadDynproMetadata !== false) {
    try {
      ir.screenMetadata = await loadDynproMetadata({
        filename: options.filename,
        language: options.language,
        metadataFilename: options.dynproMetadataFilename,
        screenDirectory: options.dynproScreenDirectory,
        screenFiles: options.dynproScreenFiles,
      });
    } catch (error) {
      diagnostics.push(diagnostic({ code: "GGCONV-E503", filename: options.filename, construct: "dynpro metadata", message: (error as Error).message, suggestion: "Fix the report-owned .prog.xml and .prog.screen_NNNN.abap metadata files or supply screenMetadata explicitly.", phase: "dynpro" }));
    }
  }
  if (ir.screenMetadata?.guiStatuses) ir.guiStatusMetadata = ir.screenMetadata.guiStatuses;
  else if (ir.dynproMetadata?.guiStatuses) ir.guiStatusMetadata = ir.dynproMetadata.guiStatuses;
  validateNames(ir, options, diagnostics);
  validateSymbolCollisions(ir, diagnostics);
  applyTextPool(ir, options);
  applySelectionMetadata(ir, options);
  applyFunctionKeyMetadata(ir);
  diagnostics.push(...textFallbackDiagnostics(ir, options));
  diagnostics.push(...scanCapabilities(ir, ir.statements, options));
  reportTimeLimit();
  selectInterfaces(ir);
  if (!ir.programName) diagnostics.push(diagnostic({ code: "GGCONV-E101", filename: options.filename, construct: "REPORT", message: "input is not an executable REPORT", suggestion: "Start the source with REPORT and supply a valid program name.", phase: "classify" }));
  if (!["report", "module-pool"].includes(ir.programKind) && ir.programName) diagnostics.push(diagnostic({ code: "GGCONV-E102", filename: options.filename, construct: ir.programKind, message: `${ir.programKind} sources are not executable report inputs`, suggestion: "Pass a REPORT source, or convert includes and other program types in their owning executable program.", phase: "classify" }));
  if (ir.programKind === "module-pool" && !ir.dynproMetadata && !diagnostics.some((item) => item.code === "GGCONV-E502")) diagnostics.push(diagnostic({ code: "GGCONV-E502", filename: options.filename, construct: "PROGRAM", message: "dynpro metadata is required for module-pool conversion", suggestion: "Use the dynpro frontend with explicit screen metadata.", phase: "capability" }));
  const sorted = sortDiagnostics(diagnostics);
  const supported = !sorted.some((item) => item.severity === "error" || item.code.startsWith("GGCONV-E")) && Boolean(ir.targetClassName);
  if (!supported && options.mode === "strict") {
    return { classSource: undefined, manifest: createManifest(ir, sorted, options), diagnostics: sorted, sourceMap: [], reportIR: ir, supported: false };
  }
  const usePartialStrategy = !supported && options.mode === "partial" && options.partialStrategy === "skeleton";
  const useDiagnosticShell = usePartialStrategy && requiresDiagnosticShell(sorted);
  const usePartialApplication = usePartialStrategy && !useDiagnosticShell;
  const classSource = useDiagnosticShell
    ? emitPartialSkeleton(ir, options, sorted)
    : usePartialApplication ? emitPartialApplication(ir, options, sorted)
    : applyStyleFixes(emitClassSource(ir, options), ir.targetClassName!);
  diagnostics.push(...conversionCompletenessDiagnostics(ir, classSource, options.filename));
  const helperSources = !useDiagnosticShell && !usePartialApplication
    ? emitHelperSources(ir, options).map((helper) => ({ ...helper, source: applyStyleFixes(helper.source, helper.className) }))
    : [];
  const sourceMap = addGeneratedLocations(classSource, buildSourceMap(ir));
  const generatedUnits = [
    { filename: `${ir.targetClassName}.clas.abap`, source: classSource, ancestry: [], newline: "\n" },
    ...helperSources.map((helper) => ({ filename: `${helper.className}.clas.abap`, source: helper.source, ancestry: [], newline: "\n" })),
  ];
  const generatedValidation = parseUnits(generatedUnits, generatedSourceConfig(config));
  diagnostics.push(...undeclaredFieldSymbolDiagnostics(generatedUnits));
  diagnostics.push(...systemIncludeDiagnostics(resolved.systemIncludes, generatedUnits, ir));
  diagnostics.push(...generatedValidation.diagnostics
    .map((item) => generatedValidationDiagnostic(item, generatedUnits.find((unit) => unit.filename === item.filename)))
    .map((item) => mapGeneratedDiagnostic(item, sourceMap, `${ir.targetClassName}.clas.abap`, ir.statements)));
  const finalDiagnostics = sortDiagnostics(diagnostics);
  const finalSupported = !finalDiagnostics.some((item) => item.severity === "error" || item.code.startsWith("GGCONV-E")) && Boolean(ir.targetClassName);
  const manifest = createManifest(ir, finalDiagnostics, options);
  // Also an error the generated source raised, as GGCONV-E202, leaves strict
  // mode without a class to write.
  if (!finalSupported && options.mode === "strict") {
    return { classSource: undefined, manifest, diagnostics: finalDiagnostics, sourceMap: [], reportIR: ir, supported: false };
  }
  const scaffold = lowerToScaffoldIR(ir, sourceMap);
  return { classSource, helperSources, manifest, diagnostics: finalDiagnostics, sourceMap, reportIR: ir, scaffoldIR: scaffold, supported: finalSupported };
}
