import { textLiteral } from "./abap-text.js";
import { bindsStatically, controlObjectTypes, iconWrite, literalAssignment, lowerStatements, rebindingCall, restoreFieldSymbols, selectionExpression, selectionType, startValueAssignment, systemFieldStartValue } from "../passes/lower-statements.js";
import { dynproStatesSetter, routineScreenStates, screenStateMembers, screenStatePlan, selectionStatesSetter, storedScreenStates } from "../passes/screen-states.js";
import { scaffoldIR } from "../ir/scaffold-ir.js";
import { hasProgramMetadata } from "../passes/select-interfaces.js";
import { BLOCK_BRANCHES, BLOCK_ENDS, BLOCK_OPENERS, closesBlock } from "../passes/blocks.js";
import { isPopupStatement, isSuspendingStatement } from "../passes/lower-continuations.js";
import { screenOkCode } from "../dynpro-metadata.js";
import { methodParameterType } from "../passes/collect-routines.js";
import { DEFAULT_SELECTION_SCREEN, selectionOptions } from "../passes/collect-selection-screens.js";
import type { SelectionOptions } from "../passes/collect-selection-screens.js";
import { eventQualifier } from "../passes/classify-program.js";
import { Expressions, Tokens } from "@abaplint/core";
import { isKeyword, leadingWords, lexedAst, statementAst } from "../abap/ast.js";
import { controlsDeclaration, declarationBody, declaredDataNames, declaredName, fieldSymbolsIn, mentions, methodDefinition } from "../abap/statements.js";
import { replaceIdentifiers } from "../passes/replace-identifiers.js";
import { hasHeaderLine, headerLineDeclarations, headerLinesIn, withoutHeaderLines } from "../passes/header-lines.js";
import { likeHeads, likeTyping, scopedMember } from "../passes/like-typing.js";
import { isReportGlobal } from "../passes/lower-state.js";
import type { LoweringContext, Replacement } from "../passes/lower-statements.js";
import type { ControlFrame, Declaration, Diagnostic, HelperSource, LocalClass, LocalClassMethod, Metadata, NormalizedOptions, ReportIR, Routine, RoutineParameter, SelectionElement, SelectionState, SourceMapSegment, Statement } from "../types.js";

/** A generated method; its string form is the METHOD ... ENDMETHOD block. */
interface GeneratedMethod {
  name: string;
  body: string[];
  comment?: string;
}

type ClassOptions = Pick<NormalizedOptions, "existingClassNames" | "existingClasses">;

const REPORT_METHODS = [
  "load_of_program", "get_logical_database", "get_list_processing", "build_screen", "initialization",
  "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of",
  "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_value_req",
  "at_selection_screen_help_req", "at_selection_screen_on_exit", "start_of_selection", "at_get", "at_get_late",
  "end_of_selection",
];
const LIST_METHODS = ["get_settings", "top_of_page", "end_of_page", "top_of_page_during_line_sel", "at_line_selection", "at_user_command", "at_pf"];

function indent(text: string, spaces = 2): string {
  let level = 0;
  const cases: { branch: boolean }[] = [];
  let selectDepth = 0;
  const lines: string[] = [];
  for (const original of text.split("\n")) {
    const relative = original.match(/^\s*/)?.[0].length ?? 0;
    const line = original.trim();
    if (!line) {
      lines.push("");
      continue;
    }
    const upper = line.toUpperCase();
    const isCase = /^CASE\b/.test(upper);
    const isWhen = /^WHEN\b/.test(upper);
    const isEndCase = /^ENDCASE\b/.test(upper);
    const isTry = /^TRY\b/.test(upper);
    const isEndTry = /^ENDTRY\b/.test(upper);
    const isSelect = /^SELECT\b/.test(upper) && !/\bINTO\s+TABLE\b/.test(upper);
    const isEndSelect = /^ENDSELECT\b/.test(upper);
    if (isEndCase) {
      const frame = cases.pop();
      if (frame?.branch) level = Math.max(0, level - 1);
      level = Math.max(0, level - 1);
    }
    const closes = !isWhen && !isEndCase && !isEndTry && /^(END(?:IF|DO|LOOP|SELECT|TRY|WHILE|AT|FORM)|ELSEIF\b|ELSE\b|CATCH\b|CLEANUP\b)/.test(upper)
      && (!isEndSelect || selectDepth > 0);
    if (isWhen && cases.at(-1)?.branch) level = Math.max(0, level - 1);
    if (closes) level = Math.max(0, level - 1);
    if (isEndTry) level = Math.max(0, level - 2);
    const prefix = line.startsWith("*") ? "" : " ".repeat(spaces + (level * 2) + relative);
    lines.push(`${prefix}${line}`);
    if (isEndSelect) selectDepth = Math.max(0, selectDepth - 1);
    if (isCase) {
      cases.push({ branch: false });
      level++;
    } else if (isWhen) {
      const frame = cases.at(-1);
      if (frame) frame.branch = true;
      level++;
    } else if (isSelect) {
      selectDepth++;
      level++;
    } else if (isTry) level += 2;
    else if (!isEndCase && /^(IF\b|DO\b|LOOP\b|WHILE\b|CATCH\b|CLEANUP\b)/.test(upper)) level++;
    if (/^ELSEIF\b|^ELSE\b/.test(upper)) level++;
  }
  return lines.join("\n");
}

function literal(value: unknown): string {
  return `'${String(value ?? "").replaceAll("'", "''")}'`;
}

function renameIdentifiers(text: string, renames: Record<string, string> = {}): string {
  return replaceIdentifiers(text, Object.entries(renames).map(([from, to]) => [from, to.toLowerCase()]));
}

function allRenames(ir: ReportIR): Record<string, string> {
  return { ...(ir.statePlan?.renames ?? {}), ...(ir.localClassRenames ?? {}), ...continuationRenames(ir) };
}

function globalMemberNames(ir: ReportIR): Record<string, string> {
  const routineStatements = new Set((ir.routines ?? []).flatMap((routine) => routine.statements ?? []));
  const dynproModuleStatements = new Set((ir.modules ?? []).flatMap((module) => module.statements ?? []));
  const global = (item: Declaration) => !routineStatements.has(item.statement)
    && !dynproModuleStatements.has(item.statement)
    && item.statement?.scope !== "local"
    && !item.statement?.localClassName;
  const result: Record<string, string> = {};
  for (const declaration of ir.declarations ?? []) {
    if (!global(declaration) || !["data", "static", "tables", "ranges"].includes(declaration.kind)) continue;
    for (const name of declaration.names ?? []) {
      result[name] = ir.statePlan?.renames?.[name] ?? name.toLowerCase();
    }
  }
  // The work areas of header-line tables are members too.
  for (const [name, header] of Object.entries(ir.headerLines?.global ?? {})) {
    result[name] ??= ir.statePlan?.selectionState?.[name]?.member ?? name.toLowerCase();
    result[header.toUpperCase()] = header;
  }
  return result;
}

function continuationLocalNames(ir: ReportIR): Set<string> {
  const routineStatements = new Set((ir.routines ?? []).flatMap((routine) => routine.statements ?? []));
  const dynproModuleStatements = new Set((ir.modules ?? []).flatMap((module) => module.statements ?? []));
  const global = (item: Declaration) => !routineStatements.has(item.statement)
    && !dynproModuleStatements.has(item.statement)
    && item.statement?.scope !== 'local'
    && !item.statement?.localClassName;
  const localDeclarations = (ir.declarations ?? [])
    .filter((item) => !global(item)
      && !item.statement?.localClassName
      && ['data', 'static'].includes(item.kind));
  const declaredBefore = (declaration: Declaration, continuation: { filename: string; span: Statement["span"] }) => {
    const declarationSpan = declaration.statement?.span;
    const continuationSpan = continuation.span;
    if (!declarationSpan?.start || !continuationSpan?.start
      || declaration.statement?.filename !== continuation.filename) return true;
    return declarationSpan.start.line < continuationSpan.start.line
      || (declarationSpan.start.line === continuationSpan.start.line
        && declarationSpan.start.column <= continuationSpan.start.column);
  };
  const localNames = new Set((ir.declarations ?? [])
    .filter((item) => !global(item) && ['data', 'static'].includes(item.kind))
    .flatMap((item) => item.names ?? [])
    .map((name) => name.toUpperCase()));
  const moduleNames: (string | undefined)[] = [];
  let structureDepth = 0;
  for (const item of ir.declarations ?? []) {
    if (!dynproModuleStatements.has(item.statement)) continue;
    if (item.kind === 'databegin') {
      if (structureDepth === 0) moduleNames.push(declaredName(item.raw));
      structureDepth++;
    } else if (item.kind === 'dataend') structureDepth--;
    else if (structureDepth === 0 && ['data', 'static'].includes(item.kind)) moduleNames.push(...item.names ?? []);
  }
  return new Set([...moduleNames, ...(ir.continuations ?? [])
    .filter((continuation) => continuation.liveVariables?.length)
    .flatMap((continuation) => (continuation.liveVariables ?? [])
      .filter((name) => localNames.has(name.toUpperCase()))
      .filter((name) => localDeclarations.some((declaration) =>
        (declaration.names ?? []).some((declaredName) => declaredName.toUpperCase() === name.toUpperCase())
          && declaredBefore(declaration, continuation))))
    .map((name) => name.toUpperCase())].filter((name): name is string => Boolean(name))
  );
}

function continuationRenames(ir: ReportIR): Record<string, string> {
  return Object.fromEntries([...continuationLocalNames(ir)].sort().map((name) => [name, `mv_ggconv_${name.toLowerCase()}`]));
}

function prepareLocalClassNames(ir: ReportIR, options: ClassOptions = {}): Record<string, string> {
  const target = String(ir.targetClassName ?? "ZCL_CONVERTED").toUpperCase().replace(/[^A-Z0-9_]/g, "_");
  const used = new Set([
    target,
    ...(options.existingClassNames ?? options.existingClasses ?? []).map((name) => String(name).toUpperCase()),
  ]);
  const stem = target.slice(0, 24);
  const renames: Record<string, string> = {};
  for (const [index, localClass] of (ir.localClasses ?? []).entries()) {
    let suffix = `_H${index + 1}`;
    let candidate = `${stem}${suffix}`.slice(0, 30);
    let collision = 1;
    while (used.has(candidate)) {
      suffix = `_H${index + 1}_${collision++}`;
      candidate = `${stem.slice(0, 30 - suffix.length)}${suffix}`;
    }
    used.add(candidate);
    renames[localClass.name] = candidate;
    localClass.generatedName = candidate;
  }
  ir.localClassRenames = renames;
  return renames;
}

// A cx_root handler that named no target is given this one, so it can pass
// the host's control-flow unwinding on; one declaration serves the method.
function withControlFlowGuard(body: string[]): string[] {
  const lines = body.flatMap((line) => String(line).split("\n"));
  if (!lines.some((line) => /\bINTO\s+lx_ggconv_caught\./i.test(line))) return body;
  return ["DATA lx_ggconv_caught TYPE REF TO cx_root.", ...body];
}

function method(name: string, body: string[], comment?: string): GeneratedMethod {
  const entry: GeneratedMethod = { name, body: body.length ? withControlFlowGuard(hoistDeclarations([...body])) : ["RETURN."] };
  if (comment) entry.comment = comment;
  Object.defineProperty(entry, "toString", {
    enumerable: false,
    value: () => {
      const lines = [`  METHOD ${entry.name}.`];
      if (entry.comment) lines.push(`* ${entry.comment}`);
      lines.push(indent(entry.body.join("\n"), 4));
      lines.push("  ENDMETHOD.", "");
      return lines.join("\n");
    },
  });
  return entry;
}

function addWriterDeclaration(body: string[]): string[] {
  const declaration = "DATA(lo_writer) = io_session->get_list( )->get_writer( ).";
  const fieldSymbols: string[] = [];
  const generatedData: string[] = [];
  const rest: string[] = [];
  const flatBody = body.flatMap((line) => String(line).split("\n"));
  // The method's own declarations stay first: a field symbol hoisted from
  // further down may be typed LIKE LINE OF one of them. The comment above a
  // FORM comes before its declarations.
  let leading = 0;
  while (leading < flatBody.length && /^\s*(?:(?:DATA|TYPES|CONSTANTS|FIELD-SYMBOLS)\s|\*|")/i.test(flatBody[leading])) leading++;
  const declarations = flatBody.slice(0, leading);
  for (const line of flatBody.slice(leading)) {
    if (/^\s*FIELD-SYMBOLS\b/i.test(line)) fieldSymbols.push(line);
    else if (/^\s*DATA\s+lv_ggconv_dynamic_name\s+TYPE\s+string\.\s*$/i.test(line)) generatedData.push(line);
    else if (line.trim() !== declaration) rest.push(line);
  }
  const unique = (items: string[]) => [...new Set(items)];
  const fields = unique(fieldSymbols);
  const data = unique(generatedData);
  if (!fields.length && !data.length) return body.some((line) => line.trim() === declaration) ? body : [declaration, ...body];
  return [...declarations, ...fields, ...data, declaration, ...rest];
}

// The program in the transaction metadata lets SUBMIT find the class through
// the transaction registry, whatever the class is called.
function programField(ir: ReportIR): string {
  return ir.programName ? ` program = '${ir.programName}'` : "";
}

// A report no transaction starts declares its program instead, which lists it
// in the workbench and lets SUBMIT find it through the program registry.
function programMethod(ir: ReportIR, description = ir.description): GeneratedMethod {
  return method("zif_gg_program_v1~get_program", [
    `rs_program = VALUE #( program = ${literal(ir.programName)} description = ${literal(description)} ).`,
  ]);
}

function interfaceOrder(ir: ReportIR): string[] {
  const order = ["zif_gg_report_v1", "zif_gg_screen_provider_v1", "zif_gg_dynpro_v1", "zif_gg_context_menu_v1", "zif_gg_transaction_v1", "zif_gg_program_v1", "zif_gg_list_processing_v1", "zif_gg_resumable_v1"];
  return order.filter((name) => ir.interfaces.includes(name));
}

function contextMenuRoutine(ir: ReportIR): Routine | undefined {
  return (ir.routines ?? []).find((routine) => /^ON_CTMENU(?:_|$)/i.test(String(routine.name ?? "")));
}

function header({ className, ir }: { className: string; ir: ReportIR }): string {
  return [
    "* Generated by open-abap-gui converter.",
    `* Source object: ${ir.programName ?? "UNKNOWN"}`,
    `* Source file: ${ir.source.filename}`,
    `* Source SHA-256: ${ir.source.sourceHash}`,
    `* Target class: ${className}`,
    "* This file is generated migration output; it is safe to edit after review.",
    "",
  ].join("\n");
}

function implicitSelectionLayoutMembers(ir: ReportIR): string[] {
  const names = new Set<string>();
  for (const screen of ir.selections ?? []) {
    if (screen.titleField) names.add(screen.titleField);
    for (const item of screen.elements ?? []) {
      if (item.kind !== "layout") continue;
      for (const value of [item.text, item.title]) {
        if (/^[A-Z][A-Z0-9_]*$/i.test(String(value ?? ""))) names.add(String(value).toUpperCase());
      }
    }
  }
  return [...names].sort();
}

const LENGTH_TYPES = new Set(["c", "n", "x", "p"]);

// The member holding a PARAMETERS value gets the type the parameter declares, so
// arithmetic, formatting and typed method calls behave as in the report. The
// screen transports values as strings; assignment converts in both directions.
// Types are assumed to exist, as for DATA declarations.
// The class member standing for a report data object: another parameter or
// select-option, or a report global, possibly renamed. Undefined when the name
// is not one, e.g. a dictionary structure in LIKE mara-matnr.
function reportMember(ir: ReportIR, base: string): string | undefined {
  const tables = (ir.declarations ?? []).find((item) => item.kind === "tables" && item.names?.includes(base));
  if (tables && !tables.resolved) return undefined;
  return ir.statePlan?.selectionState?.[base]?.member
    ?? ir.statePlan?.renames?.[base]?.toLowerCase()
    ?? (ir.statePlan?.globals?.includes(base)
      || (ir.declarations ?? []).some((item) => item.kind === "constant" && item.statement?.scope !== "local" && item.names?.includes(base))
      ? base.toLowerCase() : undefined);
}

// SELECT-OPTIONS and RANGES ... FOR target get a range table of the target's
// type, so LOW and HIGH compare, convert and pass to typed parameters as in the
// report. A dynamic FOR (name) has no static type; its LOW and HIGH are strings,
// as the screen transports them. Inside a chain the target still carries the
// comma that separates it from the next element.
function rangeType(ir: ReportIR, target: string | undefined, member: (base: string) => string | undefined = (base) => reportMember(ir, base)): string {
  const match = /^([A-Z][A-Z0-9_\/]*)((?:-[A-Z][A-Z0-9_]*)*)$/i.exec(String(target ?? "").trim().replace(/\s*[,.]$/, ""));
  if (!match) return "TYPE RANGE OF string";
  const resolved = member(match[1].toUpperCase());
  return resolved
    ? `LIKE RANGE OF ${resolved}${match[2].toLowerCase()}`
    : `TYPE RANGE OF ${`${match[1]}${match[2]}`.toLowerCase()}`;
}

// The additions of the PARAMETERS or SELECT-OPTIONS behind a selection state.
function stateOptions(ir: ReportIR, name: string): SelectionOptions {
  const element = (ir.selections ?? []).flatMap((screen) => screen.elements ?? []).find((item) => item.name?.toUpperCase() === name);
  return selectionOptions(element?.raw);
}

function selectionStateType(ir: ReportIR, name: string, state: SelectionState): string {
  const options = stateOptions(ir, name);
  if (state.ranges) return rangeType(ir, options.for);
  if (options.type) {
    const type = options.type.toLowerCase();
    if (!LENGTH_TYPES.has(type)) return `TYPE ${type}`;
    const length = options.length ?? options.fieldLength;
    return `TYPE ${type}${length ? ` LENGTH ${length}` : ""}${options.decimals ? ` DECIMALS ${options.decimals}` : ""}`;
  }
  if (options.like) {
    const [head, ...components] = options.like.split("-");
    const path = components.map((component) => `-${component.toLowerCase()}`).join("");
    const member = reportMember(ir, head.toUpperCase());
    return member ? `LIKE ${member}${path}` : `TYPE ${options.like.toLowerCase()}`;
  }
  // PARAMETERS without a type is c, of length 1 when no length is given, as a
  // checkbox or radio button always is.
  if (options.checkbox || options.radioGroup) return "TYPE c LENGTH 1";
  return `TYPE c LENGTH ${options.fieldLength ?? 1}`;
}

// A component declared without TYPE or LIKE, as in line(5000), is c.
function typedComponent(component: string): string {
  const match = /^([A-Z][A-Z0-9_]*)(?:\(\s*(\d+)\s*\))?$/i.exec(component);
  return match ? `${match[1]} TYPE c LENGTH ${match[2] ?? 1}` : component;
}

// Re-emits a BEGIN OF ... END OF structure as one chain. INCLUDE TYPE and
// INCLUDE STRUCTURE are statements of their own, so they break the chain.
function structuredDeclaration(keyword: string, beginName: string | undefined, components: string[], endName: string | undefined): string {
  const statements: string[] = [];
  let chain = [`BEGIN OF ${beginName}`];
  for (const component of components) {
    if (/^INCLUDE\s+(?:TYPE|STRUCTURE)\b/i.test(component)) {
      if (chain.length) statements.push(`${keyword}: ${chain.join(", ")}.`);
      statements.push(`${component}.`);
      chain = [];
    } else {
      chain.push(component);
    }
  }
  chain.push(`END OF ${endName}`);
  statements.push(`${keyword}: ${chain.join(", ")}.`);
  return statements.join(" ");
}

function isGlobalDeclaration(ir: ReportIR): (item: Declaration) => boolean {
  const routineStatements = new Set((ir.routines ?? []).flatMap((routine) => routine.statements ?? []));
  const dynproModuleStatements = new Set((ir.modules ?? []).flatMap((module) => module.statements ?? []));
  return (item) => !routineStatements.has(item.statement)
    && (dynproModuleStatements.has(item.statement) || item.statement?.scope !== "local")
    && !item.statement?.localClassName;
}

function beginName(declaration: Declaration): string | undefined {
  return declaredName(declaration.raw);
}

// The program's data objects a declaration may name in LIKE, by the name they
// have before the renames: a parameter or select-option is its member. A
// TABLES work area, *dbtab's star_dbtab included, is typed by its table, see
// like-typing.ts.
function globalLikeMember(ir: ReportIR): (name: string) => string | { type: string } | undefined {
  const names = new Map<string, string | { type: string }>();
  const global = isGlobalDeclaration(ir);
  for (const declaration of ir.declarations ?? []) {
    if (!global(declaration)) continue;
    if (declaration.kind === "tables") {
      for (const name of declaration.names ?? []) names.set(name.toUpperCase(), { type: (declaration.table ?? name).toLowerCase() });
    } else if (["data", "static", "ranges", "constant"].includes(declaration.kind)) {
      for (const name of declaration.names ?? []) names.set(name.toUpperCase(), name.toLowerCase());
    } else if (["databegin", "constantbegin"].includes(declaration.kind) && beginName(declaration)) {
      names.set(beginName(declaration)!.toUpperCase(), beginName(declaration)!.toLowerCase());
    }
  }
  for (const [name, header] of Object.entries(ir.headerLines?.global ?? {})) {
    names.set(name, name.toLowerCase());
    names.set(header.toUpperCase(), header);
  }
  for (const [name, state] of Object.entries(ir.statePlan?.selectionState ?? {})) {
    names.set(name, state.member);
    names.set(state.member.toUpperCase(), state.member);
  }
  return (name) => names.get(name);
}

// The program's data declared VALUE sy-repid or another system field: as a
// member it is declared without VALUE, and LOAD-OF-PROGRAM assigns the start
// value, see systemFieldStartValue.
function globalStartValues(ir: ReportIR) {
  const global = isGlobalDeclaration(ir);
  return (ir.declarations ?? [])
    .filter((item) => global(item) && ["data", "static"].includes(item.kind) && !item.complex && !item.component && !hasHeaderLine(item))
    .map((item) => systemFieldStartValue(item.raw))
    .filter((start): start is NonNullable<typeof start> => Boolean(start));
}

function dataMembers(ir: ReportIR): string[] {
  const typeMembers: string[] = [];
  const constantMembers: string[] = [];
  const dataMembers: string[] = [];
  const declarations = ir.declarations ?? [];
  const consumed = new Set<number>();
  const global = isGlobalDeclaration(ir);
  const likeMember = globalLikeMember(ir);
  const rename = (text: string) => renameIdentifiers(likeTyping(text, likeMember), allRenames(ir));
  const headerLines = ir.headerLines?.global ?? {};
  const isDataObject = (operand: string) => Boolean(reportMember(ir, operand.split("-")[0].toUpperCase()));
  const addStructured = (index: number, begin: string, end: string, keyword: string, target: string | undefined, endTarget?: string) => {
    const components: string[] = [];
    for (let cursor = index + 1; cursor < declarations.length; cursor++) {
      consumed.add(cursor);
      if (declarations[cursor].kind === begin || declarations[cursor].kind === "includetype") {
        // A component ends in "," inside a chain and in "." where the chain was
        // broken, e.g. before INCLUDE TYPE; the structure is re-emitted as one
        // chain, so the terminator is replaced by a comma.
        const component = declarationBody(declarations[cursor].raw, keyword);
        if (component) components.push(rename(typedComponent(component)));
      }
      if (declarations[cursor].kind === end) {
        const endName = endTarget ?? declaredName(declarations[cursor].raw) ?? target;
        const declaration = structuredDeclaration(keyword, target, components, endName);
        (({ TYPES: typeMembers, CONSTANTS: constantMembers } as Record<string, string[]>)[keyword] ?? dataMembers).push(rename(declaration));
        break;
      }
    }
    consumed.add(index);
  };
  const rangeMember = (item: Declaration) => {
    const name = item.names?.[0]?.toLowerCase();
    if (!name) return undefined;
    // RANGES creates a four-column selection range table of the FOR target.
    return `DATA ${name} ${rangeType(ir, item.target)}.`;
  };
  for (let index = 0; index < declarations.length; index++) {
    const item = declarations[index];
    if (!global(item) || consumed.has(index)) continue;
    if (item.kind === "databegin" || item.kind === "typebegin") {
      const begin = declaredName(item.raw);
      const keyword = item.kind === "typebegin" ? "TYPES" : "DATA";
      // BEGIN OF itab OCCURS n: the structure is the header line, see header-lines.ts.
      const header = item.kind === "databegin" && statementAst(item.raw)?.hasPhrase("OCCURS") ? headerLines[begin?.toUpperCase() ?? ""] : undefined;
      addStructured(index, item.kind === "typebegin" ? "type" : "data", item.kind === "typebegin" ? "typeend" : "dataend", keyword, header ?? begin, header);
      if (header) dataMembers.push(rename(`DATA ${begin!.toLowerCase()} LIKE STANDARD TABLE OF ${header} WITH DEFAULT KEY.`));
    } else if (item.kind === "constantbegin") {
      addStructured(index, "constant", "constantend", "CONSTANTS", declaredName(item.raw));
    } else if (item.kind === "type" && !item.complex) {
      typeMembers.push(rename(item.raw.replace(/,\s*$/, ".")));
    } else if (item.kind === "constant" && !item.complex) {
      constantMembers.push(rename(item.raw.replace(/,\s*$/, ".")));
    } else if ((item.kind === "data" || item.kind === "static") && !item.complex) {
      const declarationRaw = item.raw.replace(/,\s*$/, ".");
      const declaration = item.kind === "static"
        ? declarationRaw.replace(/^STATICS\b/i, "DATA")
        : declarationRaw;
      const header = hasHeaderLine(item) ? headerLines[item.names?.[0]?.toUpperCase() ?? ""] : undefined;
      // LOAD-OF-PROGRAM assigns a start value read from a system field, see globalStartValues.
      const start = ir.interfaces?.includes("zif_gg_report_v1") ? systemFieldStartValue(declaration) : undefined;
      if (header) dataMembers.push(...headerLineDeclarations(declaration, header, isDataObject, headerLines).map(rename));
      else dataMembers.push(rename(withoutHeaderLines(start?.declaration ?? declaration, headerLines)));
    } else if (item.kind === "tables" && item.resolved && !item.complex) {
      dataMembers.push(rename(`DATA ${item.names?.[0]?.toLowerCase()} TYPE ${item.type}.`));
    } else if (item.kind === "ranges") {
      const declaration = rangeMember(item);
      if (declaration) dataMembers.push(rename(declaration));
      const header = headerLines[item.names?.[0]?.toUpperCase() ?? ""];
      if (declaration && header) dataMembers.push(rename(`DATA ${header} LIKE LINE OF ${item.names![0].toLowerCase()}.`));
    }
  }
  const eventReferences = new Map<string, Set<string>>();
  for (const [event, statements] of Object.entries(ir.events ?? {})) {
    for (const declaration of declarations) {
      if (!global(declaration)) continue;
      const name = declaration.names?.[0]?.toUpperCase();
      if (!name || !["data", "static"].includes(declaration.kind)) continue;
      if (statements.some((statement) => statement === declaration.statement || mentions(statement.text, name))) {
        const events = eventReferences.get(name) ?? new Set();
        events.add(event);
        eventReferences.set(name, events);
      }
    }
  }
  const emittedNames = new Set(dataMembers.flatMap((member) => declaredDataNames(member)));
  for (const declaration of declarations) {
    const name = declaration.names?.[0]?.toUpperCase();
    if (!name || emittedNames.has(name) || !["data", "static"].includes(declaration.kind) || (eventReferences.get(name)?.size ?? 0) < 2) continue;
    dataMembers.push(rename(declaration.raw.replace(/,\s*$/, ".")));
    emittedNames.add(name);
  }
  for (const name of continuationLocalNames(ir)) {
    const declaration = declarations.find((item) => ['data', 'static'].includes(item.kind)
      && (item.names ?? []).some((itemName) => itemName.toUpperCase() === name));
    if (!declaration || declaration.complex || emittedNames.has((continuationRenames(ir)[name] ?? name).toUpperCase())) continue;
    const raw = declaration.kind === 'static'
      ? declaration.raw.replace(/^STATICS\b/i, 'DATA')
      : declaration.raw;
    dataMembers.push(rename(raw.replace(/,\s*$/, '.')));
  }
  const declaredNames = new Set((declarations ?? []).flatMap((item) => item.names ?? []).map((name) => name.toUpperCase()));
  for (const name of implicitSelectionLayoutMembers(ir)) {
    if (!declaredNames.has(name)) dataMembers.push(`DATA ${name.toLowerCase()} TYPE string.`);
  }
  if (selectionTabbedBlocks(ir).length) {
    dataMembers.push("DATA mv_active_tab TYPE string.");
  }
  // The binding of a global field symbol that outlives the method making it.
  for (const { member } of Object.values(ir.fieldSymbolReferences ?? {})) dataMembers.push(`DATA ${member} TYPE REF TO data.`);
  const dynamicTypes = ir.dynamicAlv
    ? [
      `TYPES: BEGIN OF ${ir.dynamicAlv.rowType},`,
      ...ir.dynamicAlv.typeFields.map((field) => `         ${field.name.toLowerCase()} TYPE ${field.type},`),
      `       END OF ${ir.dynamicAlv.rowType}.`,
      `TYPES ${ir.dynamicAlv.tableType} TYPE STANDARD TABLE OF ${ir.dynamicAlv.rowType} WITH EMPTY KEY.`,
    ]
    : [];
  // LIKE can only name an attribute declared earlier, so data typed LIKE a
  // parameter's member, or LIKE such data, comes after the selection members.
  const selectionMembers = new Set(Object.values(ir.statePlan?.selectionState ?? {}).map((state) => state.member.toUpperCase()));
  const deferredNames = new Set<string>();
  const deferredMembers: string[] = [];
  const earlyMembers = dataMembers.filter((member) => {
    if (!likeHeads(member).some((name) => selectionMembers.has(name) || deferredNames.has(name))) return true;
    for (const name of declaredDataNames(member, true)) deferredNames.add(name);
    deferredMembers.push(member);
    return false;
  });
  const members = [...typeMembers, ...dynamicTypes, ...constantMembers, ...earlyMembers, ...screenStateMembers(ir)];
  if (ir.dynamicAlv) members.push(`DATA ${ir.dynamicAlv.tableMember.toLowerCase()} TYPE ${ir.dynamicAlv.tableType}.`);
  for (const statement of ir.statements ?? []) {
    if (statement.kind !== "Controls") continue;
    const controls = controlsDeclaration(statement.text);
    if (!controls || !["TABLEVIEW", "TABSTRIP"].includes(controls.type)) continue;
    const type = controls.type === "TABSTRIP" ? "ty_tabstrip_runtime" : "ty_table_runtime";
    members.push(`DATA ${controls.name.toLowerCase()} TYPE zif_gg_dynpro_types_v1=>${type}.`);
  }
  // `LIKE` can only name an attribute declared earlier, so a parameter declared
  // LIKE another parameter comes after it.
  const selectionState = ir.statePlan?.selectionState ?? {};
  const emitted = new Set<string>();
  const emitSelection = (name: string) => {
    if (emitted.has(name)) return;
    emitted.add(name);
    const state = selectionState[name];
    const options = stateOptions(ir, name);
    const like = (options.like ?? options.for)?.split("-")[0].toUpperCase();
    if (like && selectionState[like]) emitSelection(like);
    members.push(`DATA ${state.member} ${selectionStateType(ir, name, state)}.`);
    // SELECT-OPTIONS has a header line, see header-lines.ts.
    const header = state.ranges ? ir.headerLines?.global?.[name] : undefined;
    if (header) members.push(`DATA ${header} LIKE LINE OF ${state.member}.`);
  };
  Object.keys(selectionState).forEach(emitSelection);
  members.push(...deferredMembers);
  for (const routine of ir.routines) {
    const parameters = routine.parameters ?? [];
    const parameterType = methodParameterType;
    for (const parameter of parameters.filter((item) => item.lineType)) {
      members.push(renameIdentifiers(`TYPES ${parameter.type} TYPE STANDARD TABLE OF ${parameter.lineType} WITH DEFAULT KEY.`, allRenames(ir)));
    }
    const lines = [`METHODS ${routine.methodName}`];
    const importing = parameters.filter((parameter) => parameter.direction === "IMPORTING");
    const declared = (parameter: RoutineParameter) => parameter.byValue ? `VALUE(${parameter.name})` : parameter.name;
    const width = Math.max("io_session".length, ...parameters.map((parameter) => declared(parameter).length));
    const line = (parameter: RoutineParameter) => `    ${declared(parameter).padEnd(width, " ")} TYPE ${renameIdentifiers(parameterType(parameter), allRenames(ir))}`;
    lines.push("  IMPORTING", `    io_session${" ".repeat(width - "io_session".length)} TYPE REF TO zif_gg_session_v1`);
    lines.push(...importing.map(line));
    for (const direction of ["CHANGING"]) {
      const items = parameters.filter((parameter) => parameter.direction === direction);
      if (!items.length) continue;
      lines.push(`  ${direction}`, ...items.map(line));
    }
    lines[lines.length - 1] = `${lines.at(-1)}.`;
    members.push(lines.join("\n"));
  }
  return members;
}

function selectionDataType(item: SelectionElement): string {
  if (!item.dataType?.typ) return selectionType(selectionOptions(item.raw));
  const fields: string[] = [];
  if (item.dataType.rollname) fields.push(`rollname = '${item.dataType.rollname}'`);
  fields.push(`typ = '${item.dataType.typ}'`);
  if (item.dataType.length !== undefined) fields.push(`length = ${item.dataType.length}`);
  if (item.dataType.decimals !== undefined) fields.push(`decimals = ${item.dataType.decimals}`);
  return `VALUE #( ${fields.join(" ")} )`;
}

function selectionDefault(item: SelectionElement): string | undefined {
  const value = item.default;
  if (!value) return undefined;
  if (/^'(?:''|[^'])*'$|^\|[^|]*\|$/s.test(value)) return value;
  // CONV string( 3 ) is '3 ', the blank reserved for the sign.
  if (/^\d+$/.test(value)) return `'${value}'`;
  return `CONV string( ${value} )`;
}

function decodeAbapLiteral(value: string): string {
  return String(value ?? "").replace(/^'/, "").replace(/'$/, "").replaceAll("''", "'");
}

function staticSelectionText(ir: ReportIR, token: string | undefined): string | undefined {
  const key = String(token ?? "").trim().toUpperCase();
  if (!key || /^'.*'$/.test(key) || key.startsWith("@ICON:")) return token;
  const values = new Map<string, string>();
  for (const statement of ir.events?.initialization ?? []) {
    const write = statement.kind === "Write" ? iconWrite(statement.text ?? "", false) : undefined;
    if (write) {
      values.set(write.target.toUpperCase(), `@ICON:${write.icon.toLowerCase().replace(/^icon_/, "")}`);
      continue;
    }
    const move = statement.kind === "Move" ? literalAssignment(statement.text ?? "") : undefined;
    if (!move) continue;
    const name = move.target.toUpperCase();
    const value = decodeAbapLiteral(move.literal);
    if (move.offset === undefined) {
      values.set(name, value);
      continue;
    }
    const offset = move.offset;
    const previous = values.get(name) ?? "";
    if (previous.startsWith("@ICON:")) values.set(name, `${previous} ${value.trimStart()}`);
    else values.set(name, `${previous.slice(0, offset).padEnd(offset, " ")}${value}`);
  }
  return values.get(key) ?? token;
}

// A text-pool entry of "." marks a selection text with dictionary reference:
// the screen shows the field label of the data element the field is typed with. The
// label is read at runtime from the member holding the field's value.
function selectionText(ir: ReportIR, item: SelectionElement): string {
  if (/^(?:D\s+)?\.$/.test(String(item.text ?? "").trim())) {
    const member = ir.statePlan?.selectionState?.[item.name?.toUpperCase() ?? ""]?.member;
    return member ? `io_builder->get_ddic_text( ig_field = ${member} iv_name = '${item.name}' )` : literal(item.name);
  }
  return literal(item.text ?? item.name);
}

function isValueRequestFor(qualifier: string | undefined): boolean {
  return leadingWords(qualifier ?? "").startsWith("AT SELECTION-SCREEN ON VALUE-REQUEST FOR ");
}

function hasSelectionValueRequest(ir: ReportIR, name: string | undefined): boolean {
  const target = String(name ?? "").toUpperCase();
  if (!target) return false;
  const qualifiers = [
    ir.eventQualifiers?.at_selection_screen_value_req,
    ...(ir.eventBlocks ?? [])
      .filter((block) => block.event === "at_selection_screen_value_req")
      .map((block) => block.qualifier),
  ];
  return qualifiers.some((qualifier) => isValueRequestFor(qualifier) && eventQualifier(qualifier).field === target);
}

function selectionBuilder(ir: ReportIR): string[] {
  const lines: string[] = [];
  for (const screen of ir.selections) {
    if (screen.number !== DEFAULT_SELECTION_SCREEN || screen.asWindow || screen.asSubscreen) {
      lines.push(`io_builder->begin_screen( VALUE #( number = '${screen.number}'${screen.asWindow ? " as_window = abap_true" : ""}${screen.asSubscreen ? " as_subscreen = abap_true" : ""} ) ).`);
    }
    // USER-COMMAND is written on one button of a radio group, usually the
    // first, and belongs to the whole group: selecting any button raises it.
    const groupCommands = new Map<string, string>();
    for (const item of screen.elements) {
      const options = selectionOptions(item.raw);
      const group = item.kind === "parameter" ? options.radioGroup?.toUpperCase() : undefined;
      const ucomm = group ? options.userCommand : undefined;
      if (group && ucomm && !groupCommands.has(group)) groupCommands.set(group, ucomm.toUpperCase());
    }
    for (const item of screen.elements) {
      if (item.kind === "layout") {
        if (item.layout === "comment") {
          const fields = [`name = '${item.name}'`, `text = ${literal(staticSelectionText(ir, item.text))}`];
          if (item.position !== undefined) fields.push(`position = ${item.position}`);
          if (item.length !== undefined) fields.push(`visible_length = ${item.length}`);
          lines.push(`io_builder->add_comment( VALUE #( ${fields.join(" ")} ) ).`);
        } else if (item.layout === "skip") lines.push(`io_builder->add_skip( ${item.lines} ).`);
        else if (item.layout === "uline") {
          const placement = [item.position !== undefined ? `position = ${item.position}` : "", item.length !== undefined ? `length = ${item.length}` : ""].filter(Boolean);
          lines.push(`io_builder->add_uline( VALUE #( ${placement.length ? `${placement.join(" ")} ` : ""}) ).`);
        }
        else if (item.layout === "position") lines.push(`io_builder->set_position( ${item.position} ).`);
        else if (item.layout === "begin_line") lines.push("io_builder->begin_line( ).");
        else if (item.layout === "end_line") lines.push("io_builder->end_line( ).");
        else if (item.layout === "begin_block") lines.push(`io_builder->begin_block( VALUE #( name = '${item.name}'${item.title ? ` title = ${literal(staticSelectionText(ir, item.title))}` : ""}${item.withFrame ? " with_frame = abap_true" : ""} ) ).`);
        else if (item.layout === "end_block") lines.push("io_builder->end_block( ).");
        else if (item.layout === "pushbutton") lines.push(`io_builder->add_pushbutton( VALUE #( name = '${item.name}' text = ${literal(staticSelectionText(ir, item.text))}${item.position !== undefined ? ` position = ${item.position}` : ""}${item.length !== undefined ? ` length = ${item.length}` : ""} ucomm = '${item.ucomm}' ) ).`);
        else if (item.layout === "function_key") lines.push(`io_builder->add_function_key( VALUE #( number = ${item.number} text = ${literal(item.text)} ucomm = '${item.ucomm ?? `FC${String(item.number).padStart(2, "0")}`}' ) ).`);
        else if (item.layout === "begin_tabbed_block") lines.push(`io_builder->begin_tabbed_block( VALUE #( name = '${item.name}' lines = ${item.lines} ) ).`);
        else if (item.layout === "tab") lines.push(`io_builder->add_tab( VALUE #( name = '${item.name}' text = ${literal(staticSelectionText(ir, item.text))} subscreen = '${item.subscreen}' ucomm = '${item.ucomm}' ) ).`);
        else if (item.layout === "end_tabbed_block") lines.push("io_builder->end_tabbed_block( ).");
        continue;
      }
      const options = selectionOptions(item.raw);
      // A checkbox or radio button set by DEFAULT 'X' or abap_true.
      const defaultsTrue = ["'X'", "X", "ABAP_TRUE"].includes(String(options.defaultValue).toUpperCase());
      if (item.kind === "parameter") {
        const type = `data_type = ${selectionDataType(item)}`;
        if (options.checkbox) {
          const ucomm = options.userCommand;
          const modif = options.modifId;
          const fields = [`name = '${item.name}'`, `text = ${selectionText(ir, item)}`];
          if (defaultsTrue) fields.push("default = abap_true");
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          if (ucomm) fields.push(`ucomm = '${ucomm.toUpperCase()}'`);
          lines.push(`io_builder->add_checkbox( VALUE #( ${fields.join(" ")} ) ).`);
        } else if (options.radioGroup) {
          const group = options.radioGroup.toUpperCase();
          const ucomm = groupCommands.get(group);
          const modif = options.modifId;
          const defaultValue = defaultsTrue ? " default = abap_true" : "";
          lines.push(`io_builder->add_radiobutton( VALUE #( name = '${item.name}' text = ${selectionText(ir, item)} radio_group = '${group}'${defaultValue}${modif ? ` modif_id = '${modif.toUpperCase()}'` : ""}${ucomm ? ` ucomm = '${ucomm}'` : ""} ) ).`);
        } else if (options.listbox) {
          const fields = [`name = '${item.name}'`, `text = ${selectionText(ir, item)}`, type];
          const visibleLength = options.visibleLength;
          if (visibleLength) fields[2] = type.replace(/\s\)$/, ` visible_length = ${visibleLength} )`);
          const defaultValue = selectionDefault(item);
          if (defaultValue) fields.push(`default = ${defaultValue}`);
          const modif = options.modifId;
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          const ucomm = options.userCommand;
          if (ucomm) fields.push(`ucomm = '${ucomm.toUpperCase()}'`);
          if (options.obligatory) fields.push("obligatory = abap_true");
          lines.push(`io_builder->add_listbox( VALUE #( ${fields.join(" ")} ) ).`);
        } else {
          const fields = [`name = '${item.name}'`, `text = ${selectionText(ir, item)}`, type];
          const defaultValue = selectionDefault(item);
          if (defaultValue) fields.push(`default = ${defaultValue}`);
          const modif = options.modifId;
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          const memoryId = options.memoryId;
          if (memoryId) fields.push(`memory_id = '${memoryId.toUpperCase()}'`);
          const searchHelp = options.matchcode;
          if (searchHelp) fields.push(`search_help = '${searchHelp.toUpperCase()}'`);
          if (searchHelp || hasSelectionValueRequest(ir, item.name)) fields.push("value_help = abap_true");
          if (options.obligatory) fields.push("obligatory = abap_true");
          if (options.lowerCase) fields.push("lower_case = abap_true");
          if (options.noDisplay) fields.push("no_display = abap_true");
          lines.push(`io_builder->add_parameter( VALUE #( ${fields.join(" ")} ) ).`);
        }
      } else if (item.kind === "select-option") {
        const fields = [`name = '${item.name}'`, `text = ${selectionText(ir, item)}`, `data_type = ${selectionDataType(item)}`];
        if (options.noExtension) fields.push("no_extension = abap_true");
        if (options.noIntervals) fields.push("no_intervals = abap_true");
        if (hasSelectionValueRequest(ir, item.name)) fields.push("value_help = abap_true");
        if (options.obligatory) fields.push("obligatory = abap_true");
        if (options.defaultValue) fields.push(`default = VALUE #( sign = 'I' option = '${options.defaultHigh ? "BT" : "EQ"}' low = ${selectionExpression(options.defaultValue)}${options.defaultHigh ? ` high = ${selectionExpression(options.defaultHigh)}` : ""} )`);
        const modif = options.modifId;
        if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
        const memoryId = options.memoryId;
        if (memoryId) fields.push(`memory_id = '${memoryId.toUpperCase()}'`);
        const searchHelp = options.matchcode;
        if (searchHelp) fields.push(`search_help = '${searchHelp.toUpperCase()}'`);
        if (searchHelp && !fields.includes("value_help = abap_true")) fields.push("value_help = abap_true");
        if (options.lowerCase) fields.push("lower_case = abap_true");
        if (options.noDisplay) fields.push("no_display = abap_true");
        lines.push(`io_builder->add_select_option( VALUE #( ${fields.join(" ")} ) ).`);
      }
    }
    if (screen.number !== DEFAULT_SELECTION_SCREEN || screen.asWindow || screen.asSubscreen) lines.push("io_builder->end_screen( ).");
  }
  return lines;
}

// The data objects a routine's declarations see besides the program's: its
// parameters, its own declarations and the work areas of its header lines.
function localDataObjects(ir: ReportIR, parameters: RoutineParameter[], statements: Statement[]): Set<string> {
  const own = new Set(statements);
  const names = [
    ...parameters.map((parameter) => parameter.name),
    ...(ir.declarations ?? []).filter((declaration) => own.has(declaration.statement)).flatMap((declaration) =>
      ["databegin", "constantbegin"].includes(declaration.kind) ? [beginName(declaration)] : declaration.names ?? []),
    ...Object.values(ir.headerLines?.routines ?? {}).flatMap((headers) => Object.values(headers)),
  ];
  return new Set(names.filter(Boolean).map((name) => String(name).toUpperCase()));
}

function methodContext(ir: ReportIR, event: string, {parameters = [], statements = ir.statements ?? []}: { parameters?: RoutineParameter[]; statements?: Statement[] } = {}): LoweringContext {
  const mutable = ["initialization", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_output"].includes(event);
  const values = ir.selections
    .flatMap((screen) => screen.elements.map((item) => ({ ...item, screen: screen.number })))
    .filter((item) => item.name && ["parameter", "select-option"].includes(item.kind))
    .map((item) => ({ name: item.name!, ranges: item.kind === "select-option", screen: item.screen }));
  const dynamicWriteTargets: { name: string; expression: string }[] = [];
  const dynamicTargetNames = new Set<string>();
  const dynamicCommentNames = (ir.selections ?? [])
    .flatMap((screen) => screen.elements ?? [])
    .filter((item) => item.kind === "layout" && item.layout === "comment")
    .map((item) => String(item.text ?? "").trim().toUpperCase())
    .filter((name) => /^[A-Z][A-Z0-9_]*$/.test(name));
  for (const declaration of ir.declarations ?? []) {
    if (declaration.statement?.scope === "local" || declaration.statement?.localClassName || !["data", "static", "tables", "ranges"].includes(declaration.kind)) continue;
    for (const name of declaration.names ?? []) {
      const upper = name.toUpperCase();
      if (dynamicTargetNames.has(upper)) continue;
      dynamicTargetNames.add(upper);
      dynamicWriteTargets.push({ name: upper, expression: ir.statePlan?.renames?.[upper] ?? name.toLowerCase() });
    }
  }
  for (const selection of values) {
    const upper = selection.name.toUpperCase();
    if (dynamicTargetNames.has(upper)) continue;
    dynamicTargetNames.add(upper);
    dynamicWriteTargets.push({ name: upper, expression: ir.statePlan?.selectionState?.[upper]?.member ?? selection.name.toLowerCase() });
  }
  dynamicWriteTargets.sort((left, right) => left.name.localeCompare(right.name));
  // The function codes AT USER-COMMAND compares, as in WHEN 'SAVE' or = 'BACK'.
  const activeCommands = (ir.events?.at_user_command ?? []).flatMap((statement) => {
    const tokens = lexedAst(statement.text)?.tokens() ?? [];
    return tokens.filter((entry, index) => /^'.+'$/.test(entry.token.getStr()) && ["WHEN", "="].includes(tokens[index - 1]?.token.getUpperStr()))
      .map((entry) => entry.token.getStr().slice(1, -1).toUpperCase());
  });
  const activePFKeys = (ir.eventBlocks ?? [])
    .filter((block) => block.event === "at_pf")
    .map((block) => eventQualifier(block.qualifier).pfKey)
    .filter((key): key is number => key !== undefined);
  const valueReference = (item: { name: string; ranges: boolean }) => ir.statePlan?.selectionState?.[item.name]?.member ?? `${mutable ? "ct_values" : "it_values"}[ name = '${item.name}' ]-${item.ranges ? "ranges" : "value"}`;
  const valueReplacements = values.flatMap((item): Replacement[] => {
    const reference = valueReference(item);
    const fields: Replacement[] = item.ranges
      ? [[`${item.name}-low`, `${reference}[ 1 ]-low`], [`${item.name}-high`, `${reference}[ 1 ]-high`]]
      : [];
    return [...fields, [item.name, reference]];
  });
  return {
    event,
    selections: values,
    // A FORM sees its own header-line tables too; routineBody adds them.
    headerLines: headerLinesIn(ir),
    // Each TABLES work area with its database table.
    tablesWorkAreas: new Map((ir.declarations ?? [])
      .filter((item) => item.kind === "tables" && item.resolved)
      .flatMap((item) => (item.names ?? []).map((name): [string, string | undefined] => [name.toUpperCase(), item.type]))),
    dataObjects: new Set((ir.declarations ?? [])
      .filter((item) => ["data", "static", "tables", "ranges", "databegin"].includes(item.kind))
      .flatMap((item) => item.kind === "databegin" ? [declaredName(item.raw)] : item.names ?? [])
      .filter((name): name is string => Boolean(name))
      .map((name) => name.toUpperCase())),
    // A local class's methods are class code already.
    likeMember: event === "local_class" ? undefined : scopedMember(localDataObjects(ir, parameters, statements), globalLikeMember(ir)),
    tabbedBlocks: selectionTabbedBlocks(ir),
    messageId: ir.header?.messageId,
    constantNames: ir.constantNames,
    // Shared by every statement of the method, so temporaries get unique names.
    temporaries: { count: 0 },
    mutableValues: mutable,
    messageField: ["at_selection_screen_on_field", "at_selection_screen_on_end_of"].includes(event) ? "iv_name" : undefined,
    // Only AT SELECTION-SCREEN itself, ON EXIT-COMMAND and AT USER-COMMAND get
    // the function code as a parameter; the other selection events read the
    // PAI's function code from the session.
    ucomm: ["at_selection_screen", "at_selection_screen_on_exit", "at_user_command"].includes(event)
      ? "iv_ucomm"
      : event.startsWith("at_selection_screen") ? "io_session->get_context( )-selection-ucomm" : undefined,
    replacements: [
      ...Object.entries(ir.statePlan?.renames ?? {}),
      ...Object.entries(ir.localClassRenames ?? {}).map(([name, value]): Replacement => [name, String(value).toLowerCase()]),
      ...Object.entries(continuationRenames(ir)),
      ...valueReplacements,
      // A hidden global is restored from the selected line, see
      // hiddenRestore; any other hidden name reads the line directly.
      ...(event === "at_line_selection" || event === "at_user_command" || event === "at_pf"
        ? (ir.hiddenNames ?? []).filter((name) => !hiddenGlobal(ir, name))
          .map((name): Replacement => [name, `is_line-fields[ name = '${name}' ]-value`])
        : []),
    ],
    hiddenNames: ir.hiddenNames ?? [],
    continuations: (ir.continuations ?? []).map((continuation) => ({
      ...continuation,
      capturedVariables: (continuation.liveVariables ?? []).map((name) =>
        ir.statePlan?.selectionState?.[name]?.member
        ?? ir.statePlan?.renames?.[name]
        ?? continuationRenames(ir)[name]
        ?? name.toLowerCase()),
    })),
    routines: ir.routines ?? [],
    subrc: event === "resume" ? "is_resume-subrc" : undefined,
    activeCommands,
    activePFKeys,
    guiStatusMetadata: ir.guiStatusMetadata ?? {},
    titlebarMetadata: ir.screenMetadata?.titlebars ?? ir.dynproMetadata?.titlebars ?? {},
    selectionState: ir.statePlan?.selectionState ?? {},
    dynamicWriteTargets,
    dynamicCommentNames,
    localClassStaticMethods: Object.fromEntries((ir.localClasses ?? []).map((localClass) => [
      String(localClass.name ?? "").toUpperCase(),
      new Set((localClass.definition ?? [])
        .map((statement) => methodDefinition(statement.text))
        .filter((definition) => definition?.isStatic && !definition.isEventHandler)
        .map((definition) => definition!.name.toUpperCase())),
    ])),
    localClassStaticEventHandlers: Object.fromEntries((ir.localClasses ?? []).map((localClass) => [
      String(localClass.name ?? "").toUpperCase(),
      staticEventHandlerNames(localClass),
    ])),
    localClassStaticParameters: Object.fromEntries((ir.localClasses ?? []).map((localClass) => [
      String(localClass.name ?? "").toUpperCase(),
      Object.fromEntries((localClass.definition ?? [])
        .map((statement) => methodDefinition(statement.text))
        .filter((definition) => definition?.isStatic && !definition.isEventHandler && definition.importing.length)
        .map((definition) => [definition!.name.toUpperCase(), definition!.importing[0].toUpperCase()])),
    ])),
    localClassRenames: Object.fromEntries(Object.entries(ir.localClassRenames ?? {})
      .map(([name, value]) => [String(name).toUpperCase(), String(value).toLowerCase()])),
    controlObjectTypes: controlObjectTypes(ir.declarations ?? [], ir.localClasses ?? [], {
      parameters: [
        ...(ir.routines ?? []).flatMap((routine) => routine.parameters ?? []),
        ...parameters,
      ],
      statements,
    }),
    safeFieldSymbols: ir.safeFieldSymbols ?? [],
    fieldSymbolReferences: ir.fieldSymbolReferences ?? {},
    dynamicAlv: ir.dynamicAlv,
    rangeDeclarations: Object.fromEntries((ir.declarations ?? [])
      .filter((declaration) => declaration.kind === "ranges")
      .flatMap((declaration) => (declaration.names ?? []).map((name): [string, string] => [name.toUpperCase(), rangeType(ir, declaration.target, (base) => {
        // A RANGES in a FORM may be FOR the FORM's own variables and parameters.
        const local = declaration.statement?.scope === "local"
          && ((ir.declarations ?? []).some((item) => item.statement?.scope === "local" && item.names?.includes(base))
            || (ir.routines ?? []).some((routine) => (routine.parameters ?? []).some((parameter) => parameter.name.toUpperCase() === base)));
        return local ? base.toLowerCase() : reportMember(ir, base);
      })]))),
    sessionVariable: "io_session",
    ownerPrefix: "",
    localClassOwner: "me",
  };
}

// The report's FIELD-SYMBOLS a generated method uses, declared in it, as a
// class cannot have field symbols. One bound in another method gets that
// binding back from its data reference first, see fieldSymbolReferences.
function globalFieldSymbolDeclarations(ir: ReportIR, statements: Statement[] | undefined, context: LoweringContext): string[] {
  const source = statements ?? [];
  const uses = (name: string) => source.some((statement) => fieldSymbolsIn(statement.text).includes(name.toUpperCase()));
  const declarations = (ir.declarations ?? [])
    .filter((declaration) => declaration.kind === "field-symbol"
      && declaration.statement?.scope !== "local"
      && (!ir.dynamicAlv || !declaration.names?.some((name) => String(name).toUpperCase() === ir.dynamicAlv!.tableSymbol))
      && (declaration.names ?? []).some((name) => ir.safeFieldSymbols?.includes(name.toUpperCase()))
      && (declaration.names ?? []).some(uses))
    .map((declaration) => {
      // Typed like a report global, which may have been renamed or have had
      // a header line.
      return replaceIdentifiers(withoutHeaderLines(declaration.raw.replace(/,\s*$/, "."), ir.headerLines?.global ?? {}), context?.replacements ?? []);
    });
  const kept = Object.keys(ir.fieldSymbolReferences ?? {}).filter(uses);
  // Not where the method binds it before anything else uses it.
  const restored = kept.filter((name) => {
    const first = source.find((statement) => fieldSymbolsIn(statement.text).includes(name.toUpperCase()));
    return !bindsStatically(first!.text, name);
  });
  // A call that may change the binding takes it over again.
  const calls = source.some((statement) => kept.some((name) => rebindingCall(statement, ir.fieldSymbolReferences![name])));
  return [
    ...declarations,
    ...(restored.length || calls ? ["DATA lv_ggconv_subrc TYPE sy-subrc."] : []),
    ...(restored.length ? [restoreFieldSymbols(restored, context)] : []),
  ];
}

function selectionStateTransport(ir: ReportIR, event: string): { hydrate: string[]; flush: string[] } {
  const state = ir.statePlan?.selectionState ?? {};
  const values = ["initialization", "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_on_exit", "at_selection_screen_value_req", "at_selection_screen_help_req", "start_of_selection", "end_of_selection"].includes(event);
  if (!values) return { hydrate: [], flush: [] };
  const source = ["initialization", "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio"].includes(event) ? "ct_values" : "it_values";
  const hydrate: string[] = [];
  const flush: string[] = [];
  for (const [name, item] of Object.entries(state)) {
    const field = `${source}[ name = '${name}' ]-${item.ranges ? "ranges" : "value"}`;
    // A select-option member is a range table of its own type; the screen
    // transports LOW and HIGH as strings, CORRESPONDING converts each row.
    hydrate.push(item.ranges ? `${item.member} = CORRESPONDING #( ${field} ).` : `${item.member} = ${field}.`);
    // The screen fields of a select-option are its header line, which after
    // input holds the first row.
    const header = item.ranges ? ir.headerLines?.global?.[name] : undefined;
    if (header) hydrate.push(`${header} = VALUE #( ${item.member}[ 1 ] OPTIONAL ).`);
    if (source !== "ct_values") continue;
    if (item.ranges) {
      // As for parameters below, an untouched empty LOW of type i must not
      // come back as "0", so the screen rows are only replaced on a change.
      const screen = `lt_ggconv_${name.toLowerCase()}`;
      // Declared, not inline: a method can write the values back twice, and
      // the declaration goes to its top once.
      flush.push([
        `DATA ${screen} LIKE ${item.member}.`,
        `${screen} = ${item.member}.`,
        `${screen} = CORRESPONDING #( ${field} ).`,
        `IF ${screen} <> ${item.member}.`,
        `${field} = CORRESPONDING #( ${item.member} ).`,
        "ENDIF.",
      ].join("\n"));
      continue;
    }
    // The member has the parameter's own type. Assigning it back would turn an
    // untouched 1 into "1 ", -1 into "1-" and "" into "0 ", so the screen value
    // is only replaced when the program changed it, in template format.
    flush.push([
      `IF ${field} <> ${item.member}.`,
      `${field} = |{ ${item.member} }|.`,
      "ENDIF.",
    ].join("\n"));
  }
  // build_screen only knows the declared tab text. The label the program puts
  // in the tab field, in a FORM or in any event, reaches the screen through
  // the tab's value.
  if (source === "ct_values") {
    for (const name of selectionTabFields(ir)) {
      flush.push(`ct_values[ name = '${name}' ]-value = ${renameIdentifiers(name.toLowerCase(), allRenames(ir))}.`);
    }
  }
  return { hydrate, flush };
}

function selectionTabFields(ir: ReportIR): string[] {
  return (ir.selections ?? []).flatMap((screen) => screen.elements ?? [])
    .filter((item) => item.layout === "tab")
    .map((item) => item.name!);
}

function nestedSelectionCaptures(ir: ReportIR): string[] {
  const fields = ir.selections
    .filter((screen) => screen.number !== DEFAULT_SELECTION_SCREEN)
    .flatMap((screen) => screen.elements
      .filter((item) => item.kind === "parameter" || item.kind === "select-option")
      .map((item) => ({ screen: screen.number, ...item })));
  if (!fields.length) return [];
  const lines: string[] = [];
  let current: string | undefined;
  for (const field of fields) {
    if (field.screen !== current) {
      if (current) lines.push("ENDIF.");
      current = field.screen;
      lines.push(`IF iv_screen = '${current}'.`);
    }
    const ranges = ir.statePlan?.selectionState?.[field.name!]?.ranges ?? field.ranges;
    lines.push(ranges
      ? `mv_${field.name!.toLowerCase()} = CORRESPONDING #( ct_values[ name = '${field.name}' ]-ranges ).`
      : `mv_${field.name!.toLowerCase()} = ct_values[ name = '${field.name}' ]-value.`);
  }
  if (current) lines.push("ENDIF.");
  return lines;
}

function removePromotedDeclarations(ir: ReportIR, lines: string[]): string[] {
  const promoted = new Set([...continuationLocalNames(ir)].map((name) => continuationRenames(ir)[name].toLowerCase()));
  if (!promoted.size) return lines;
  return lines.flatMap((line) => String(line).split('\n'))
    .filter((line) => ![...promoted].some((name) => new RegExp(`^\\s*DATA\\s+${name}\\b`, 'i').test(line)));
}

// The blocks open at statements[index], outermost first, with the branch of
// each that the statement is in.
function enclosingBlocks(statements: Statement[], index: number): (ControlFrame & { statement: Statement })[] {
  const stack: (ControlFrame & { statement: Statement })[] = [];
  for (let cursor = 0; cursor < index; cursor++) {
    const statement = statements[cursor];
    if (BLOCK_OPENERS.has(statement.kind)) {
      stack.push({ kind: statement.kind, statement, branch: "body" });
    } else if (BLOCK_BRANCHES.has(statement.kind) && stack.length) {
      stack.at(-1)!.branch = statement.kind;
    } else if (BLOCK_ENDS.has(statement.kind)) {
      const open = stack.findLastIndex((item) => closesBlock(item.kind, statement.kind));
      if (open >= 0) stack.splice(open);
    }
  }
  return stack;
}

// What runs after a suspension returns, as statements of the owning block.
// Suspending unwinds the ABAP call stack, so the continuation is the rest of
// the block the suspension is in, then the rest of each enclosing block,
// outward. Sibling ELSE/WHEN/CATCH branches of an enclosing block are not on
// that path and are skipped with the block's closer, except for a TRY whose
// protected body is resumed: that TRY is opened again, so its CATCH and
// CLEANUP branches still handle the rest of the body. Blocks that start after
// the suspension are ordinary ABAP and are kept as written.
function resumeTail(statements: Statement[], index: number): Statement[] {
  const frames = enclosingBlocks(statements, index)
    .map((frame) => ({ ...frame, reopened: frame.kind === "Try" && frame.branch === "body" }));
  const output = frames.filter((frame) => frame.reopened).map((frame) => frame.statement);
  let nested = 0;
  let skipping = false;
  let skippedDepth = 0;
  for (let cursor = index + 1; cursor < statements.length; cursor++) {
    const statement = statements[cursor];
    const kind = statement.kind;
    if (skipping) {
      if (BLOCK_OPENERS.has(kind)) skippedDepth++;
      else if (BLOCK_ENDS.has(kind)) {
        if (skippedDepth > 0) skippedDepth--;
        else {
          frames.pop();
          skipping = false;
        }
      }
      continue;
    }
    if (nested > 0) {
      if (BLOCK_OPENERS.has(kind)) nested++;
      else if (BLOCK_ENDS.has(kind)) nested--;
      output.push(statement);
      continue;
    }
    if (BLOCK_OPENERS.has(kind)) {
      nested++;
      output.push(statement);
      continue;
    }
    const frame = frames.at(-1);
    if (BLOCK_ENDS.has(kind)) {
      if (!frame) continue;
      frames.pop();
      if (frame.reopened) output.push(statement);
      continue;
    }
    if (BLOCK_BRANCHES.has(kind) && frame) {
      if (frame.reopened) output.push(statement);
      else {
        skipping = true;
        skippedDepth = 0;
      }
      continue;
    }
    output.push(statement);
  }
  return output;
}

// The statements after which the program does not go on: STOP, SUBMIT
// without AND RETURN, LEAVE PROGRAM, LEAVE TO TRANSACTION and LEAVE
// LIST-PROCESSING.
function isTerminal(statement: Statement): boolean {
  const words = leadingWords(statement.text);
  return statement.kind === "Stop" || statement.kind === "Submit" && !lexedAst(statement.text)?.containsPhrase("AND RETURN")
    || statement.kind === "Leave" && ["LEAVE PROGRAM", "LEAVE TO TRANSACTION", "LEAVE LIST-PROCESSING"].some((phrase) => words === phrase || words.startsWith(`${phrase} `));
}

// Terminal statements and suspensions do not fall through: the session
// unwinds the method at them. The rest of the block they are in is therefore
// unreachable and is left out, and a suspension's rest runs from its
// continuation instead. The block's closer, its sibling branches and
// everything after it are still reachable and are kept.
function truncateTerminalPaths(statements: Statement[]): Statement[] {
  const output: Statement[] = [];
  let depth = 0;
  let skipDepth: number | undefined;
  for (const statement of statements) {
    const kind = statement.kind;
    if (skipDepth !== undefined) {
      if (BLOCK_OPENERS.has(kind)) depth++;
      else if (BLOCK_ENDS.has(kind)) {
        depth--;
        if (depth < skipDepth) {
          skipDepth = undefined;
          output.push(statement);
        }
      } else if (BLOCK_BRANCHES.has(kind) && depth === skipDepth) {
        skipDepth = undefined;
        output.push(statement);
      }
      continue;
    }
    output.push(statement);
    if (BLOCK_OPENERS.has(kind)) depth++;
    else if (BLOCK_ENDS.has(kind)) depth = Math.max(0, depth - 1);
    else if (isTerminal(statement) || (isSuspendingStatement(statement) && !isPopupStatement(statement))) {
      if (depth === 0) return output;
      skipDepth = depth;
    }
  }
  return output;
}

function hiddenGlobal(ir: ReportIR, name: string): boolean {
  const base = name.split("-")[0];
  return (ir.statePlan?.globals ?? []).some((global) => global.toUpperCase() === base);
}

// Choosing a line puts the values HIDE stored for it back into their global
// fields before the event runs.
function hiddenRestore(ir: ReportIR, event: string): string[] {
  if (!["at_line_selection", "at_user_command", "at_pf"].includes(event)) return [];
  return (ir.hiddenNames ?? []).filter((name) => hiddenGlobal(ir, name)).flatMap((name) => {
    const [base, ...path] = name.split("-");
    const target = [ir.statePlan?.renames?.[base] ?? base.toLowerCase(), ...path.map((part) => part.toLowerCase())].join("-");
    return [
      `IF line_exists( is_line-fields[ name = '${name}' ] ).`,
      `${target} = is_line-fields[ name = '${name}' ]-value.`,
      "ENDIF.",
    ];
  });
}

// A value request that assigns its own parameter offers that value. Values an
// F4 function module offers reach the host through the compatibility layer.
function valueRequestResult(ir: ReportIR, qualifier: string | undefined): string[] {
  const field = isValueRequestFor(qualifier) ? eventQualifier(qualifier).field : undefined;
  const state = field && ir.statePlan?.selectionState?.[field];
  if (!state || state.ranges) return [];
  return [
    `IF ${state.member} <> it_values[ name = '${field}' ]-value.`,
    `rt_values = VALUE #( ( sign = zif_gg_selection_screen_types=>sign_include option = zif_gg_selection_screen_types=>option_eq low = |{ ${state.member} }| ) ).`,
    "ENDIF.",
  ];
}

function eventBody(ir: ReportIR, event: string, sourceStatements: Statement[] = ir.events[event] ?? [], qualifier: string | undefined = ir.eventQualifiers?.[event]): { body: string[]; lowered: { text: string }[] } {
  const statements = truncateTerminalPaths(sourceStatements);
  const context = methodContext(ir, event, {statements: sourceStatements});
  context.screenStates = event === "at_selection_screen_output"
    ? { kind: "selection", table: "ct_states" }
    : storedScreenStates(screenStatePlan(ir).defaultKind);
  if (event === "at_selection_screen_help_req") {
    const write = statements.find((statement) => statement.kind === "Write");
    // WRITE 'text': the help text.
    const text = write ? lexedAst(write.text.trim())?.tokens()[1]?.token : undefined;
    if (text instanceof Tokens.StringToken && text.getStr().startsWith("'")) return { body: [`rv_text = ${text.getStr()}.`], lowered: [] };
  }
  const lowered = lowerStatements(statements, context);
  // A value or help request without a block of its own needs no values.
  const requestEvent = ["at_selection_screen_value_req", "at_selection_screen_help_req"].includes(event);
  const transport = requestEvent && !statements.length ? { hydrate: [], flush: [] } : selectionStateTransport(ir, event);
  const fieldSymbols = globalFieldSymbolDeclarations(ir, statements, context);
  let body = [
    ...fieldSymbols,
    ...(statements.length ? hiddenRestore(ir, event) : []),
    ...transport.hydrate,
    ...removePromotedDeclarations(ir, lowered.map((item) => item.text)),
    ...transport.flush,
    ...(event === "at_selection_screen_value_req" ? valueRequestResult(ir, qualifier) : []),
  ];
  const hasWriter = body.some((line) => line.includes("lo_writer->"));
  if (hasWriter) body = addWriterDeclaration(body);
  if (event === "start_of_selection" && context.activePFKeys?.length && !statements.some((statement) => statement.kind === "SetPFStatus")) {
    body.unshift(`io_session->get_list( )->set_status( VALUE #( status = 'LIST' active_pf_keys = VALUE #( ${context.activePFKeys.map((key) => `( ${key} )`).join(" ")} ) ) ).`);
  }
  if (event === "start_of_selection" && body.length) body.unshift(`io_session->get_list( )->set_title( ${textLiteral(ir.reportTitle ?? ir.targetClassName)} ).`);
  if (hasWriter) body = addWriterDeclaration(body);
  return { body, lowered };
}

function qualifierGuard(ir: ReportIR, event: string, body: string[], qualifierOverride: string | undefined): string[] {
  const qualifier = qualifierOverride ?? ir.eventQualifiers?.[event];
  if (!qualifier || !body.length) return body;
  let condition: string | undefined;
  const { field, block, group, pfKey } = eventQualifier(qualifier);
  if (field && (event.includes("field") || event.includes("value_req") || event.includes("help_req"))) condition = `iv_name = '${field}'`;
  if (block) condition = `iv_block = '${block}'`;
  if (group) condition = `iv_group = '${group}'`;
  if (event === "at_pf" && pfKey !== undefined) condition = `iv_key = ${pfKey}`;
  if (!condition) return body;
  const definitions = body.filter((line) => /^(?:DATA\(|FIELD-SYMBOLS\b|TYPES\b|CONSTANTS\b)/i.test(line.trim()));
  const executable = body.filter((line) => !definitions.includes(line));
  let guarded: string[];
  if (executable.length >= 2 && /^IF\s+.+\.$/i.test(executable[0]) && executable.at(-1)!.toUpperCase() === "ENDIF.") {
    const inner = executable[0].replace(/^IF\s+/i, "").replace(/\.$/, "");
    guarded = [`IF ${condition} AND ${inner}.`, ...executable.slice(1, -1), "ENDIF."];
  } else {
    guarded = [`IF ${condition}.`, ...executable, "ENDIF."];
  }
  return [...definitions, ...guarded];
}

// Names of the selection screen's tabbed blocks. Their ACTIVETAB fields all
// live in mv_active_tab.
function selectionTabbedBlocks(ir: ReportIR): string[] {
  return (ir.selections ?? []).flatMap((screen) => screen.elements ?? [])
    .filter((item) => item.layout === "begin_tabbed_block")
    .map((item) => item.name!);
}

// Choosing a tab sets <block>-ACTIVETAB to the tab's function code before AT
// SELECTION-SCREEN runs, so later events, Execute included, see the tab.
function activeTabCapture(ir: ReportIR): string[] {
  const ucomms = (ir.selections ?? []).flatMap((screen) => screen.elements ?? [])
    .filter((item) => item.layout === "tab")
    .map((item) => `iv_ucomm = '${item.ucomm}'`);
  return ucomms.length ? [`IF ${ucomms.join(" OR ")}.`, "mv_active_tab = iv_ucomm.", "ENDIF."] : [];
}

function reportMethods(ir: ReportIR): GeneratedMethod[] {
  const methods: GeneratedMethod[] = [];
  const bodiesFor = (event: string) => {
    const blocks = ir.eventBlocks?.filter((block) => block.event === event) ?? [];
    if (!blocks.length) return eventBody(ir, event).body;
    return blocks.flatMap((block) => qualifierGuard(ir, event, eventBody(ir, event, block.statements, block.qualifier).body, block.qualifier));
  };
  for (const event of REPORT_METHODS) {
    if (event === "get_logical_database") {
      methods.push(method(`zif_gg_report_v1~${event}`, []));
    } else if (event === "get_list_processing") {
      methods.push(method(`zif_gg_report_v1~${event}`, ir.interfaces.includes("zif_gg_list_processing_v1") ? ["ro_list_processing = me."] : []));
    } else if (event === "build_screen") {
      methods.push(method(`zif_gg_report_v1~${event}`, selectionBuilder(ir)));
    } else if (event === "at_selection_screen_value_req") {
      methods.push(method(`zif_gg_report_v1~${event}`, bodiesFor(event)));
    } else if (event === "at_selection_screen_help_req") {
      methods.push(method(`zif_gg_report_v1~${event}`, bodiesFor(event)));
    } else {
      const body = [...bodiesFor(event)];
      if (event === "load_of_program") body.unshift(...globalStartValues(ir).map((start) => startValueAssignment(start, methodContext(ir, event))));
      if (event === "load_of_program" && ir.reportTitle) {
        body.unshift(`io_session->get_list( )->set_title( ${textLiteral(ir.reportTitle ?? ir.targetClassName)} ).`);
      }
      if (event === "at_selection_screen") body.unshift(...activeTabCapture(ir));
      if (event === "at_selection_screen" && ir.continuations?.length) body.push(...nestedSelectionCaptures(ir));
      if (event === "at_selection_screen_output") body.unshift(...selectionStatesSetter(ir));
      methods.push(method(`zif_gg_report_v1~${event}`, body));
    }
  }
  return methods;
}

function listMethods(ir: ReportIR): GeneratedMethod[] {
  const methods: GeneratedMethod[] = [];
  const bodiesFor = (event: string) => {
    const blocks = ir.eventBlocks?.filter((block) => block.event === event) ?? [];
    if (!blocks.length) return eventBody(ir, event).body;
    return blocks.flatMap((block) => qualifierGuard(ir, event, eventBody(ir, event, block.statements, block.qualifier).body, block.qualifier));
  };
  for (const name of LIST_METHODS) {
    if (name === "get_settings") {
      const h = ir.header;
      const fields: string[] = [];
      if (h.lineSize !== undefined) fields.push(`line_size = ${h.lineSize}`);
      if (h.lineCount !== undefined) fields.push(`line_count = ${h.lineCount}`);
      if (h.footerLines !== undefined) fields.push(`footer_lines = ${h.footerLines}`);
      if (h.noStandardPageHeading) fields.push("no_standard_page_head = abap_true");
      methods.push(method(`zif_gg_list_processing_v1~${name}`, fields.length ? [`rs_settings = VALUE #( ${fields.join(" ")} ).`] : []));
    } else {
      const event = name;
      methods.push(method(`zif_gg_list_processing_v1~${name}`, bodiesFor(event)));
    }
  }
  return methods;
}

function resumeMethod(ir: ReportIR): GeneratedMethod {
  const cases: string[] = [];
  for (const continuation of ir.continuations ?? []) {
    const statement = ir.statements.find((item) => item.filename === continuation.filename
      && item.span.start.line === continuation.span.start.line
      && item.span.start.column === continuation.span.start.column);
    if (!statement) continue;
    const id = continuation.id;
    const owner = ir.eventBlocks?.find((block) => block.statements?.includes(statement))
      ?? ir.routines?.find((item) => item.statements?.includes(statement))
      ?? ir.modules?.find((item) => item.statements?.includes(statement));
    const ownerIsModule = ir.modules?.includes(owner as never) === true;
    const ownerStatements = owner?.statements ?? [];
    const tail = truncateTerminalPaths(resumeTail(ownerStatements, ownerStatements.indexOf(statement)));
    if (isPopupStatement(statement)) tail.unshift(statement);
    let lowered: string[];
    {
      const context = methodContext(ir, ownerIsModule ? "dynpro" : "resume");
      context.screenStates = ownerIsModule ? storedScreenStates("dynpro")
        : ir.routines?.includes(owner as Routine) ? routineScreenStates(ir, owner as Routine)
        : storedScreenStates(screenStatePlan(ir).defaultKind);
      if (ir.routines?.includes(owner as Routine)) context.headerLines = headerLinesIn(ir, (owner as Routine).name);
      lowered = removePromotedDeclarations(ir, lowerStatements(tail, context).map((item) => item.text));
      lowered = [...(ir.routines?.includes(owner as Routine) ? ir.headerLines?.parameters?.[(owner as Routine).name] ?? [] : []), ...globalFieldSymbolDeclarations(ir, tail, context), ...lowered];
    }
    if (!lowered.some((line) => String(line).trim() && !/^\s*\*/.test(line))) lowered.push("RETURN.");
    cases.push(`WHEN '${id}'.`, ...lowered);
  }
    const body = ["CASE is_resume-continuation-id.", ...(cases.length ? cases : ["WHEN OTHERS.", "RETURN."]), ...(cases.length ? ["WHEN OTHERS.", "RETURN."] : []), "ENDCASE."];
    if (body.some(line => /\bis_context\b/i.test(line))) body.unshift("DATA(is_context) = is_resume-module_context.");
  // One writer serves every continuation: each WHEN declaring its own inline
  // DATA(lo_writer) would declare the same name twice in one method.
  return method("zif_gg_resumable_v1~resume", body.some((line) => line.includes("lo_writer->")) ? addWriterDeclaration(body) : body, "Continuation states are explicit so unsupported suspension semantics remain visible.");
}

const STATE_TYPES = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "ABAP_BOOL", "SY-UCOMM", "SY-DYNNR"]);

// The type a declaration names right after TYPE, as in TYPE c LENGTH 10, upper
// case; undefined for TYPE REF TO, TYPE TABLE OF and LIKE.
function elementaryType(raw: string | undefined): string | undefined {
  const ast = statementAst(String(raw ?? "").trim());
  const typing = ast?.find(Expressions.Type);
  const name = typing?.getChildren()[1];
  return ast && name?.get() instanceof Expressions.TypeName ? ast.source(name).toUpperCase() : undefined;
}

function dynproStateComponents(ir: ReportIR): { name: string; member: string }[] {
  const components: { name: string; member: string }[] = [];
  const seen = new Set<string>();
  const add = (name: string) => {
    const upper = name.toUpperCase();
    if (seen.has(upper)) return;
    seen.add(upper);
    components.push({ name: upper, member: ir.statePlan?.renames?.[upper] ?? name.toLowerCase() });
  };
  for (const declaration of ir.declarations ?? []) {
    if (!isReportGlobal(ir, declaration)
        || !["data", "static"].includes(declaration.kind)
        || declaration.complex
        // A component of a BEGIN OF structure is no data object of its own.
        || declaration.component) continue;
    // A screen field holds an elementary value.
    const name = declaredName(declaration.raw);
    if (name && STATE_TYPES.has(elementaryType(declaration.raw) ?? "")) add(name);
  }
  for (const statement of ir.statements ?? []) {
    if (statement.kind !== "Controls") continue;
    const controls = controlsDeclaration(statement.text);
    if (controls?.type !== "TABSTRIP") continue;
    const name = `${controls.name.toUpperCase()}-ACTIVETAB`;
    if (seen.has(name)) continue;
    seen.add(name);
    components.push({
      name,
      member: `${controls.name.toLowerCase()}-activetab`,
    });
  }
  return components;
}

function dynproStateHydrate(ir: ReportIR, valuesName = "ct_values", keep: (name: string) => boolean = () => true): string[] {
  return dynproStateComponents(ir).filter(({ name }) => keep(name)).flatMap(({ name, member }) => [
    `IF line_exists( ${valuesName}[ name = '${name}' ] ).`,
    `${member} = CONV #( ${valuesName}[ name = '${name}' ]-value ).`,
    "ENDIF.",
  ]);
}

// PAI takes over only the screen fields a user can change. Other
// fields keep the program's values, which an event handler of a control may
// have set before PAI. The active tab of a tabstrip comes from the screen too.
function screenInputField(metadata: Metadata | undefined): (name: string) => boolean {
  const changeable = new Set((metadata?.screens ?? [])
    .flatMap((screen: Metadata) => screen.elements ?? [])
    .filter((element: Metadata) => !["output", "text", "frame", "pushbutton", "subscreen"].includes(element.kind))
    .map((element: Metadata) => String(element.name ?? "").toUpperCase()));
  return (name) => changeable.has(name) || name.endsWith("-ACTIVETAB");
}

// A string field goes into the screen value as it is.
function stringDeclared(ir: ReportIR, name: string): boolean {
  return (ir.declarations ?? []).some((item) => (item.names ?? []).some((declared) => declared.toUpperCase() === name)
    && elementaryType(item.raw) === "STRING");
}

function dynproStateFlush(ir: ReportIR, valuesName = "ct_values"): string[] {
  return dynproStateComponents(ir).flatMap(({ name, member }) => {
    const value = stringDeclared(ir, name) ? member : `CONV string( ${member} )`;
    return [
      `IF line_exists( ${valuesName}[ name = '${name}' ] ).`,
      `${valuesName}[ name = '${name}' ]-value = ${value}.`,
      "ELSE.",
      `INSERT VALUE #( name = '${name}' value = ${value} ) INTO TABLE ${valuesName}.`,
      "ENDIF.",
    ];
  });
}

function unsupportedDynamicTableAction(ir: ReportIR, routine: Routine): string[] | undefined {
  if (ir.dynamicAlv) return undefined;
  const tableSymbols = new Set((ir.declarations ?? [])
    .filter((declaration) => declaration.kind === "field-symbol"
      && declaration.statement?.scope !== "local"
      && Boolean(lexedAst(declaration.raw ?? "")?.containsPhrase("TYPE STANDARD TABLE")))
    .flatMap((declaration) => (declaration.names ?? []).map((name) => String(name).toUpperCase())));
  if (!tableSymbols.size) return undefined;
  const statements = routine.statements ?? [];
  if (statements.some((statement) => mentions(statement.text, "SET_TABLE_FOR_FIRST_DISPLAY"))) return undefined;
  const usesDynamicTable = statements.some((statement) => fieldSymbolsIn(statement.text ?? "").some((name) => tableSymbols.has(name)));
  // GV_STATUS = or GV_DETAIL =, wherever it stands.
  const writesFeedback = statements.some((statement) => {
    const tokens = lexedAst(statement.text ?? "")?.tokens() ?? [];
    return tokens.some((entry, index) => ["GV_STATUS", "GV_DETAIL"].includes(entry.token.getUpperStr()) && tokens[index + 1]?.token.getStr() === "=");
  });
  if (!usesDynamicTable || !writesFeedback) return undefined;
  const members = globalMemberNames(ir);
  const body: string[] = [];
  if (members.GV_STATUS) {
    body.push(`${members.GV_STATUS} = ${literal("Dynamic ALV action not applied: generic field-symbol table operations are unsupported.")}.`);
  }
  if (members.GV_DETAIL) {
    body.push(`${members.GV_DETAIL} = ${literal("No table rows or cell styles were changed.")}.`);
  }
  return body.length ? [...body, "RETURN."] : undefined;
}

function routineBody(ir: ReportIR, routine: Routine): string[] {
  const dynamicTableAction = unsupportedDynamicTableAction(ir, routine);
  if (dynamicTableAction) return dynamicTableAction;
  const active = truncateTerminalPaths(routine.statements ?? []);
  const context = methodContext(ir, "start_of_selection", {
    parameters: routine.parameters,
    statements: routine.statements ?? [],
  });
  context.screenStates = routineScreenStates(ir, routine);
  context.contextMenu = /^ON_CTMENU(?:_|$)/i.test(String(routine.name ?? ""));
  context.headerLines = headerLinesIn(ir, routine.name);
  let lowered = removePromotedDeclarations(ir, lowerStatements(active, context).map((item) => item.text));
  // The work areas for the header lines of TABLES parameters.
  lowered = [...(ir.headerLines?.parameters?.[routine.name] ?? []), ...globalFieldSymbolDeclarations(ir, active, context), ...lowered];
  // Keep the ILI demo's fallback actions observable in browser runtimes.  The
  // native report deliberately does not construct the ActiveX control when it
  // is unavailable, so its later action forms would otherwise only update
  // the status text and return.  A hidden logical control preserves the
  // control's geometry/menu state without changing the initial fallback UI.
  if (/^SHOW_UNAVAILABLE$/i.test(String(routine.name ?? ""))
      && lowered.some((line) => /CREATE OBJECT go_fallback\b/i.test(line))
      && (ir.declarations ?? []).some((declaration) => (declaration.names ?? []).some((name) => String(name).toUpperCase() === "GO_ILI"))
      && (ir.declarations ?? []).some((declaration) => (declaration.names ?? []).some((name) => String(name).toUpperCase() === "GO_HOST"))) {
    const fallbackIndex = lowered.findIndex((line) => /CREATE OBJECT go_fallback\b/i.test(line));
    lowered.splice(fallbackIndex + 1, 0,
      "CREATE OBJECT go_ili EXPORTING parent = go_host.",
      "go_ili->hide( ).");
  }
  if (lowered.some((line) => line.includes("lo_writer->"))) lowered = addWriterDeclaration(lowered);
  return lowered;
}

function dynproDataType(element: Metadata): string {
  const attributes = element.attributes ?? {};
  const format = String(attributes.format ?? "CHAR").toUpperCase();
  const typ = ({ DATS: "D", TIMS: "T", INT4: "I", QUAN: "P", CURR: "P" } as Record<string, string>)[format] ?? "C";
  const defaultLengths: Record<string, number> = { DATS: 10, TIMS: 8, INT4: 10, QUAN: 14, CURR: 12, UNIT: 3, CUKY: 5 };
  const length = Number(element.length ?? defaultLengths[format] ?? 1);
  const fields = [
    "typ = '" + typ + "'",
    "length = " + (Number.isFinite(length) && length > 0 ? length : 1),
  ];
  const decimals = ({ QUAN: 3, CURR: 2 } as Record<string, number>)[format];
  if (decimals !== undefined) fields.push("decimals = " + decimals);
  return "VALUE #( " + fields.join(" ") + " )";
}

function dynproPosition(element: Metadata): string {
  const position = element.position ?? {};
  const line = Number(position.line ?? element.line ?? 1);
  const column = Number(position.column ?? element.column ?? 1);
  const width = Number(position.visibleWidth ?? element.visibleLength ?? position.width ?? element.length ?? 1);
  const height = Number(position.height ?? element.height ?? 1);
  const safeLine = Number.isFinite(line) ? line : 1;
  const safeColumn = Number.isFinite(column) ? column : 1;
  const safeWidth = Number.isFinite(width) && width > 0 ? width : 1;
  const safeHeight = Number.isFinite(height) && height > 0 ? height : 1;
  return "VALUE #( row = " + ((safeLine - 1) * 26 + 10)
    + " column = " + ((safeColumn - 1) * 10 + 5)
    + " width = " + (safeWidth * 10)
    + " height = " + Math.max(safeHeight * 26, 26) + " )";
}

function dynproControl(element: Metadata): string {
  const name = String(element.name ?? "").toUpperCase();
  const fields = [
    "name = '" + name + "'",
    "position = " + dynproPosition(element),
  ];
  const modifId = element.attributes?.modifId
    ?? element.attributes?.modifid
    ?? element.attributes?.group1;
  if (modifId) fields.push("modif_id = '" + String(modifId).toUpperCase() + "'");
  return "VALUE #( " + fields.join(" ") + " )";
}

// The Screen Painter resizing attributes of a container, with the minimum size
// in the same pixel units as dynproPosition; empty for a fixed size control.
function dynproResizing(container: Metadata): string {
  const resizable = container.resizable ?? {};
  if (!resizable.vertical && !resizable.horizontal) return "";
  const fields: string[] = [];
  if (resizable.vertical) {
    fields.push("vertical = abap_true");
    if (resizable.minLines > 0) fields.push("min_height = " + resizable.minLines * 26);
  }
  if (resizable.horizontal) {
    fields.push("horizontal = abap_true");
    if (resizable.minColumns > 0) fields.push("min_width = " + resizable.minColumns * 10);
  }
  return " resizing = VALUE #( " + fields.join(" ") + " )";
}

function dynproTabDefinitions(screen: Metadata, flowLogic: Metadata[] | undefined): Metadata[] {
  const screenNumber = String(screen.number ?? "").padStart(4, "0");
  const flows = (flowLogic ?? []).filter((flow) => String(flow.screen ?? "").padStart(4, "0") === screenNumber);
  const flowFor = (area: unknown): Metadata | undefined => flows
    .flatMap((flow) => flow.steps ?? [])
    .find((step: Metadata) => step.kind === "subscreen" && step.phase === "pbo"
      && String(step.area ?? "").toUpperCase() === String(area ?? "").toUpperCase()
      && (step.screen || step.screenField));
  const targetFor = (area: unknown) => flowFor(area)?.screen;
  const fieldFor = (area: unknown) => flowFor(area)?.screenField;
  const containers: Metadata[] = screen.containers ?? [];
  return containers
    .filter((container) => String(container.type ?? container.kind ?? "").toUpperCase() === "STRIP_CTRL")
    .map((container) => {
      const name = String(container.name ?? "").toUpperCase();
      const areas = containers
        .filter((area) => String(area.type ?? area.kind ?? "").toUpperCase() === "SUBSCREEN"
          && String(area.elementOf ?? "").toUpperCase() === name)
        .map((area) => ({
          name: String(area.name ?? "").toUpperCase(),
          line: area.line,
          column: area.column,
          length: area.length,
          height: area.height,
          control: dynproControl(area),
          subscreen: targetFor(area.name),
          screenField: fieldFor(area.name),
        }));
      const tabs = (screen.elements ?? [])
        .filter((element: Metadata) => String(element.attributes?.contName ?? "").toUpperCase() === name
          && (element.kind === "input-output" || element.kind === "pushbutton")
          && element.ucomm)
        .sort((left: Metadata, right: Metadata) => Number(left.line ?? 0) - Number(right.line ?? 0)
          || Number(left.column ?? 0) - Number(right.column ?? 0))
        .map((element: Metadata) => {
          const areaName = element.attributes?.refField;
          const area = areas.find((item) => item.name === String(areaName ?? "").toUpperCase());
          return {
            name: String(element.name ?? "").toUpperCase(),
            line: element.line,
            column: element.column,
            control: dynproControl(element),
            // A pushbutton tab has its own text; a template tab shows the
            // value of the field it names.
            text: element.kind === "pushbutton" && element.text ? element.text : element.name,
            ucomm: String(element.ucomm).toUpperCase(),
            subscreen: area?.subscreen,
          };
        });
      return {
        name,
        line: container.line,
        column: container.column,
        control: dynproControl(container),
        tabs,
        areas,
      };
    })
    .filter((strip) => strip.name && (strip.tabs.length || strip.areas.length));
}

function dynproSubscreenAreas(screen: Metadata, flowLogic: Metadata[] | undefined): Metadata[] {
  const screenNumber = String(screen.number ?? "").padStart(4, "0");
  const flows = (flowLogic ?? []).filter((flow) => String(flow.screen ?? "").padStart(4, "0") === screenNumber);
  const flowFor = (area: unknown): Metadata | undefined => flows
    .flatMap((flow) => flow.steps ?? [])
    .find((step: Metadata) => step.kind === "subscreen" && step.phase === "pbo"
      && String(step.area ?? "").toUpperCase() === String(area ?? "").toUpperCase()
      && (step.screen || step.screenField));
  return (screen.containers ?? [])
    .filter((container: Metadata) => String(container.type ?? container.kind ?? "").toUpperCase() === "SUBSCREEN")
    .map((area: Metadata) => ({
      name: String(area.name ?? "").toUpperCase(),
      line: area.line,
      column: area.column,
      control: dynproControl(area),
      subscreen: flowFor(area.name)?.screen,
      screenField: flowFor(area.name)?.screenField,
    }))
    .filter((area: Metadata) => area.name);
}

function dynproTableDefinitions(screen: Metadata | undefined): Metadata[] {
  if (!screen) return [];
  const elements: Metadata[] = screen.elements ?? [];
  const containers: Metadata[] = (screen.containers ?? []).filter((container: Metadata) =>
    String(container.type ?? container.kind ?? "").toUpperCase() === "TABLE_CTRL");
  return containers.map((container) => {
    const name = String(container.name ?? "").toUpperCase();
    const children = elements
      .filter((element) => String(element.attributes?.contName ?? "").toUpperCase() === name)
      .sort((left, right) => Number(left.column ?? 0) - Number(right.column ?? 0));
    const headings = children.filter((element) => element.kind === "text");
    const columns = children
      .filter((element) => element.kind !== "text" && element.name)
      .map((element) => ({
        name: String(element.name).split("-").slice(1).join("-").toUpperCase() || String(element.name).toUpperCase(),
        dataType: dynproDataType(element),
        width: Math.max(1, Number(element.visibleLength ?? element.length ?? 1)) * 10,
        input: element.input === true,
        required: element.required === true,
        checkbox: element.kind === "checkbox",
        title: headings.find((heading) => Number(heading.column ?? 0) === Number(element.column ?? 0))?.text
          ?? (element.kind === "checkbox" && element.column === undefined ? "" : String(element.name).split("-").at(-1)),
      }));
    const attributes = container.attributes ?? {};
    return {
      name,
      rowPrefix: String(children.find((element) => element.name?.includes("-"))?.name ?? "GS_ROW").split("-")[0].toUpperCase(),
      // The internal table is the one PBO loops over WITH CONTROL.
      tableVariable: ((screen.flowLogic?.steps ?? []).find((step: Metadata) => step.kind === "table-loop-begin"
        && step.phase === "pbo" && step.tableControl === name)?.table ?? `GT_${name.replace(/^TC_/, "")}`).toLowerCase(),
      control: dynproControl(container),
      visibleRows: Math.max(1, Number(container.height ?? container.position?.height ?? 1) - 1),
      selectionMode: String(attributes.tcSelLns ?? attributes.tcSelCls ?? "NONE").toUpperCase(),
      withHscroll: String(attributes.cScrollH ?? "").toUpperCase() === "X",
      withVscroll: String(attributes.cScrollV ?? "").toUpperCase() === "X",
      columns,
    };
  }).filter((table) => table.name && table.columns.length);
}

function dynproTableBindings(metadata: Metadata | undefined): Metadata[] {
  return (metadata?.screens ?? []).flatMap((screen: Metadata) => dynproTableDefinitions(screen));
}

// The CONTROLS ... TYPE TABLEVIEW structures of the program; the host reads
// and changes their TOP_LINE and LINES like screen fields.
function tableViews(ir: ReportIR): string[] {
  return (ir.statements ?? [])
    .filter((statement) => statement.kind === "Controls")
    .map((statement) => controlsDeclaration(statement.text))
    .filter((controls) => controls?.type === "TABLEVIEW")
    .map((controls) => controls!.name.toUpperCase());
}

function tableViewHydrate(views: string[]): string[] {
  return views.flatMap((view) => [
    ...["TOP_LINE", "LINES"].flatMap((field) => [
      `IF line_exists( it_values[ name = '${view}-${field}' ] ).`,
      `  ${view.toLowerCase()}-${field.toLowerCase()} = CONV #( it_values[ name = '${view}-${field}' ]-value ).`,
      "ENDIF.",
    ]),
    // The runtime shows a table control from its first line.
    `IF ${view.toLowerCase()}-top_line = 0.`,
    `  ${view.toLowerCase()}-top_line = 1.`,
    "ENDIF.",
  ]);
}

function tableViewFlush(views: string[]): string[] {
  return views.flatMap((view) => ["TOP_LINE", "LINES"].flatMap((field) => [
    `IF line_exists( ct_values[ name = '${view}-${field}' ] ).`,
    `  ct_values[ name = '${view}-${field}' ]-value = CONV string( ${view.toLowerCase()}-${field.toLowerCase()} ).`,
    "ELSE.",
    `  INSERT VALUE #( name = '${view}-${field}' value = CONV string( ${view.toLowerCase()}-${field.toLowerCase()} ) ) INTO TABLE ct_values.`,
    "ENDIF.",
  ]));
}

// A module that ends with CALL SCREEN, LEAVE or an error message unwinds with
// zcx_gg_control_flow. What it changed before is still the program's data, so
// the values are written back on that way out too.
function keptOnUnwind(dispatchLines: string[], flushLines: string[]): string[] {
  if (!dispatchLines.length || !flushLines.length) return [...dispatchLines, ...flushLines];
  // CATCH and RAISE again rather than CLEANUP, which the transpiler ignores.
  // The values are written once, after ENDTRY, on both ways out.
  return [
    "DATA lx_unwind TYPE REF TO zcx_gg_control_flow.",
    "TRY.", ...dispatchLines, "CATCH zcx_gg_control_flow INTO lx_unwind.", "ENDTRY.",
    ...flushLines,
    "IF lx_unwind IS BOUND.", "RAISE EXCEPTION lx_unwind.", "ENDIF.",
  ];
}

// A method's declarations go to its top, as an ABAP declaration does not
// depend on where it stands: the DATA of the modules that share a method, or
// of a statement lowered into several. A structure declared with BEGIN OF
// keeps the body as it is.
function hoistDeclarations(body: string[]): string[] {
  const lines = body.flatMap((line) => String(line).split("\n"));
  if (lines.some((line) => /^\s*(?:DATA|TYPES|CONSTANTS)\b.*\b(?:BEGIN|END)\s+OF\b/i.test(line))) return body;
  const declarations: string[] = [];
  const rest: string[] = [];
  for (const line of lines) {
    if (/^\s*(?:TYPES|DATA|FIELD-SYMBOLS|CONSTANTS)\s+[^\s(:]+\s.*\.\s*$/i.test(line)) {
      if (!declarations.includes(line.trim())) declarations.push(line.trim());
    } else {
      rest.push(line);
    }
  }
  return [...declarations, ...rest];
}

function dynproTableHydrate(bindings: Metadata[]): string[] {
  const lines: string[] = [];
  for (const [tableIndex, table] of bindings.entries()) {
    // Named by the table's position: a name built from the table control's
    // name can pass the 30 characters ABAP allows.
    const rowSymbol = `<ls_table${tableIndex + 1}_hydrate_row>`;
    const rowIndex = `lv_table${tableIndex + 1}_hydrate_row`;
    lines.push(`LOOP AT ${table.tableVariable} ASSIGNING FIELD-SYMBOL(${rowSymbol}).`);
    lines.push(`  DATA(${rowIndex}) = sy-tabix.`);
    for (const column of table.columns) {
      lines.push(`  IF line_exists( it_values[ container = '${table.name}' name = '${column.name}' row = ${rowIndex} ] ).`);
      lines.push(`    ${rowSymbol}-${column.name.toLowerCase()} = CONV #( it_values[ container = '${table.name}' name = '${column.name}' row = ${rowIndex} ]-value ).`);
      lines.push("  ENDIF.");
    }
    lines.push("ENDLOOP.");
  }
  return lines;
}

// The table line a module works on: its row of the table control inside the
// loop, none outside it.
function dynproTableCurrentRow(bindings: Metadata[]): string[] {
  return bindings.flatMap((table) => [
    `IF is_context-table_control = '${table.name}' AND is_context-row > 0.`,
    `  ${table.name.toLowerCase()}-current_line = is_context-row.`,
    `  READ TABLE ${table.tableVariable} INTO ${table.rowPrefix.toLowerCase()} INDEX is_context-row.`,
    "ELSEIF is_context-row = 0.",
    `  CLEAR ${table.rowPrefix.toLowerCase()}.`,
    "ENDIF.",
  ]);
}

// Table controls and their TABLEVIEW structures exchange values with the
// screen in two methods of their own, which every module call shares.
function dynproExchangeDefinitions(ir: ReportIR, metadata: Metadata | undefined): string[] {
  if (!metadata || !(dynproTableBindings(metadata).length || tableViews(ir).length)) return [];
  return [
    "METHODS table_values_in\n  IMPORTING\n    it_values TYPE zif_gg_dynpro_types_v1=>ty_values.",
    "METHODS table_values_out\n  CHANGING\n    ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.",
  ];
}

// The PBO and PAI modules of all screens, one method each; the interface
// methods around them exchange the values with the screen.
function dynproModuleDefinitions(ir: ReportIR): string[] {
  const context = "  IMPORTING\n    is_context TYPE zif_gg_dynpro_types_v1=>ty_module_context\n    io_session TYPE REF TO zif_gg_session_v1\n  CHANGING\n    ct_values  TYPE zif_gg_dynpro_types_v1=>ty_values";
  return [
    ...(ir.modules.some((item) => item.direction === "OUTPUT")
      ? [`METHODS output_modules\n${context}\n    ct_states  TYPE zif_gg_dynpro_types_v1=>ty_states.`] : []),
    ...(ir.modules.some((item) => item.direction === "INPUT")
      ? [`METHODS input_modules\n${context}.`] : []),
  ];
}

function moduleCall(name: string, withStates: boolean): string {
  return [
    `${name}(`,
    "  EXPORTING",
    "    is_context = is_context",
    "    io_session = io_session",
    "  CHANGING",
    `    ct_values  = ct_values${withStates ? "" : " )."}`,
    ...(withStates ? ["    ct_states  = ct_states )."] : []),
  ].join("\n");
}

export function dynproPrivateDefinitions(ir: ReportIR, metadata: Metadata | undefined): string[] {
  if (!metadata) return [];
  return [...dynproModuleDefinitions(ir), ...dynproExchangeDefinitions(ir, metadata)];
}

function dynproExchangeMethods(ir: ReportIR, metadata: Metadata | undefined): GeneratedMethod[] {
  if (!dynproExchangeDefinitions(ir, metadata).length) return [];
  const bindings = dynproTableBindings(metadata);
  const views = tableViews(ir);
  return [
    method("table_values_in", [...dynproTableHydrate(bindings), ...tableViewHydrate(views)]),
    method("table_values_out", [...dynproTableFlush(bindings), ...tableViewFlush(views)]),
  ];
}

function dynproTableFlush(bindings: Metadata[]): string[] {
  const lines: string[] = [];
  for (const [tableIndex, table] of bindings.entries()) {
    const rowSymbol = `<ls_table${tableIndex + 1}_flush_row>`;
    const rowIndex = `lv_table${tableIndex + 1}_flush_row`;
    lines.push(`DELETE ct_values WHERE container = '${table.name}'.`);
    lines.push(`LOOP AT ${table.tableVariable} ASSIGNING FIELD-SYMBOL(${rowSymbol}).`);
    lines.push(`  DATA(${rowIndex}) = sy-tabix.`);
    for (const column of table.columns) {
      lines.push(`  INSERT VALUE #( container = '${table.name}' name = '${column.name}' row = ${rowIndex} value = CONV string( ${rowSymbol}-${column.name.toLowerCase()} ) ) INTO TABLE ct_values.`);
    }
    lines.push("ENDLOOP.");
  }
  return lines;
}

function dynproMethods(ir: ReportIR, metadata: Metadata | undefined = ir.dynproMetadata, interfaceName = "zif_gg_dynpro_v1", {presentationOnly = false}: { presentationOnly?: boolean } = {}): GeneratedMethod[] {
  const interfaceMethod = (name: string) => `${interfaceName}~${name}`;
  if (!metadata) {
    const todo = ["* TODO GGCONV-E502: supply dynpro metadata before activating this class."];
    return [
      method(interfaceMethod("get_initial_screen"), ["RETURN."]),
      method(interfaceMethod("build_screens"), todo),
      method(interfaceMethod("build_flow_logic"), todo),
      method(interfaceMethod("initialization"), ["RETURN."]),
      method(interfaceMethod("process_output_module"), todo),
      method(interfaceMethod("process_input_module"), todo),
      method(interfaceMethod("process_on_value_request"), ["RETURN."]),
      method(interfaceMethod("process_on_help_request"), ["RETURN."]),
    ];
  }
  const screenNumber = (value: unknown) => String(value ?? "").padStart(4, "0");
  const screens: Metadata[] = Array.isArray(metadata.screens) ? metadata.screens : [];
  const tableBindings = dynproTableBindings(metadata);
  const initial = screenNumber(metadata.initialScreen ?? screens[0]?.number ?? "0100");
  const screenFields = (screen: Metadata) => {
    const fields = [`number = '${screenNumber(screen.number)}'`];
    if (screen.title) fields.push(`title = ${literal(screen.title)}`);
    if (screen.nextScreen !== undefined) fields.push(`next_screen = '${screenNumber(screen.nextScreen)}'`);
    const okCode = screen.okCode ? String(screen.okCode).trim().toUpperCase() : screenOkCode(screen.elements);
    if (okCode) fields.push(`ok_code = '${okCode}'`);
    if (screen.modal) fields.push("modal = abap_true");
    if (screen.width !== undefined) fields.push(`width = ${screen.width * 10}`);
    if (screen.height !== undefined) fields.push(`height = ${screen.height * 26 + 20}`);
    return fields.join(" ");
  };
  const flowLogic: Metadata[] = Array.isArray(metadata.flowLogic) ? metadata.flowLogic : [];
  const hasDynproValueRequest = (name: unknown) => flowLogic.some((screen) =>
    (screen.steps ?? []).some((step: Metadata) => step.phase === "pov"
      && (!step.field || String(step.field).toUpperCase() === String(name).toUpperCase())));
  const buildScreens: string[] = [];
  const radioGroups = new Map<string, string>();
  let radioGroupIndex = 0;
  const radioGroup = (element: Metadata) => {
    const source = String(element.attributes?.contName ?? element.attributes?.elementOf ?? "RADIO");
    if (!radioGroups.has(source)) {
      radioGroupIndex += 1;
      radioGroups.set(source, "G" + String(radioGroupIndex).padStart(3, "0"));
    }
    return radioGroups.get(source);
  };
  for (const screen of screens) {
    buildScreens.push("io_builder->begin_screen( VALUE #( " + screenFields(screen) + " ) ).");
    const tables = dynproTableDefinitions(screen);
    const tabstrips = dynproTabDefinitions(screen, flowLogic);
    const genericSubscreenAreas = dynproSubscreenAreas(screen, flowLogic);
    const tableChildren = new Set(tables.flatMap((table) => (screen.elements ?? [])
      .filter((element: Metadata) => String(element.attributes?.contName ?? "").toUpperCase() === table.name)
      .map((element: Metadata) => element.name)));
    const tabChildren = new Set(tabstrips.flatMap((strip) => strip.tabs.map((tab: Metadata) => tab.name)));
    const tabSubscreenAreas = new Set(tabstrips.flatMap((strip) => strip.areas.map((area: Metadata) => area.name)));
    const subscreenAreas = new Set([
      ...tabSubscreenAreas,
      ...genericSubscreenAreas.map((area) => area.name),
    ]);
    const items: Metadata[] = [
      ...(screen.elements ?? []).filter((element: Metadata) => element.name
        && !tableChildren.has(element.name)
        && !tabChildren.has(element.name)
        && !subscreenAreas.has(element.name)),
      ...tables.map((table) => ({
        kind: "table-control",
        name: table.name,
        line: screen.containers?.find((container: Metadata) => String(container.name).toUpperCase() === table.name)?.line ?? 1,
        column: screen.containers?.find((container: Metadata) => String(container.name).toUpperCase() === table.name)?.column ?? 1,
        table,
      })),
      ...tabstrips.map((strip) => ({
        kind: "tabstrip",
        name: strip.name,
        line: strip.line,
        column: strip.column,
        tabstrip: strip,
      })),
      ...tabstrips.flatMap((strip) => strip.areas.map((area: Metadata) => ({
        kind: "subscreen-area",
        name: area.name,
        line: area.line,
        column: area.column,
        area,
      }))),
      ...genericSubscreenAreas
        .filter((area) => !tabSubscreenAreas.has(area.name))
        .map((area) => ({
          kind: "subscreen-area",
          name: area.name,
          line: area.line,
          column: area.column,
          area,
        })),
      ...(screen.containers ?? [])
        .filter((container: Metadata) => String(container.type ?? container.kind ?? "").toUpperCase() === "CUST_CTRL")
        .map((container: Metadata) => ({
          kind: "custom-control",
          name: String(container.name ?? "").toUpperCase(),
          line: container.line,
          column: container.column,
          customControl: container,
        })),
    ].sort((left, right) => Number(left.line ?? left.position?.line ?? 1) - Number(right.line ?? right.position?.line ?? 1)
      || Number(left.column ?? left.position?.column ?? 1) - Number(right.column ?? right.position?.column ?? 1));
    for (const element of items) {
      if (element.kind === "table-control") {
        const table = element.table;
        buildScreens.push(`io_builder->begin_table_control( VALUE #( control = ${table.control} visible_rows = ${table.visibleRows} selection_mode = '${table.selectionMode}' with_hscroll = ${table.withHscroll ? "abap_true" : "abap_false"} with_vscroll = ${table.withVscroll ? "abap_true" : "abap_false"} ) ).`);
        for (const column of table.columns) {
          buildScreens.push(`io_builder->add_table_column( VALUE #( table_control = '${table.name}' name = '${column.name}' state_name = '${table.rowPrefix}-${column.name}' title = ${literal(column.title ?? column.name)} data_type = ${column.dataType} width = ${column.width} input = ${column.input ? "abap_true" : "abap_false"} required = ${column.required ? "abap_true" : "abap_false"} checkbox = ${column.checkbox ? "abap_true" : "abap_false"} ) ).`);
        }
        buildScreens.push("io_builder->end_table_control( ).");
        continue;
      }
      if (element.kind === "tabstrip") {
        const strip = element.tabstrip;
        buildScreens.push(`io_builder->add_tabstrip( VALUE #( control = ${strip.control} ) ).`);
        for (const tab of strip.tabs) {
          const fields = [
            `control = ${tab.control}`,
            `tabstrip = '${strip.name}'`,
            `text = ${literal(tab.text)}`,
            `ucomm = '${tab.ucomm}'`,
          ];
          if (tab.subscreen) fields.splice(3, 0, `subscreen = '${screenNumber(tab.subscreen)}'`);
          buildScreens.push(`io_builder->add_tab( VALUE #( ${fields.join(" ")} ) ).`);
        }
        continue;
      }
      if (element.kind === "subscreen-area") {
        const fields = [`control = ${element.area.control}`];
        if (element.area.subscreen) fields.push(`subscreen = '${screenNumber(element.area.subscreen)}'`);
        if (element.area.screenField) fields.push(`screen_field = '${element.area.screenField}'`);
        buildScreens.push(`io_builder->add_subscreen_area( VALUE #( ${fields.join(" ")} ) ).`);
        continue;
      }
      if (element.kind === "custom-control") {
        buildScreens.push(`io_builder->add_custom_control( VALUE #( control = ${dynproControl(element.customControl)}${dynproResizing(element.customControl)} ) ).`);
        continue;
      }
      const control = dynproControl(element);
      const dataType = dynproDataType(element);
      if (element.kind === "frame") {
        buildScreens.push("io_builder->add_box( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + " ) ).");
      } else if (element.kind === "text") {
        buildScreens.push("io_builder->add_text( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + " ) ).");
      } else if (element.kind === "dropdown"
          || (element.kind === "input-output" && String(element.attributes?.dropdown ?? "").toUpperCase() === "L")) {
        buildScreens.push("io_builder->add_listbox( VALUE #( control = " + control + " data_type = " + dataType + " ) ).");
      } else if (element.kind === "input-output" || element.kind === "input") {
        const fields = ["control = " + control, "data_type = " + dataType];
        if (String(element.attributes?.cxtMenon ?? "").toUpperCase() === "INPUT") fields.push("context_menu = abap_true");
        if (element.required) fields.push("required = abap_true");
        if (element.invisible) fields.push("password = abap_true");
        if (hasDynproValueRequest(element.name)
            || ["X", "1", "TRUE", "Y"].includes(String(element.attributes?.possEntry ?? "").toUpperCase())) {
          fields.push("value_help = abap_true");
        }
        buildScreens.push("io_builder->add_input_field( VALUE #( " + fields.join(" ") + " ) ).");
      } else if (element.kind === "output") {
        buildScreens.push("io_builder->add_output_field( VALUE #( control = " + control + " data_type = " + dataType + " ) ).");
      } else if (element.kind === "pushbutton") {
        const exitCommand = String(element.pushType ?? element.attributes?.pushFtype ?? "").toUpperCase() === "E" ? " exit_command = abap_true" : "";
        buildScreens.push("io_builder->add_pushbutton( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + " ucomm = '" + String(element.ucomm ?? "").toUpperCase() + "'" + exitCommand + " ) ).");
      } else if (element.kind === "checkbox") {
        // A checkbox or radio button with a function code triggers PAI when clicked.
        const ucomm = element.ucomm ? ` ucomm = '${String(element.ucomm).toUpperCase()}'` : "";
        buildScreens.push("io_builder->add_checkbox( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + ucomm + " ) ).");
      } else if (element.kind === "radio") {
        const ucomm = element.ucomm ? ` ucomm = '${String(element.ucomm).toUpperCase()}'` : "";
        buildScreens.push("io_builder->add_radiobutton( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + " group = '" + radioGroup(element) + "'" + ucomm + " ) ).");
      }
    }
    buildScreens.push("io_builder->end_screen( ).");
  }
  const buildFlow: string[] = [];
  for (const screen of flowLogic) {
    buildFlow.push(`io_builder->begin_screen( '${screenNumber(screen.screen)}' ).`);
    const fallbackSteps: Metadata[] = [];
    const addFallbackPhase = (phase: string, entries: Metadata[] | undefined) => {
      if (!entries?.length) return;
      fallbackSteps.push({ kind: "process", phase });
      fallbackSteps.push(...entries.map((entry) => ({
        kind: "module",
        phase,
        ...(typeof entry === "string" ? { name: entry } : entry),
      })));
    };
    addFallbackPhase("pbo", screen.pbo);
    addFallbackPhase("pai", screen.pai);
    if (screen.pov?.modules?.length) {
      fallbackSteps.push({ kind: "process", phase: "pov", field: screen.pov.field });
      fallbackSteps.push(...screen.pov.modules.map((entry: Metadata) => ({ kind: "module", phase: "pov", ...entry })));
    }
    if (screen.poh?.modules?.length) {
      fallbackSteps.push({ kind: "process", phase: "poh", field: screen.poh.field });
      fallbackSteps.push(...screen.poh.modules.map((entry: Metadata) => ({ kind: "module", phase: "poh", ...entry })));
    }
    const steps: Metadata[] = screen.steps?.length ? screen.steps : fallbackSteps;
    let openPhase: string | undefined;
    const addModule = (phase: string | undefined, item: Metadata | string) => {
      const module = typeof item === "string" ? { name: item } : item;
      const flags: string[] = [];
      if (phase === "pai" || module.onInput) flags.push(" on_input = abap_true");
      if (module.onRequest) flags.push(" on_request = abap_true");
      if (module.onChainRequest) flags.push(" on_chain_request = abap_true");
      if (module.atExitCommand) flags.push(" at_exit_command = abap_true");
      buildFlow.push(`io_builder->add_module( VALUE #( name = '${String(module.name ?? "").toUpperCase()}'${flags.join("")} ) ).`);
    };
    for (const step of steps) {
      if (step.kind === "process") {
        if (openPhase) buildFlow.push("io_builder->end_processing( ).");
        openPhase = step.phase;
        const begin = ({ pbo: "begin_pbo", pai: "begin_pai", pov: "begin_value_request", poh: "begin_help_request" } as Record<string, string>)[openPhase!];
        if (begin === "begin_value_request" || begin === "begin_help_request") {
          buildFlow.push(`io_builder->${begin}( '${String(step.field ?? "").toUpperCase()}' ).`);
        } else if (begin) buildFlow.push(`io_builder->${begin}( ).`);
      } else if (step.kind === "field") {
        buildFlow.push(`io_builder->add_field( '${String(step.field ?? "").toUpperCase()}' ).`);
      } else if (step.kind === "module" || step.kind === "field-module") {
        if (step.kind === "field-module" && step.field && (openPhase === "pai" || openPhase === "pbo")) {
          buildFlow.push(`io_builder->add_field( '${String(step.field).toUpperCase()}' ).`);
        }
        addModule(openPhase, step);
      } else if (step.kind === "chain-begin") {
        buildFlow.push("io_builder->begin_chain( ).");
      } else if (step.kind === "chain-end") {
        buildFlow.push("io_builder->end_chain( ).");
      } else if (step.kind === "subscreen") {
        const fields = [`area = '${String(step.area ?? "").toUpperCase()}'`];
        if (step.screen) fields.push(`screen = '${screenNumber(step.screen)}'`);
        if (step.screenField) fields.push(`screen_field = '${String(step.screenField).toUpperCase()}'`);
        buildFlow.push(`io_builder->call_subscreen( VALUE #( ${fields.join(" ")} ) ).`);
      } else if (step.kind === "table-loop-begin") {
        const table = step.tableControl ?? dynproTableDefinitions(screens.find((item) => screenNumber(item.number) === screenNumber(screen.screen)))?.[0]?.name ?? "";
        buildFlow.push(`io_builder->begin_table_loop( VALUE #( table_control = '${table}' ) ).`);
      } else if (step.kind === "table-loop-end") {
        buildFlow.push("io_builder->end_table_loop( ).");
      }
    }
    if (openPhase) buildFlow.push("io_builder->end_processing( ).");
    buildFlow.push("io_builder->end_screen( ).");
  }
  const dispatch = (direction: string) => {
    const modules = ir.modules.filter((item) => item.direction === direction);
    // A screen without modules of this direction has nothing to dispatch; a
    // RETURN here would skip writing the values back.
    if (!modules.length) return [];
    const lines = ["CASE is_context-module."];
    for (const module of modules) {
      const context: LoweringContext = {
        ...methodContext(ir, "dynpro"),
        ucomm: "is_context-ucomm",
        ...(direction === "OUTPUT" ? {} : { screenStates: storedScreenStates("dynpro", { row: "is_context-row" }) }),
      };
      const body = [
        ...globalFieldSymbolDeclarations(ir, module.statements, context),
        ...removePromotedDeclarations(ir, lowerStatements(module.statements.filter(statement => !ir.declarations?.some(item => item.statement === statement)), context).map((item) => item.text)),
      ];
      lines.push(`WHEN '${module.name}'.`, ...body);
    }
    if (lines.some((line) => line.includes("lo_writer->"))) lines.splice(0, 0, "DATA(lo_writer) = io_session->get_list( )->get_writer( ).");
    lines.push("WHEN OTHERS.", "RETURN.", "ENDCASE.");
    return lines;
  };
  const statusByScreen = metadata.statuses ?? metadata.statusByScreen ?? metadata.guiStatuses ?? {};
  const statusLines: string[] = [];
  for (const [screen, value] of Object.entries<Metadata>(statusByScreen)) {
    if (!value || typeof value !== "object") continue;
    const fields = [`status = ${literal(value.status ?? value.name ?? "")}`];
    const active = value.activeUcomm ?? value.active_ucomm ?? [];
    const excluded = value.excludedUcomm ?? value.excluded_ucomm ?? [];
    if (active.length) fields.push(`active_ucomm = VALUE #( ${active.map((item: unknown) => `( '${String(item).toUpperCase()}' )`).join(" ")} )`);
    if (excluded.length) fields.push(`excluded_ucomm = VALUE #( ${excluded.map((item: unknown) => `( '${String(item).toUpperCase()}' )`).join(" ")} )`);
    const guiStatus = ir.guiStatusMetadata?.[String(value.status ?? value.name ?? "").toUpperCase()]
      ?? ir.guiStatusMetadata?.[value.status ?? value.name];
    if (guiStatus?.activePFKeys?.length || guiStatus?.active_pf_keys?.length) {
      const keys = guiStatus.activePFKeys ?? guiStatus.active_pf_keys;
      fields.push(`active_pf_keys = VALUE #( ${[...new Set(keys)].map((key) => `( ${Number(key)} )`).join(" ")} )`);
    }
    if (guiStatus?.pfActions?.length || guiStatus?.pf_actions?.length) {
      const actions = guiStatus.pfActions ?? guiStatus.pf_actions;
      fields.push(`pf_actions = VALUE #( ${actions.map((item: Metadata) => `( number = ${Number(item.number ?? item.functionKey)} ucomm = '${String(item.ucomm ?? item.functionCode ?? "").toUpperCase()}' )`).join(" ")} )`);
    }
    if (guiStatus?.iconBar?.length || guiStatus?.icon_bar?.length) {
      const icons = guiStatus.iconBar ?? guiStatus.icon_bar;
      fields.push(`icon_bar = VALUE #( ${icons.map((item: Metadata) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' label = ${textLiteral(String(item.label ?? ""))} icon = ${literal(String(item.icon ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} )`);
    }
    if (guiStatus?.menus?.length) {
      fields.push(`menus = VALUE #( ${guiStatus.menus.map((menu: Metadata) => `( code = ${literal(String(menu.code ?? ""))} text = ${literal(String(menu.text ?? ""))} path = ${literal(String(menu.path ?? ""))} items = VALUE #( ${(
        menu.items ?? []
      ).map((item: Metadata) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' text = ${literal(String(item.text ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} ) )`).join(" ")} )`);
    }
    statusLines.push(`IF is_context-screen = '${screenNumber(screen)}'.`);
    statusLines.push(`io_session->get_dialog( )->set_status( VALUE #( ${fields.join(" ")} ) ).`);
    statusLines.push("ENDIF.");
  }
  const cursorLines = screens
    .filter((screen) => screen.cursor)
    .flatMap((screen) => [
      `IF is_context-screen = '${screenNumber(screen.number)}'.`,
      `io_session->get_dialog( )->set_cursor( VALUE #( field = '${String(screen.cursor).toUpperCase()}' ) ).`,
      "ENDIF.",
    ]);
  const stateHydrate = dynproStateHydrate(ir);
  const stateFlush = dynproStateFlush(ir);
  const exchange = dynproExchangeDefinitions(ir, metadata).length > 0;
  const outputModules = dispatch("OUTPUT");
  const inputModules = dispatch("INPUT");
  const tableHydrate = exchange ? ["table_values_in( ct_values )."] : [];
  const tableFlush = exchange ? ["table_values_out( CHANGING ct_values = ct_values )."] : [];
  const tableContext = dynproTableCurrentRow(tableBindings);
  const requestDispatch = (phase: string) => {
    const requestModules = flowLogic
      .flatMap((screen) => screen.steps ?? [])
      .filter((step: Metadata) => step.phase === phase && (step.kind === "module" || step.kind === "field-module"))
      .map((step: Metadata) => String(step.name ?? "").toUpperCase())
      .filter(Boolean);
    const modules = ir.modules.filter((item) => requestModules.includes(String(item.name ?? "").toUpperCase()));
    const lines = [
      "DATA ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.",
      "ct_values = it_values.",
    ];
    if (!modules.length) return lines;
    lines.push(
      ...dynproStateHydrate(ir),
      ...tableHydrate,
      ...tableContext,
      "CASE is_context-module.",
    );
    for (const module of modules) {
      const context: LoweringContext = {
        ...methodContext(ir, "dynpro"),
        ucomm: "is_context-ucomm",
        screenStates: storedScreenStates("dynpro", { row: "is_context-row" }),
      };
      const body = [
        ...globalFieldSymbolDeclarations(ir, module.statements, context),
        ...removePromotedDeclarations(ir, lowerStatements(module.statements.filter(statement => !ir.declarations?.some(item => item.statement === statement)), context).map((item) => item.text)),
      ];
      lines.push(`WHEN '${module.name}'.`, ...body);
    }
    lines.push(
      "WHEN OTHERS.",
      "RETURN.",
      "ENDCASE.",
      ...dynproStateFlush(ir),
      ...tableFlush,
    );
    return lines;
  };
  const valueRequest = [
    ...requestDispatch("pov"),
    "rt_values = io_session->get_compatibility( )->get_value_help_values( ).",
  ];
  const helpRequest = [
    ...requestDispatch("poh"),
  ];
  const methods = [
    method(interfaceMethod("get_initial_screen"), [`rv_screen = '${initial}'.`]),
    method(interfaceMethod("build_screens"), buildScreens),
    method(interfaceMethod("build_flow_logic"), buildFlow),
    method(interfaceMethod("initialization"), [...stateFlush, ...tableFlush]),
    method(interfaceMethod("process_output_module"), hoistDeclarations([...dynproStatesSetter(ir), ...stateHydrate, ...tableHydrate, ...tableContext, ...statusLines, ...cursorLines, ...keptOnUnwind(outputModules.length
      ? [moduleCall("output_modules", true)]
      : [], [...stateFlush, ...tableFlush])])),
    // A screen without PAI modules has nothing to read or write back.
    method(interfaceMethod("process_input_module"), inputModules.length
      ? hoistDeclarations([...dynproStateHydrate(ir, "ct_values", screenInputField(metadata)), ...tableHydrate, ...tableContext, ...keptOnUnwind(
        [moduleCall("input_modules", false)], [...stateFlush, ...tableFlush])])
      : ["RETURN."]),
    method(interfaceMethod("process_on_value_request"), hoistDeclarations(valueRequest)),
    method(interfaceMethod("process_on_help_request"), hoistDeclarations(helpRequest)),
    ...(presentationOnly ? [] : [
      ...(outputModules.length ? [method("output_modules", hoistDeclarations(outputModules))] : []),
      ...(inputModules.length ? [method("input_modules", hoistDeclarations(inputModules))] : []),
      ...dynproExchangeMethods(ir, metadata),
    ]),
  ];
  if (!presentationOnly) return methods;
  return [
    ...methods.slice(0, 3),
    method(interfaceMethod("initialization"), ["RETURN."]),
    method(interfaceMethod("process_output_module"), cursorLines.length ? cursorLines : ["RETURN."]),
    method(interfaceMethod("process_input_module"), ["RETURN."]),
    method(interfaceMethod("process_on_value_request"), ["RETURN."]),
    method(interfaceMethod("process_on_help_request"), ["RETURN."]),
  ];
}

function contextMenuMethod(ir: ReportIR): GeneratedMethod | undefined {
  const routine = contextMenuRoutine(ir);
  if (!routine) return undefined;
  const screenField = (ir.screenMetadata?.screens ?? ir.dynproMetadata?.screens ?? [])
    .flatMap((screen: Metadata) => screen.elements ?? [])
    .find((element: Metadata) => String(element.attributes?.cxtMenon ?? "").toUpperCase() === "INPUT")?.name;
  const body = [
    "DATA lo_menu TYPE REF TO cl_ctmenu.",
    "CREATE OBJECT lo_menu.",
    ...(screenField ? [`IF iv_field = '${String(screenField).toUpperCase()}'.`] : []),
    `  ${routine.methodName}(
      EXPORTING
        io_session = io_session
        io_menu    = lo_menu ).`,
    ...(screenField ? ["ENDIF."] : []),
    "ro_menu = lo_menu.",
  ];
  return method("zif_gg_context_menu_v1~get_context_menu", body);
}

function helperDefinitionHeader(localClass: LocalClass, generatedName: string, ir: ReportIR): string {
  const raw = localClass.definitionHeader ?? `CLASS ${localClass.name} DEFINITION.`;
  // The additions after DEFINITION; the helper class is PUBLIC itself.
  const ast = statementAst(raw.trim());
  const tokens = ast?.tokens() ?? [];
  const definition = tokens.find((entry) => isKeyword(entry.node) && entry.token.getUpperStr() === "DEFINITION");
  const global = ast?.find(Expressions.ClassGlobal);
  const last = tokens.at(-1);
  const end = last && /^[.,]$/.test(last.token.getStr()) ? last.start : raw.trim().length;
  let rest = ast && definition ? raw.trim().slice(global ? ast.end(global) : definition.end, end).trim() : "";
  if (!ast?.containsPhrase("CREATE")) rest = `${rest}${rest ? " " : ""}CREATE PUBLIC`;
  return `CLASS ${generatedName.toLowerCase()} DEFINITION PUBLIC${rest ? ` ${renameIdentifiers(rest, allRenames(ir))}` : ""}.`;
}

// A static event handler is called by the event, which passes only the event's
// parameters, so it cannot take io_owner and io_session like other static
// methods. It reads them from static attributes that SET HANDLER fills instead.
function staticEventHandlerNames(localClass: LocalClass): Set<string> {
  return new Set((localClass.definition ?? [])
    .map((statement) => methodDefinition(statement.text))
    .filter((definition) => definition?.isStatic && definition.isEventHandler)
    .map((definition) => definition!.name.toUpperCase()));
}

function helperMethodContext(ir: ReportIR, localClass: LocalClass, localMethod: LocalClassMethod | undefined): LoweringContext {
  const isStaticMethod = (localClass.definition ?? []).some((statement) => {
    const definition = methodDefinition(statement.text);
    return definition?.isStatic && definition.name.toUpperCase() === String(localMethod?.name ?? "").toUpperCase();
  });
  const isEventHandler = staticEventHandlerNames(localClass).has(String(localMethod?.name ?? "").toUpperCase());
  const context = methodContext(ir, "local_class", {
    statements: localMethod?.statements ?? ir.statements ?? [],
  });
  const [owner, session] = isEventHandler
    ? ["go_owner", "go_session"]
    : isStaticMethod ? ["io_owner", "io_session"] : ["mo_owner", "mo_session"];
  context.ucomm = "sy-ucomm";
  context.sessionVariable = session;
  context.ownerPrefix = `${owner}->`;
  context.screenStates = storedScreenStates(screenStatePlan(ir).defaultKind, { owner: context.ownerPrefix });
  context.localClassOwner = owner;
  context.localClassName = String(localClass.name ?? "").toUpperCase();
  const ownerReplacements = Object.fromEntries(Object.entries(globalMemberNames(ir))
    .map(([name, member]) => [name, `${context.ownerPrefix}${member}`]));
  // The types the method names, in its definition and its statements.
  const typeNames = (text: string | undefined) => {
    const ast = statementAst(String(text ?? "").trim());
    return ast ? ast.findEvery(Expressions.TypeName).map((name) => ast.source(name).split(/-|=>/)[0].toUpperCase()) : [];
  };
  const localTypeUses = new Set([
    ...typeNames(localMethod?.definition?.text),
    ...(localMethod?.statements ?? []).flatMap((statement) => typeNames(statement.text)),
  ]);
  const ownerTypeReplacements = (ir.declarations ?? [])
    .filter((declaration) => ["type", "typebegin"].includes(declaration.kind))
    .flatMap((declaration) => (declaration.names ?? [])
      .filter((name) => localTypeUses.has(name.toUpperCase()))
      .map((name): Replacement => [name, `${ir.targetClassName!.toLowerCase()}=>${name.toLowerCase()}`]));
  context.replacements = [
    ...Object.entries(ownerReplacements),
    ...ownerTypeReplacements,
    ...Object.entries(ir.statePlan?.renames ?? {}),
    ...(ir.selections ?? []).flatMap((screen) => (screen.elements ?? [])
      .filter((item) => item.name)
      .flatMap((item) => {
        // The member lives on the owner class, like the report globals above.
        const reference = `${context.ownerPrefix}${ir.statePlan?.selectionState?.[item.name!]?.member ?? item.name!.toLowerCase()}`;
        const fields: Replacement[] = item.kind === "select-option"
          ? [[`${item.name}-low`, `${reference}[ 1 ]-low`], [`${item.name}-high`, `${reference}[ 1 ]-high`]]
          : [];
        return [...fields, [item.name!, reference] as Replacement];
      })),
    ...Object.entries(ir.localClassRenames ?? {}).map(([name, value]): Replacement => [name, String(value).toLowerCase()]),
  ];
  context.controlObjectTypes = controlObjectTypes(ir.declarations ?? [], ir.localClasses ?? [], {
    statements: localMethod?.statements ?? [],
  });
  context.isStaticMethod = isStaticMethod;
  return context;
}

function helperMethodBody(ir: ReportIR, localClass: LocalClass, localMethod: LocalClassMethod): string[] {
  const statements = truncateTerminalPaths(localMethod.statements ?? []);
  const context = helperMethodContext(ir, localClass, localMethod);
  let body = lowerStatements(statements, context).map((item) => item.text);
  body = [...globalFieldSymbolDeclarations(ir, statements, context), ...body];
  if (body.some((line) => line.includes("lo_writer->"))) body = addWriterDeclaration(body);
  // Lowering writes io_session, the writer declaration included; methods
  // without that parameter use the session the helper stores for its owner.
  // `io_session =` is a named argument and stays.
  if (context.sessionVariable !== "io_session") {
    body = body.map((line) => line.replace(/\bio_session\b/gi, (name: string, offset: number, source: string) =>
      /^\s*=/.test(source.slice(offset + name.length)) ? name : context.sessionVariable!));
  }
  return body.length ? body : ["RETURN."];
}

function helperDefinitionBody(statements: Statement[], rename: (text: string) => string): string[] {
  const lines: string[] = [];
  let structured: { keyword: string; beginName: string; components: string[]; endName: string | undefined } | undefined;
  const flushStructured = () => {
    if (!structured) return;
    lines.push(`  ${structuredDeclaration(structured.keyword, structured.beginName, structured.components, structured.endName ?? structured.beginName)}`);
    structured = undefined;
  };
  for (const statement of statements) {
    const text = rename(statement.text).replace(/\s+$/, "");
    if (statement.kind === "Comment") {
      flushStructured();
      // `*` is only a comment in column 1, so divider comments must keep that
      // column instead of being indented into the generated class body.
      lines.push(text.split("\n").map((line) => line.trim()).join("\n"));
      continue;
    }
    if (["DataBegin", "TypeBegin", "ConstantBegin"].includes(statement.kind)) {
      flushStructured();
      structured = {
        keyword: ({ DataBegin: "DATA", TypeBegin: "TYPES", ConstantBegin: "CONSTANTS" } as Record<string, string>)[statement.kind],
        beginName: declaredName(text) ?? "",
        components: [],
        endName: undefined,
      };
      continue;
    }
    if (structured && ["DataEnd", "TypeEnd", "ConstantEnd"].includes(statement.kind)) {
      structured.endName = declaredName(text) ?? structured.beginName;
      flushStructured();
      continue;
    }
    if (structured) {
      // Components carry their own terminator: a comma in the chained form, a
      // period in the classic `DATA BEGIN OF x. DATA fld. DATA END OF x.` form.
      // The structure is always re-emitted as one chain, so drop the terminator
      // here and let flushStructured put the commas back.
      const component = declarationBody(text, structured.keyword);
      if (component) structured.components.push(component);
      continue;
    }
    // abaplint splits chained declarations into one statement per element,
    // repeating the keyword and keeping the comma. Each element becomes a
    // standalone member, so the comma must become a terminator.
    // Continuation lines keep their indentation, so a definition over several
    // lines keeps its layout.
    lines.push(...text.split("\n").map((line, index, all) => {
      const kept = index === 0 ? `  ${line.trim()}` : line.trimEnd();
      return index === all.length - 1 ? kept.replace(/,\s*$/, ".") : kept;
    }));
  }
  flushStructured();
  return lines;
}

// Adds parameters to a METHODS or CLASS-METHODS definition. IMPORTING comes
// before EXPORTING, CHANGING, RETURNING, RAISING and EXCEPTIONS, so the
// parameters close an existing IMPORTING or open one ahead of those. A chained
// definition ends in a comma, which becomes a period like other chain elements.
function withImportingParameters(definition: string, parameters: string): string {
  const text = definition.replace(/\s*[.,]\s*$/, "");
  const masked = text.replace(/'(?:''|[^'])*'|`(?:``|[^`])*`|"[^\n]*/g, (part) => " ".repeat(part.length));
  const importing = /\bIMPORTING\b/i.exec(masked);
  const from = importing ? importing.index + importing[0].length : 0;
  const next = /\b(?:EXPORTING|CHANGING|RETURNING|RAISING|EXCEPTIONS)\b/i.exec(masked.slice(from));
  // Insert after the last code ahead of that keyword, not into a " comment.
  const at = masked.slice(0, next ? from + next.index : masked.length).trimEnd().length;
  if (!importing) return `${text.slice(0, at)}\n      IMPORTING\n        ${parameters}${text.slice(at)}.`;
  return alignImporting(`${text.slice(0, at)}\n        ${parameters}${text.slice(at)}.`);
}

// A definition written on one line, METHODS m IMPORTING p TYPE t, gets its
// parameters below IMPORTING, one per line with aligned types, as the lint
// rules ask once more parameters follow.
function alignImporting(definition: string): string {
  const lines = definition.split("\n");
  const at = lines.findIndex((line) => /\bIMPORTING\b/i.test(line));
  if (at < 0) return definition;
  const sameLine = /^(\s*)(.*?)\s*\bIMPORTING\s+(\S.*)$/i.exec(lines[at]);
  if (sameLine) {
    const head = sameLine[2] ? [`${sameLine[1]}${sameLine[2]}`] : [];
    lines.splice(at, 1, ...head, "      IMPORTING", `        ${sameLine[3]}`);
  }
  const start = lines.findIndex((line) => /^\s*IMPORTING\s*$/i.test(line));
  if (start < 0) return lines.join("\n");
  let end = start + 1;
  while (end < lines.length && !/^\s*(?:EXPORTING|CHANGING|RETURNING|RAISING|EXCEPTIONS)\b/i.test(lines[end])) end++;
  const parameters = lines.slice(start + 1, end).map((line) => /^\s*(\S+)\s+(TYPE\b.*)$/i.exec(line));
  if (!parameters.length || parameters.some((match) => !match)) return lines.join("\n");
  const width = Math.max(...parameters.map((match) => match![1].length));
  parameters.forEach((match, index) => {
    lines[start + 1 + index] = `        ${match![1].padEnd(width, " ")} ${match![2]}`;
  });
  return lines.join("\n");
}

function helperSource(ir: ReportIR, options: ClassOptions, localClass: LocalClass): string {
  const generatedName = localClass.generatedName!;
  const rename = (text: string) => renameIdentifiers(text, allRenames(ir));
  // One parameter per line with aligned types, as the lint rules ask.
  const ownerSessionParameters = `io_owner   TYPE REF TO ${ir.targetClassName!.toLowerCase()}\n        io_session TYPE REF TO zif_gg_session_v1`;
  const originalConstructor = (localClass.methods ?? []).find((localMethod) => localMethod.name?.toUpperCase() === "CONSTRUCTOR");
  const constructorSignature = originalConstructor?.definition?.text
    ? withImportingParameters(rename(originalConstructor.definition.text), ownerSessionParameters)
    : `METHODS constructor\n      IMPORTING\n        ${ownerSessionParameters}.`;
  const eventHandlers = staticEventHandlerNames(localClass);
  const bridge = [
    `    ${constructorSignature}`,
    `    DATA mo_owner TYPE REF TO ${ir.targetClassName!.toLowerCase()}.`,
    "    DATA mo_session TYPE REF TO zif_gg_session_v1.",
    ...(eventHandlers.size ? [
      `    CLASS-DATA go_owner TYPE REF TO ${ir.targetClassName!.toLowerCase()}.`,
      "    CLASS-DATA go_session TYPE REF TO zif_gg_session_v1.",
    ] : []),
  ];
  // Static methods, other than event handlers, get the owner and session as
  // parameters. They are added before the statement is split into lines, so a
  // definition spanning several lines keeps its parameters in order.
  const definitionWithStaticBridges = helperDefinitionBody(
    (localClass.definition ?? [])
      .filter((statement) => {
        const definition = statement.kind === "MethodDef" ? methodDefinition(statement.text) : undefined;
        return !(definition && !definition.isStatic && definition.name.toUpperCase() === "CONSTRUCTOR");
      })
      .map((statement) => {
        const text = rename(statement.text);
        const definition = methodDefinition(text);
        const bridged = Boolean(definition?.isStatic && !definition.isEventHandler && !mentions(text, "IO_OWNER"));
        return { ...statement, text: bridged ? withImportingParameters(text, ownerSessionParameters) : text };
      }),
    (text) => text,
  // PUBLIC SECTION . is the same statement; it is written PUBLIC SECTION., so
  // the bridge goes into the program's own public section.
  ).map((line) => line.replace(/^(\s*)(PUBLIC|PROTECTED|PRIVATE)\s+SECTION\s*\.\s*$/i, (_, space, visibility) => `${space}${visibility.toUpperCase()} SECTION.`));
  const publicSection = definitionWithStaticBridges.findIndex((line) => /^\s*PUBLIC SECTION\.$/i.test(line));
  const definitionBody = publicSection >= 0
    ? [...definitionWithStaticBridges.slice(0, publicSection + 1), ...bridge, ...definitionWithStaticBridges.slice(publicSection + 1)]
    : ["  PUBLIC SECTION.", ...bridge, ...definitionWithStaticBridges];
  const definition = [
    helperDefinitionHeader(localClass, generatedName, ir),
    "",
    ...definitionBody,
    "",
    "ENDCLASS.",
    "",
    `CLASS ${generatedName.toLowerCase()} IMPLEMENTATION.`,
    "",
  ];
  const implementations = [
    method("constructor", [
      "mo_owner = io_owner.",
      "mo_session = io_session.",
      ...(originalConstructor ? helperMethodBody(ir, localClass, originalConstructor) : []),
    ]),
    ...(localClass.methods ?? [])
    .filter((localMethod) => localMethod.statement && localMethod.name?.toUpperCase() !== "CONSTRUCTOR")
    .map((localMethod) => method(localMethod.name.toLowerCase(), helperMethodBody(ir, localClass, localMethod))),
  ];
  return `${header({ className: generatedName, ir })}${definition.join("\n")}${implementations.join("\n")}ENDCLASS.\n`.replace(/\r?\n/g, "\n");
}

export function emitHelperSources(ir: ReportIR, options: ClassOptions): HelperSource[] {
  prepareLocalClassNames(ir, options);
  return (ir.localClasses ?? []).map((localClass) => ({
    className: localClass.generatedName!,
    sourceName: localClass.name,
    source: helperSource(ir, options, localClass),
  }));
}

export function emitClassSource(ir: ReportIR, options: ClassOptions): string {
  prepareLocalClassNames(ir, options);
  const className = ir.targetClassName!.toLowerCase();
  const interfaces = interfaceOrder(ir);
  const members = [
    ...dataMembers(ir),
    ...dynproPrivateDefinitions(ir, ir.programKind === "module-pool" ? ir.dynproMetadata
      : ir.screenMetadata?.screens?.length ? ir.screenMetadata : undefined),
  ];
  const friends = (ir.localClasses ?? []).map((localClass) => localClass.generatedName!.toLowerCase());
  const friendAddition = friends.length ? ` FRIENDS ${friends.join(" ")}` : "";
  const definition = [`CLASS ${className} DEFINITION PUBLIC FINAL CREATE PUBLIC${friendAddition}.`, "", "  PUBLIC SECTION.", ...interfaces.map((name) => `    INTERFACES ${name}.`), ""];
  if (members.length) definition.push("  PRIVATE SECTION.", ...members.flatMap((line) => line.split("\n").map((part) => `    ${part}`)), "");
  definition.push("ENDCLASS.", "", `CLASS ${className} IMPLEMENTATION.`, "");
  const implementation: (GeneratedMethod | string)[] = [];
  if (ir.interfaces.includes("zif_gg_transaction_v1")) {
    implementation.push(method("zif_gg_transaction_v1~get_transaction", [`rs_transaction = VALUE #( tcode = '${ir.transactionCode}' description = '${String(ir.description).replaceAll("'", "''")}'${programField(ir)} ).`]));
  }
  if (ir.interfaces.includes("zif_gg_program_v1")) implementation.push(programMethod(ir));
  if (ir.programKind === "module-pool") implementation.push(...dynproMethods(ir));
  else {
    implementation.push(...reportMethods(ir));
    if (ir.screenMetadata?.screens?.length) implementation.push(...dynproMethods(ir, ir.screenMetadata, "zif_gg_screen_provider_v1"));
  }
  if (ir.interfaces.includes("zif_gg_list_processing_v1")) implementation.push(...listMethods(ir));
  if (ir.interfaces.includes("zif_gg_resumable_v1")) implementation.push(resumeMethod(ir));
  const contextMethod = contextMenuMethod(ir);
  if (contextMethod) implementation.push(contextMethod);
  for (const routine of ir.routines) {
    implementation.push(method(routine.methodName!, routineBody(ir, routine)));
  }
  implementation.push("ENDCLASS.", "");
  return `${header({ className: ir.targetClassName!, ir })}${definition.join("\n")}\n${implementation.join("\n")}`.replace(/\r?\n/g, "\n");
}

export function emitPartialSkeleton(ir: ReportIR, options: ClassOptions, diagnostics: Diagnostic[]): string {
  const className = ir.targetClassName!.toLowerCase();
  const diagnosticLines = diagnostics
    .filter((item) => item.severity === "error" || item.severity === "warning")
    .map((item) => `${item.code}: ${item.construct}`)
    .filter((value, index, values) => values.indexOf(value) === index);
  const startBody = [
    `io_session->get_list( )->set_title( ${textLiteral(ir.reportTitle ?? ir.programName ?? ir.targetClassName)} ).`,
    "DATA(lo_writer) = io_session->get_list( )->get_writer( ).",
    `lo_writer->write_field( VALUE #( text = ${literal("Partial conversion preview")} placement = VALUE #( new_line = abap_true ) ) ).`,
    `lo_writer->write_field( VALUE #( text = ${literal(`Source report: ${ir.programName ?? "UNKNOWN"}`)} placement = VALUE #( new_line = abap_true ) ) ).`,
    `lo_writer->write_field( VALUE #( text = ${literal("Unsupported source remains as explicit converter diagnostics.")} placement = VALUE #( new_line = abap_true ) ) ).`,
    ...diagnosticLines.map((line) => `lo_writer->write_field( VALUE #( text = ${literal(line)} placement = VALUE #( new_line = abap_true ) ) ).`),
  ];
  const methods = REPORT_METHODS.map((name) => method(
    `zif_gg_report_v1~${name}`,
    name === "load_of_program" && ir.reportTitle
      ? [`io_session->get_list( )->set_title( ${textLiteral(ir.reportTitle)} ).`]
      : name === "start_of_selection" ? startBody : ["RETURN."],
  ));
  const todos = diagnostics
    .filter((item) => item.severity === "error" || item.code.startsWith("GGCONV-E"))
    .map((item) => `* TODO ${item.code}: ${item.construct}`)
    .filter((value, index, values) => values.indexOf(value) === index);
  return `${header({className: ir.targetClassName!, ir})}${todos.join("\n")}${todos.length ? "\n" : ""}` + [
    `CLASS ${className} DEFINITION PUBLIC FINAL CREATE PUBLIC.`,
    "",
    "  PUBLIC SECTION.",
    "    INTERFACES zif_gg_report_v1.",
    ...(ir.transactionCode ? ["    INTERFACES zif_gg_transaction_v1."] : []),
    ...(hasProgramMetadata(ir) ? ["    INTERFACES zif_gg_program_v1."] : []),
    "",
    "ENDCLASS.",
    "",
    `CLASS ${className} IMPLEMENTATION.`,
    "",
    ...(ir.transactionCode ? [method("zif_gg_transaction_v1~get_transaction", [
      `rs_transaction = VALUE #( tcode = ${literal(ir.transactionCode)} description = ${literal(ir.description)}${programField(ir)} ).`,
    ]).toString()] : []),
    ...(hasProgramMetadata(ir) ? [programMethod(ir).toString()] : []),
    ...methods.map((entry) => entry.toString()),
    "ENDCLASS.",
    "",
  ].join("\n");
}

export function emitPartialApplication(ir: ReportIR, options: ClassOptions, diagnostics: Diagnostic[]): string {
  const className = ir.targetClassName!.toLowerCase();
  const hasScreenProvider = ir.programKind === "report" && (ir.screenMetadata?.screens?.length ?? 0) > 0;
  const interfaceNames = (ir.programKind === "module-pool"
    ? ["zif_gg_dynpro_v1", "zif_gg_transaction_v1"]
    : ["zif_gg_report_v1", "zif_gg_transaction_v1", ...(hasScreenProvider ? ["zif_gg_screen_provider_v1"] : [])])
    .filter((name) => name !== "zif_gg_transaction_v1" || ir.transactionCode)
    .concat(hasProgramMetadata(ir) ? ["zif_gg_program_v1"] : []);
  const definition = [
    `CLASS ${className} DEFINITION PUBLIC FINAL CREATE PUBLIC.`,
    "",
    "  PUBLIC SECTION.",
    ...interfaceNames.map((name) => `    INTERFACES ${name}.`),
    "",
    "ENDCLASS.",
    "",
    `CLASS ${className} IMPLEMENTATION.`,
    "",
  ];
  const label = ir.reportTitle ?? ir.description ?? ir.programName ?? ir.targetClassName;
  const applicationBody = [
    `io_session->get_list( )->set_title( ${textLiteral(label)} ).`,
    "DATA(lo_writer) = io_session->get_list( )->get_writer( ).",
    `lo_writer->write_field( VALUE #( text = ${literal(label)} placement = VALUE #( new_line = abap_true ) ) ).`,
    `lo_writer->write_field( VALUE #( text = ${literal("Application content is available; unsupported optional operations remain in converter diagnostics.")} placement = VALUE #( new_line = abap_true ) ) ).`,
  ];
  const screenBody = hasScreenProvider
    ? [`io_session->get_dialog( )->call_screen(
      is_call         = VALUE #( screen = '${String(ir.screenMetadata!.initialScreen ?? ir.screenMetadata!.screens[0]?.number ?? "0100").padStart(4, "0")}' )
      is_continuation = VALUE #( id = 'PARTIAL_SCREEN' ) ).`]
    : applicationBody;
  const methods = [];
  if (ir.programKind === "module-pool") {
    methods.push(
      method("zif_gg_dynpro_v1~get_initial_screen", [`rv_screen = '${String(ir.dynproMetadata?.initialScreen ?? "0100").padStart(4, "0")}'.`]),
      method("zif_gg_dynpro_v1~build_screens", ["RETURN."]),
      method("zif_gg_dynpro_v1~build_flow_logic", ["RETURN."]),
      method("zif_gg_dynpro_v1~initialization", ["RETURN."]),
      method("zif_gg_dynpro_v1~process_output_module", ["RETURN."]),
      method("zif_gg_dynpro_v1~process_input_module", ["RETURN."]),
      method("zif_gg_dynpro_v1~process_on_value_request", ["RETURN."]),
      method("zif_gg_dynpro_v1~process_on_help_request", ["RETURN."]),
    );
  } else {
    for (const name of REPORT_METHODS) {
      const body = name === "build_screen"
        ? selectionBuilder(ir)
        : name === "load_of_program" && ir.reportTitle
          ? [`io_session->get_list( )->set_title( ${textLiteral(ir.reportTitle)} ).`]
        : name === "start_of_selection" ? screenBody : ["RETURN."];
      methods.push(method(`zif_gg_report_v1~${name}`, body.length ? body : ["RETURN."]));
    }
    if (hasScreenProvider) methods.push(...dynproMethods(ir, ir.screenMetadata, "zif_gg_screen_provider_v1", {presentationOnly: true}));
  }
  const todos = diagnostics
    .filter((item) => item.severity === "error" || item.code.startsWith("GGCONV-E"))
    .map((item) => `* TODO ${item.code}: ${item.construct}`)
    .filter((value, index, values) => values.indexOf(value) === index);
  const transaction = method("zif_gg_transaction_v1~get_transaction", [
    `rs_transaction = VALUE #( tcode = ${literal(ir.transactionCode)} description = ${literal(label)}${programField(ir)} ).`,
  ]);
  return `${header({className: ir.targetClassName!, ir})}${todos.join("\n")}${todos.length ? "\n" : ""}${[
    ...definition,
    ...(ir.transactionCode ? [transaction.toString()] : []),
    ...(hasProgramMetadata(ir) ? [programMethod(ir, label).toString()] : []),
    ...methods.map((entry) => entry.toString()),
    "ENDCLASS.",
    "",
  ].join("\n")}`;
}

export function lowerToScaffoldIR(ir: ReportIR, sourceMap: SourceMapSegment[] = []): Metadata {
  const methods = [];
  if (ir.interfaces.includes("zif_gg_transaction_v1")) {
    methods.push(method("zif_gg_transaction_v1~get_transaction", [`rs_transaction = VALUE #( tcode = '${ir.transactionCode}' description = '${String(ir.description).replaceAll("'", "''")}'${programField(ir)} ).`]));
  }
  if (ir.interfaces.includes("zif_gg_program_v1")) methods.push(programMethod(ir));
  if (ir.programKind === "module-pool") methods.push(...dynproMethods(ir));
  else {
    methods.push(...reportMethods(ir));
    if (ir.screenMetadata?.screens?.length) methods.push(...dynproMethods(ir, ir.screenMetadata, "zif_gg_screen_provider_v1"));
  }
  if (ir.interfaces.includes("zif_gg_list_processing_v1")) methods.push(...listMethods(ir));
  if (ir.interfaces.includes("zif_gg_resumable_v1")) methods.push(resumeMethod(ir));
  const contextMethod = contextMenuMethod(ir);
  if (contextMethod) methods.push(contextMethod);
  for (const routine of ir.routines) {
    methods.push(method(routine.methodName!, routineBody(ir, routine)));
  }
  return scaffoldIR({
    className: ir.targetClassName,
    transactionCode: ir.transactionCode,
    description: ir.description,
    definition: { visibility: "public", final: true, create: "public" },
    transaction: { tcode: ir.transactionCode, description: ir.description },
    interfaces: interfaceOrder(ir),
    members: dataMembers(ir),
    methods: methods.map(({ name, body, comment }) => ({ name, body: [...body], ...(comment ? { comment } : {}) })),
    screenBuilder: {
      kind: ir.programKind === "module-pool" ? "dynpro" : "selection-screen",
      selections: ir.selections,
      dynproMetadata: ir.dynproMetadata,
      screenProviderMetadata: ir.screenMetadata?.screens?.length ? ir.screenMetadata : undefined,
    },
    listProcessing: {
      settings: ir.header,
      events: Object.fromEntries(LIST_METHODS.filter((name) => name !== "get_settings").map((name) => [name, ir.events?.[name] ?? []])),
    },
    continuations: (ir.continuations ?? []).map((continuation) => ({
      ...continuation,
      capturedVariables: (continuation.liveVariables ?? []).map((name) =>
        ir.statePlan?.selectionState?.[name]?.member
        ?? ir.statePlan?.renames?.[name]
        ?? name.toLowerCase()),
    })),
    noOpMethods: methods.filter((item) => item.body.length === 1 && item.body[0] === "RETURN.").map((item) => item.name),
    sourceMap,
  });
}
