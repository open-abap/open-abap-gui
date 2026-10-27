import { lowerCompatibilityFunction } from "../function-modules.js";
import { callsStatic, functionModule, hiddenFields, refToName } from "../abap/statements.js";
import { textLiteral } from "../emit/abap-text.js";
import { Expressions, Nodes, Statements, Tokens } from "@abaplint/core";
import { isKeyword, lexedAst, parsesAsStatement, spliceText, statementAst, typeAst } from "../abap/ast.js";
import type { StatementAst } from "../abap/ast.js";
import { assignTarget, bindsStatically, fieldSymbolsIn, inlineFieldSymbolsIn, isStaticAssign } from "../abap/statements.js";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import { inProgramPerform, isExternalPerform, isGenericParameterType, methodParameterType } from "./collect-routines.js";
import { isWritableArgument, performArguments, performedForm } from "../abap/statements.js";
import { isPopupStatement } from "./lower-continuations.js";
import { replaceIdentifiers } from "./replace-identifiers.js";
import { headerLineBegin, headerLineDeclarations, headerLineEnd, withoutHeaderLines } from "./header-lines.js";
import { likeTyping } from "./like-typing.js";
import type { ScreenStates } from "./screen-states.js";
import type { SelectionOptions } from "./collect-selection-screens.js";
import type { Continuation, DynamicAlv, FieldSymbolReference, LocalClass, Metadata, Routine, RoutineParameter, SelectionState, Statement } from "../types.js";

/** A [pattern, replacement] pair for replaceIdentifiers. */
export type Replacement = [string, string];

/**
 * What lowering a statement needs to know about the method it is lowered
 * into, built by methodContext in emit/class-source.ts.
 */
export interface LoweringContext {
  event: string;
  selections: { name: string; ranges: boolean; screen?: string }[];
  headerLines?: Record<string, string>;
  tablesWorkAreas?: Map<string, string | undefined>;
  dataObjects?: Set<string>;
  likeMember?: (name: string) => string | { type: string } | undefined;
  tabbedBlocks?: string[];
  messageId?: string;
  constantNames?: Set<string>;
  temporaries?: { count: number };
  mutableValues?: boolean;
  messageField?: string;
  ucomm?: string;
  replacements: Replacement[];
  hiddenNames?: string[];
  continuations?: Continuation[];
  routines?: Routine[];
  subrc?: string;
  activeCommands?: string[];
  activePFKeys?: number[];
  guiStatusMetadata?: Metadata;
  titlebarMetadata?: Metadata;
  selectionState?: Record<string, SelectionState>;
  dynamicWriteTargets?: { name: string; expression: string }[];
  dynamicCommentNames?: string[];
  localClassStaticMethods?: Record<string, Set<string>>;
  localClassStaticEventHandlers?: Record<string, Set<string>>;
  localClassStaticParameters?: Record<string, Record<string, string>>;
  localClassRenames?: Record<string, string>;
  controlObjectTypes?: Record<string, string>;
  safeFieldSymbols?: string[];
  fieldSymbolReferences?: Record<string, FieldSymbolReference>;
  dynamicAlv?: DynamicAlv;
  rangeDeclarations?: Record<string, string>;
  sessionVariable?: string;
  ownerPrefix?: string;
  localClassOwner?: string;
  localClassName?: string;
  isStaticMethod?: boolean;
  contextMenu?: boolean;
  screenStates?: ScreenStates;
  screenStateSymbol?: string;
  freeChainControlKeys?: Set<string>;
}

/** A lowered statement, as one or more lines of the generated method. */
export interface LoweredStatement {
  text: string;
  statement: Statement;
  supported: boolean;
}

const TYPE_CODES = new Map([
  ["C", "C"], ["N", "N"], ["D", "D"], ["T", "T"], ["I", "I"], ["INT4", "I"],
  ["P", "P"], ["F", "F"], ["X", "X"], ["STRING", "STRING"],
]);

const MESSAGE_TYPES = {
  A: "message_type_abort", E: "message_type_error", I: "message_type_info", S: "message_type_success",
  W: "message_type_warning", X: "message_type_exit",
};

const LIST_COLOR_FIELDS = Object.freeze({
  COL_BACKGROUND: "color_background", COL_HEADING: "color_heading", COL_NORMAL: "color_normal",
  COL_TOTAL: "color_total", COL_KEY: "color_key", COL_POSITIVE: "color_positive",
  COL_NEGATIVE: "color_negative", COL_GROUP: "color_group",
});

const LIST_COLOR_CONSTANTS = Object.freeze({
  COL_BACKGROUND: "color_background", COL_HEADING: "color_heading", COL_NORMAL: "color_normal",
  COL_TOTAL: "color_total", COL_KEY: "color_key", COL_POSITIVE: "color_positive",
  COL_NEGATIVE: "color_negative", COL_GROUP: "color_group",
});

function runtimeClassFiles(directory: string): string[] {
  if (!fs.existsSync(directory)) return [];
  const result: string[] = [];
  const visit = (current: string) => {
    for (const entry of fs.readdirSync(current, {withFileTypes: true}).sort((left, right) => left.name.localeCompare(right.name))) {
      const filename = path.join(current, entry.name);
      if (entry.isDirectory()) visit(filename);
      else if (/\.clas\.abap$/i.test(entry.name)) result.push(filename);
    }
  };
  visit(directory);
  return result;
}

// build/src/passes/, below the converter folder in the repository root.
const RUNTIME_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../src");
const RUNTIME_CLASS_FILES = runtimeClassFiles(RUNTIME_ROOT);

// These classes are implemented by the shipped runtime. Deriving the set
// from src/ keeps converter coverage aligned with the runtime inventory, while
// unknown GUI objects remain explicit converter gaps.
const CONVERTIBLE_CONTROL_CLASSES = new Set(
  RUNTIME_CLASS_FILES
    .map((filename) => path.basename(filename).replace(/\.clas\.abap$/i, "").toUpperCase())
    .filter((name) => name.startsWith("CL_")),
);

const CONVERTIBLE_STATIC_CLASSES = new Set([
  ...CONVERTIBLE_CONTROL_CLASSES,
  "ZCL_GG_GUI_DEMO_HELPER",
]);

// The runtime classes, parsed once.
const RUNTIME_CLASSES = RUNTIME_CLASS_FILES.map((filename) => ({
  className: path.basename(filename).replace(/\.clas\.abap$/i, "").toUpperCase(),
  ast: lexedAst(fs.readFileSync(filename, "utf8")),
}));

function runtimeMethodReturns(): Map<string, Map<string, string>> {
  const result = new Map<string, Map<string, string>>();
  for (const { className, ast } of RUNTIME_CLASSES) {
    const methods = new Map<string, string>();
    for (const statement of ast?.statements ?? []) {
      const name = statement.get() instanceof Statements.MethodDef ? statement.findDirectExpression(Expressions.MethodName) : undefined;
      const returning = statement.findDirectExpression(Expressions.MethodDefReturning);
      const returnType = ast && returning ? refToName(ast, returning) : undefined;
      if (name && returnType) methods.set(ast!.source(name).toUpperCase(), returnType);
    }
    if (methods.size) result.set(className, methods);
  }
  return result;
}

const RUNTIME_METHOD_RETURNS = runtimeMethodReturns();

// The parameters of each event typed as an object reference, by class.
function runtimeEventSignatures(): Map<string, Map<string, Record<string, string>>> {
  const result = new Map<string, Map<string, Record<string, string>>>();
  for (const { className, ast } of RUNTIME_CLASSES) {
    const events = new Map<string, Record<string, string>>();
    for (const statement of ast?.statements ?? []) {
      const name = statement.get() instanceof Statements.Events ? statement.findDirectExpression(Expressions.EventName) : undefined;
      if (!ast || !name) continue;
      const parameters: Record<string, string> = {};
      for (const parameter of statement.findAllExpressions(Expressions.MethodParam)) {
        const parameterName = parameter.findDirectExpression(Expressions.MethodParamName);
        const typing = parameter.findDirectExpression(Expressions.TypeParam);
        const type = typing ? refToName(ast, typing) : undefined;
        if (parameterName && type) parameters[ast.source(parameterName).toUpperCase()] = type;
      }
      events.set(ast.source(name).toUpperCase(), parameters);
    }
    if (events.size) result.set(className, events);
  }
  return result;
}

const RUNTIME_EVENT_SIGNATURES = runtimeEventSignatures();

function runtimeClassParents(): Map<string, string> {
  const result = new Map<string, string>();
  for (const { className, ast } of RUNTIME_CLASSES) {
    const definition = ast?.statements.find((statement) => statement.get() instanceof Statements.ClassDefinition);
    const parent = definition?.findDirectExpression(Expressions.SuperClassName);
    if (ast && parent) result.set(className, ast.source(parent).toUpperCase());
  }
  return result;
}

const RUNTIME_CLASS_PARENTS = runtimeClassParents();

function runtimeEventSignature(className: string, eventName: string): Record<string, string> | undefined {
  let current: string | undefined = String(className ?? "").toUpperCase();
  const visited = new Set();
  while (current && !visited.has(current)) {
    visited.add(current);
    const signature = RUNTIME_EVENT_SIGNATURES.get(current)?.get(String(eventName ?? "").toUpperCase());
    if (signature) return signature;
    current = RUNTIME_CLASS_PARENTS.get(current);
  }
  return undefined;
}

function localClassObjectTypes(localClasses: LocalClass[] | undefined): Set<string> {
  const result = new Set((localClasses ?? []).map((item) => String(item.name ?? "").toUpperCase()));
  return result;
}

function eventHandlerObjectTypes(localClasses: LocalClass[] | undefined): Record<string, string> {
  const result: Record<string, string> = {};
  for (const localClass of localClasses ?? []) {
    for (const method of localClass.methods ?? []) {
      const ast = statementAst(method.definition?.text ?? "");
      const handler = ast?.find(Expressions.EventHandler);
      const event = handler?.findDirectExpression(Expressions.EventName);
      const owner = handler?.findDirectExpression(Expressions.ClassName);
      if (!ast || !handler || !event || !owner) continue;
      const signature = runtimeEventSignature(ast.source(owner), ast.source(event));
      if (!signature) continue;
      for (const parameter of handler.findDirectExpressions(Expressions.MethodParamName)) {
        const name = ast.source(parameter).toUpperCase();
        const type = signature[name];
        if (type && CONVERTIBLE_CONTROL_CLASSES.has(type)) result[name] = type;
      }
    }
  }
  return result;
}

export function controlObjectTypes(declarations: { entries?: { name: string; definition: string }[] }[] = [], localClasses: LocalClass[] = [], {parameters = [], statements = []}: { parameters?: RoutineParameter[]; statements?: Statement[] } = {}): Record<string, string> {
  const result: Record<string, string> = {};
  const localClassNames = localClassObjectTypes(localClasses);
  for (const localClassName of localClassNames) result[localClassName] = `LOCAL:${localClassName}`;
  for (const declaration of declarations) {
    for (const entry of declaration.entries ?? []) {
      const typing = statementAst(`DATA ggconv_probe ${entry.definition ?? ""}.`);
      const type = typing ? refToName(typing, typing.node) : undefined;
      if (type && (CONVERTIBLE_CONTROL_CLASSES.has(type) || localClassNames.has(type))) {
        result[entry.name.toUpperCase()] = localClassNames.has(type) ? `LOCAL:${type}` : type;
      }
    }
  }
  for (const parameter of parameters ?? []) {
    const typing = typeAst(parameter.type ?? "");
    const type = typing ? refToName(typing, typing.node) : undefined;
    if (!type || (!CONVERTIBLE_CONTROL_CLASSES.has(type) && !localClassNames.has(type))) continue;
    result[String(parameter.name ?? "").toUpperCase()] = localClassNames.has(type) ? `LOCAL:${type}` : type;
  }
  for (const statement of statements ?? []) {
    const ast = statementAst(statement.text ?? "");
    if (!ast) continue;
    // DATA x TYPE REF TO c.
    const name = ast.is(Statements.Data) ? ast.find(Expressions.DefinitionName) : undefined;
    const typing = ast.find(Expressions.Type);
    const type = name && typing && ast.skeleton(typing) === "TYPE REF TO _" ? refToName(ast, typing) : undefined;
    if (name && type && (CONVERTIBLE_CONTROL_CLASSES.has(type) || localClassNames.has(type))) {
      result[ast.source(name).toUpperCase()] = localClassNames.has(type) ? `LOCAL:${type}` : type;
    }
    // DATA(x) = receiver->method( ), typed by what the runtime method returns.
    const inline = ast.is(Statements.Move) ? ast.findDirect(Expressions.Target)?.findDirectExpression(Expressions.InlineData) : undefined;
    const call = ast.findDirect(Expressions.Source)?.getChildren();
    const [receiver, arrow, method] = call?.length === 1 && call[0].get() instanceof Expressions.MethodCallChain
      ? (call[0] as Nodes.ExpressionNode).getChildren() : [];
    const methodName = method instanceof Nodes.ExpressionNode ? method.findDirectExpression(Expressions.MethodName) : undefined;
    const target = inline?.findDirectExpression(Expressions.TargetField);
    if (!target || !receiver || !methodName || ast.source(arrow) !== "->" || !/^[A-Z][A-Z0-9_]*$/i.test(ast.source(receiver))) continue;
    const receiverName = ast.source(receiver).toUpperCase();
    const receiverType = result[receiverName] ?? receiverName;
    const returned = RUNTIME_METHOD_RETURNS.get(receiverType)?.get(ast.source(methodName).toUpperCase());
    if (returned && CONVERTIBLE_CONTROL_CLASSES.has(returned)) result[ast.source(target).toUpperCase()] = returned;
  }
  Object.assign(result, eventHandlerObjectTypes(localClasses));
  return result;
}

function convertibleControlType(type: string | undefined, objectTypes: Record<string, string> | undefined): boolean {
  return CONVERTIBLE_CONTROL_CLASSES.has(String(type ?? "").toUpperCase())
    || String(objectTypes?.[String(type ?? "").toUpperCase()] ?? "").toUpperCase().startsWith("LOCAL:")
    || CONVERTIBLE_CONTROL_CLASSES.has(String(objectTypes?.[String(type ?? "").toUpperCase()] ?? "").toUpperCase());
}

// The variables a FREE releases; of a component or attribute, the variable
// holding it.
function freeReceivers(statement: Statement): string[] {
  const ast = lexedAst(statement.text ?? "");
  return (ast?.statements ?? []).flatMap((node) => node.findDirectExpressions(Expressions.Target))
    .map((target) => target.getFirstToken().getStr())
    .filter((name) => /^[A-Z][A-Z0-9_]*$/i.test(name));
}

function freeChainKey(statement: Statement): string | undefined {
  if (statement?.kind !== "Free") return undefined;
  const span: Metadata = statement.span ?? {};
  const start = span.startOffset ?? `${span.start?.line ?? span.start?.row ?? 0}:${span.start?.column ?? span.start?.col ?? 0}`;
  return `${statement.filename ?? ""}:${start}`;
}

function convertibleFreeChainKeys(statements: Statement[], objectTypes: Record<string, string> = {}): Set<string> {
  const groups = new Map<string, Statement[]>();
  for (const statement of statements ?? []) {
    const key = freeChainKey(statement);
    if (key) groups.set(key, [...(groups.get(key) ?? []), statement]);
  }
  return new Set([...groups.entries()]
    .filter(([, members]) => members.some((member) => freeReceivers(member).some((receiver) => convertibleControlType(receiver, objectTypes))))
    .map(([key]) => key));
}

// Return true only for a control statement whose receiver was declared with a
// scaffold-owned class. This deliberately does not infer from a variable name
// such as GO_GRID, because doing so could emit a call for an unrelated type.
function isConvertibleControlStatement(statement: Statement, objectTypes: Record<string, string> = {}): boolean {
  const ast = statementAst(String(statement?.text ?? "").trim());
  if (statement?.kind === "CreateObject") {
    const { target, explicitType } = ast ? createdObject(ast) : {};
    return convertibleControlType(explicitType, objectTypes) || convertibleControlType(target, objectTypes);
  }
  if (statement?.kind === "Call" || statement?.kind === "CallMethod") {
    // The first object, and the first class, a method is called on anywhere
    // in the statement, also in its arguments.
    const receiver = ast ? namedBefore(ast, "->") : undefined;
    const staticClass = ast ? namedBefore(ast, "=>") : undefined;
    return convertibleControlType(receiver, objectTypes)
      || CONVERTIBLE_STATIC_CLASSES.has(String(staticClass ?? "").toUpperCase())
      || convertibleControlType(staticClass, objectTypes);
  }
  if (statement?.kind === "SetHandler") {
    const receiver = ast?.after("FOR", ast.node)?.getFirstToken().getStr();
    return convertibleControlType(receiver, objectTypes);
  }
  if (statement?.kind === "Free") {
    return freeReceivers(statement).some((receiver) => convertibleControlType(receiver, objectTypes));
  }
  return false;
}

// The name before the first arrow of a kind, as in lo_grid->refresh( ) or
// cl_gui_cfw=>flush( ).
function namedBefore(ast: StatementAst, arrow: "->" | "=>"): string | undefined {
  const tokens = ast.tokens();
  const index = tokens.findIndex((entry, at) => entry.token.getStr() === arrow && at > 0
    && tokens[at - 1].end === entry.start && tokens[at - 1].node instanceof Nodes.TokenNodeRegex);
  return index > 0 ? tokens[index - 1].token.getStr() : undefined;
}

// CREATE OBJECT target [TYPE class]: the variable created, and the class
// named, both as written.
function createdObject(ast: StatementAst): { target?: string; targetToken?: Nodes.TokenNode; explicitType?: string } {
  const target = ast.findDirect(Expressions.Target);
  const first = target?.getFirstChild();
  const targetToken = target ? ast.tokens().find((entry) => entry.start === ast.start(target))?.node : undefined;
  const type = ast.after("TYPE", ast.node);
  return {
    target: first && /^[A-Z][A-Z0-9_]*$/i.test(targetToken?.getFirstToken().getStr() ?? "") ? targetToken!.getFirstToken().getStr() : undefined,
    targetToken,
    explicitType: type?.get() instanceof Expressions.ClassName ? ast.source(type) : undefined,
  };
}

const LIST_COLOR_REWRITES: Replacement[] = Object.entries(LIST_COLOR_CONSTANTS)
  .map(([name, constant]) => [name, `zif_gg_list_processing_types_v1=>${constant}`]);

// The statements the lowering visitor rewrites into scaffold operations. The
// manifest records the rule used for each statement; a statement with no rule
// here is carried over as written.
export const LOWERING_RULES = new Map([
  ["Assign", { kind: "field-symbol-assign" }],
  ["AuthorityCheck", { kind: "compatibility-authority-check" }],
  ["CallFunction", { kind: "compatibility-function-module" }],
  ["CallScreen", { kind: "dialog-call-screen" }],
  ["CallSelectionScreen", { kind: "dialog-call-selection-screen" }],
  ["CallTransaction", { kind: "navigation-call-transaction" }],
  ["Constant", { kind: "declaration" }],
  ["Controls", { kind: "declaration" }],
  ["Data", { kind: "declaration" }],
  ["Export", { kind: "session-abap-memory-export" }],
  ["FieldSymbol", { kind: "field-symbol-declaration" }],
  ["Format", { kind: "list-format" }],
  ["FreeMemory", { kind: "session-abap-memory-free" }],
  ["GetCursor", { kind: "list-cursor" }],
  ["GetParameter", { kind: "compatibility-parameter-get" }],
  ["Hide", { kind: "list-hide" }],
  ["Import", { kind: "session-abap-memory-import" }],
  ["Leave", { kind: "navigation-leave" }],
  ["LeaveScreen", { kind: "dialog-leave-screen" }],
  ["LeaveToScreen", { kind: "dialog-leave-to-screen" }],
  ["LoopAtScreen", { kind: "selection-screen-state-loop" }],
  ["Message", { kind: "session-message" }],
  ["ModifyLine", { kind: "list-modify-line" }],
  ["ModifyScreen", { kind: "selection-screen-state-mutation" }],
  ["Move", { kind: "assignment" }],
  ["NewLine", { kind: "list-new-line" }],
  ["NewPage", { kind: "list-new-page" }],
  ["Perform", { kind: "routine-call" }],
  ["Ranges", { kind: "declaration" }],
  ["ReadLine", { kind: "list-read-line" }],
  ["Reserve", { kind: "list-reserve" }],
  ["SetBlank", { kind: "list-blank-lines" }],
  ["SetCursor", { kind: "dialog-set-cursor" }],
  ["SetParameter", { kind: "compatibility-parameter-set" }],
  ["SetPFStatus", { kind: "session-status" }],
  ["SetScreen", { kind: "dialog-set-screen" }],
  ["SetTitlebar", { kind: "session-title" }],
  ["Skip", { kind: "list-skip" }],
  ["Static", { kind: "declaration" }],
  ["Stop", { kind: "terminal-stop" }],
  ["Submit", { kind: "navigation-submit" }],
  ["SuppressDialog", { kind: "dialog-suppress" }],
  ["IncludeType", { kind: "declaration" }],
  ["TypeBegin", { kind: "declaration" }],
  ["TypeEnd", { kind: "declaration" }],
  ["TypePools", { kind: "type-pool-resolution" }],
  ["Uline", { kind: "list-uline" }],
  ["Write", { kind: "list-write" }],
]);

// A data object named statically: a variable or field symbol, then components
// and attributes, as itab, ls-rows, lo->items or <fs>-lines, and for a table
// possibly its body, itab[].
function isNamedChain(chain: Nodes.ExpressionNode | undefined, tableBody: boolean): boolean {
  const children = chain?.getChildren() ?? [];
  const [head, ...rest] = children;
  if (!(head?.get() instanceof Expressions.SourceField || head?.get() instanceof Expressions.SourceFieldSymbol
      || head?.get() instanceof Expressions.TargetField || head?.get() instanceof Expressions.TargetFieldSymbol)) return false;
  if (tableBody && rest.at(-1)?.get() instanceof Expressions.TableBody) rest.pop();
  for (let index = 0; index < rest.length; index += 2) {
    const separator = rest[index].getFirstToken().getStr();
    const name = rest[index + 1]?.get();
    if (!(separator === "-" && name instanceof Expressions.ComponentName)
        && !(separator === "->" && tableBody && name instanceof Expressions.AttributeName)) return false;
  }
  return true;
}

// A LOOP whose INTO, ASSIGNING or REFERENCE INTO target, or TRANSPORTING NO
// FIELDS, follows a statically named table carries over into a method as
// written; one without reads the header line.
export function isMethodSafeLoop(statement: Statement): boolean {
  if (statement.kind !== "Loop") return false;
  const ast = statementAst(statement.text);
  const source = ast?.findDirect(Expressions.LoopSource);
  const target = ast?.findDirect(Expressions.LoopTarget);
  if (!ast || !source || !target) return false;
  const children = ast.node.getChildren();
  if (children.indexOf(target) !== children.indexOf(source) + 1) return false;
  // `itab[]` is the table body, for a table without a header line the table
  // itself, so it is a loop source as much as `itab` is.
  const chain = source.findDirectExpression(Expressions.SimpleSource2);
  if (chain?.getChildren().length !== 1 || !isNamedChain(chain.findDirectExpression(Expressions.FieldChain), true)) return false;
  const words = ast.skeleton(target);
  if (words === "TRANSPORTING NO FIELDS") return true;
  if (words === "ASSIGNING _") return true;
  if (words !== "INTO _" && words !== "REFERENCE INTO _") return false;
  // A work area may be a field symbol, or a component of one.
  const area = target.findDirectExpression(Expressions.Target);
  return Boolean(area?.findDirectExpression(Expressions.InlineData)) || isNamedChain(area, false);
}

export { assignTarget, bindsStatically, isStaticAssign };

// A global field symbol bound in one generated method and used in another
// keeps its binding in a data reference of the class, see
// fieldSymbolReferences in analyze-field-symbols.ts. A method takes the
// binding over where it starts and after each call, which may have rebound
// it. ASSIGN sets sy-subrc, which the report's own statements around it may
// still read.
export function restoreFieldSymbols(names: string[], context: LoweringContext): string {
  const lines = ["lv_ggconv_subrc = sy-subrc."];
  for (const name of names) {
    const member = keptFieldSymbolMember(name, context);
    const symbol = `<${name.toLowerCase()}>`;
    lines.push(`IF ${member} IS BOUND.`, `  ASSIGN ${member}->* TO ${symbol}.`, "ELSE.", `  UNASSIGN ${symbol}.`, "ENDIF.");
  }
  lines.push("sy-subrc = lv_ggconv_subrc.");
  return lines.join("\n");
}

function keptFieldSymbolMember(name: string, context: LoweringContext): string {
  return `${context?.ownerPrefix ?? ""}${context.fieldSymbolReferences![name].member}`;
}

// A PERFORM of a FORM that may bind or unassign the field symbol, or one whose
// FORM is not known statically; a method call where a local-class method may.
export function rebindingCall(statement: Statement, reference: Omit<FieldSymbolReference, "member">): boolean {
  if (statement.kind === "Perform") {
    const name = performedForm(statement.text);
    return !name || reference.routines.includes(name);
  }
  return ["Call", "CallMethod"].includes(statement.kind) && reference.methods;
}

// What follows a statement for the field symbols whose binding the class
// keeps: a statement binding one hands the binding back, for LOOP ...
// ASSIGNING inside the loop, so the reference follows each row; UNASSIGN
// drops it; a call that may have changed it takes it over again.
function keptFieldSymbolBindings(statement: Statement, names: string[], context: LoweringContext): string[] {
  const lines: string[] = [];
  const referenced = new Set(referencedFieldSymbols(statement.text));
  for (const name of names) {
    const symbol = `<${name.toLowerCase()}>`;
    if (statement.kind === "Unassign" && referenced.has(name)) lines.push(`CLEAR ${keptFieldSymbolMember(name, context)}.`);
    else if (bindsStatically(statement.text, name)) lines.push(`IF ${symbol} IS ASSIGNED.`, `  GET REFERENCE OF ${symbol} INTO ${keptFieldSymbolMember(name, context)}.`, "ENDIF.");
  }
  const rebound = names.filter((name) => rebindingCall(statement, context.fieldSymbolReferences![name]));
  if (rebound.length) lines.push(restoreFieldSymbols(rebound, context));
  return lines;
}

// The name WRITE (name) reads at runtime is evaluated by the generated code,
// which can do that for a variable, a component or a substring of one, and a
// literal; not for a method call, an object attribute or a table expression.
function dynamicWriteExpressionSupported(ast: StatementAst, operand: Nodes.ExpressionNode | Nodes.TokenNode | undefined): boolean {
  if (operand?.get() instanceof Expressions.Constant) return true;
  if (!(operand?.get() instanceof Expressions.FieldChain)) return false;
  return (operand as Nodes.ExpressionNode).getChildren().every((child) => {
    const type = child.get();
    // A substring has a fixed offset and length, +2(3).
    if (type instanceof Expressions.FieldOffset || type instanceof Expressions.FieldLength) return /^(?:\+\d+|\(\d+\))$/.test(ast.source(child));
    return type instanceof Expressions.SourceField || type instanceof Expressions.ComponentName
      || (child instanceof Nodes.TokenNode && ast.source(child) === "-");
  });
}

// WRITE (expression) that abaplint cannot parse, with a method call where a
// name goes: the operand between the parentheses, read from the tokens.
function unparsedDynamicWrite(raw: string): DynamicWrite | undefined {
  const tokens = lexedAst(raw)?.tokens() ?? [];
  let index = tokens[0]?.token.getUpperStr() === "WRITE" ? 1 : -1;
  if (tokens[index]?.token.getStr() === "/") index++;
  if (index < 1 || !tokens[index]?.token.getStr().startsWith("(")) return undefined;
  let depth = 0;
  for (let close = index; close < tokens.length; close++) {
    const token = tokens[close].token.getStr();
    if (token.startsWith("(") || token.endsWith("(")) depth++;
    if (token.startsWith(")")) depth--;
    if (depth === 0) {
      const start = tokens[index].end;
      const end = tokens[close].start;
      return { operand: raw.slice(start, end).trim(), supported: false, rewrite: (target) => `${raw.slice(0, tokens[index].start)}${target}${raw.slice(tokens[close].end)}` };
    }
  }
  return undefined;
}

/** WRITE ... TO, and whether the generated class can carry it over. */
export interface WriteTo {
  supported: boolean;
  dynamic: boolean;
}

// WRITE ... TO formats a value into a variable. It writes nothing to the list
// and is an ordinary statement in a class, with every formatting addition,
// UNIT and CURRENCY included. Only the obsolete WRITE ... TO itab INDEX idx and
// a source named at runtime, WRITE (name) TO, have no class equivalent.
export function writeToTarget(statement: Statement): WriteTo | undefined {
  if (statement.kind !== "Write") return undefined;
  const ast = statementAst(statement.text.trim());
  if (!ast?.hasPhrase("TO")) return undefined;
  const dynamic = Boolean(ast.findDirect(Expressions.Dynamic));
  return { supported: !dynamic && !ast.hasPhrase("INDEX"), dynamic };
}

/** WRITE (name): the operand naming the field, and the statement with another one. */
export interface DynamicWrite {
  operand: string;
  supported: boolean;
  rewrite: (target: string) => string;
}

export function dynamicWriteOperand(statement: Statement): DynamicWrite | undefined {
  if (statement.kind !== "Write" || writeToTarget(statement)) return undefined;
  const raw = statement.text.trim();
  const ast = statementAst(raw);
  if (!ast) return unparsedDynamicWrite(raw);
  const dynamic = ast.findDirect(Expressions.Dynamic);
  if (!dynamic) return undefined;
  const inner = dynamic.getChildren()[1];
  return {
    operand: ast.source(inner),
    supported: dynamicWriteExpressionSupported(ast, inner),
    rewrite: (target) => `${raw.slice(0, ast.start(dynamic))}${target}${raw.slice(ast.end(dynamic))}`,
  };
}

function lowerDynamicWriteFallback(dynamic: DynamicWrite, context: LoweringContext): string {
  const dynamicName = "lv_ggconv_dynamic_name";
  const dynamicValue = "<ggconv_dynamic_value>";
  const rewritten = dynamic.rewrite(dynamicValue);
  const formatting = statementAst(rewritten);
  const unsupportedFormatting = !formatting || Boolean(formatting.findDirect(Expressions.Color))
    || ["CURRENCY", "UNIT", "EXPONENT", "EDIT MASK"].some((phrase) => formatting.hasPhrase(phrase));
  const body = unsupportedFormatting
    ? ["* TODO GGCONV-E501: dynamic WRITE formatting requires manual lowering."]
    : parseWrite(rewritten, context).split("\n");
  return [
    "* TODO GGCONV-E501: dynamic WRITE target requires manual review; the operand is evaluated once before guarded assignment.",
    "FIELD-SYMBOLS " + dynamicValue + " TYPE any.",
    "DATA " + dynamicName + " TYPE string.",
    dynamicName + " = " + valueExpression(dynamic.operand, context) + ".",
    "ASSIGN (" + dynamicName + ") TO " + dynamicValue + ".",
    "IF " + dynamicValue + " IS ASSIGNED.",
    ...body,
    "ENDIF.",
  ].join("\n");
}

// WRITE icon AS ICON [QUICKINFO q] TO field fills the field with the icon's
// name, which a selection-screen comment shows as the icon.
export function iconWrite(text: string, quickinfo = true): { icon: string; target: string } | undefined {
  const ast = statementAst(text.trim());
  const words = ast?.words() ?? "";
  if (!ast || !(words === "WRITE _ AS ICON TO _" || (quickinfo && words === "WRITE _ AS ICON QUICKINFO _ TO _"))) return undefined;
  const name = (node: Nodes.ExpressionNode | Nodes.TokenNode | undefined) => node && /^[A-Z][A-Z0-9_]*$/i.test(ast.source(node)) ? ast.source(node) : undefined;
  const icon = name(writeValue(ast));
  const target = name(ast.after("TO", ast.node));
  return icon && target ? { icon, target } : undefined;
}

function stripPeriod(text: string): string {
  return text.trim().replace(/\.\s*$/, "");
}

function quote(value: unknown): string {
  return `'${String(value).replaceAll("'", "''")}'`;
}

function titlebarExpression(text: unknown, operands: string[], context: LoweringContext): string {
  // Template text escapes \ | { and } with a backslash.
  let result = String(text ?? "").replace(/[\\|{}]/g, "\\$&");
  for (let index = 0; index < operands.length; index++) {
    const expression = valueExpression(operands[index], context);
    result = result.replaceAll(`&${index + 1}`, `{ ${expression} }`);
  }
  return `|${result}|`;
}


// A USING parameter that its FORM writes is CHANGING in the method, which
// needs a variable. A literal, constant or text symbol argument, or one the
// class reads through an expression, goes through a temporary of the call.
function performTemporary(parameter: RoutineParameter, value: string, raw: string, context: LoweringContext): { name: string; declaration: string[] } | undefined {
  if (!parameter.written) return undefined;
  if (isWritableArgument(raw, context.constantNames) && !/\(|\bit_values\[/i.test(value)) return undefined;
  const counter = context.temporaries ?? { count: 0 };
  counter.count++;
  const name = `lv_perform_${counter.count}`;
  const type = methodParameterType(parameter);
  return {
    name,
    declaration: isGenericParameterType(type)
      ? [`DATA(${name}) = ${value}.`]
      : [`DATA ${name} TYPE ${type}.`, `${name} = ${value}.`],
  };
}

function lowerDynamicAlvFactory(raw: string, context: LoweringContext): string | undefined {
  const model = context.dynamicAlv;
  if (!model || !callsStatic(raw, "CL_ALV_TABLE_CREATE", ["CREATE_DYNAMIC_TABLE"])) return undefined;
  return [
    `GET REFERENCE OF ${model.tableMember.toLowerCase()} INTO ${model.referenceMember.toLowerCase()}.`,
    `${model.styleMember.toLowerCase()} = '${model.styleComponent}'.`,
  ].join("\n");
}

// The data clusters EXPORT and IMPORT name: `name = dobj` or a data object
// under its own name, up to TO or FROM MEMORY.
function memoryBindings(ast: StatementAst): { name: string; value: string }[] {
  const children = ast.node.getChildren();
  const bindings: { name: string; value: string }[] = [];
  for (let index = 1; index < children.length; index++) {
    const node = children[index];
    if (node instanceof Nodes.TokenNode) {
      if (["TO", "FROM"].includes(node.getFirstToken().getUpperStr())) break;
      continue;
    }
    const name = ast.source(node);
    const bound = children[index + 1]?.getFirstToken().getStr() === "=" ? children[index + 2] : undefined;
    bindings.push({ name, value: bound ? ast.source(bound) : name });
    if (bound) index += 2;
  }
  return bindings;
}

function memoryCallLines(statement: Statement, context: LoweringContext): string[] {
  const ast = statementAst(statement.text);
  const id = ast?.operand("MEMORY ID");
  if (!ast || id === undefined) return [];
  if (ast.is(Statements.FreeMemory)) return [`io_session->free_memory( iv_id = ${valueExpression(id, context)} ).`];
  if (ast.is(Statements.Export)) return memoryBindings(ast).map(({ name, value }) =>
    `io_session->export_memory( iv_id = ${valueExpression(id, context)} iv_name = ${quote(name.toUpperCase())} iv_value = ${valueExpression(value, context)} ).`);
  if (ast.is(Statements.Import)) return memoryBindings(ast).map(({ name, value }) =>
    `io_session->import_memory( EXPORTING iv_id = ${valueExpression(id, context)} iv_name = ${quote(name.toUpperCase())} CHANGING cv_value = ${valueExpression(value, context)} ).`);
  return [];
}

function continuationCall(target: string, parameter: string, value: string, id: string): string {
  const width = Math.max(parameter.length, "is_continuation".length);
  const named = (name: string, expression: string) => `${name.padEnd(width, " ")} = ${expression}`;
  return `${target}(\n  ${named(parameter, value)}\n  ${named("is_continuation", `VALUE #( id = '${id}' )`)} ).`;
}

function replaceOutsideStrings(text: string, replacements: readonly Replacement[] | undefined): string {
  return replaceIdentifiers(text, replacements);
}

// Selection events receive the number directly. FORMs and helper methods
// read the host's current selection screen from their session instead.
function selectionScreenNumber(context: LoweringContext): string {
  if (context.event?.startsWith("at_selection_screen")) return "iv_screen";
  if (context.event === "dynpro") return "io_session->get_context( )-dynpro-screen";
  return "io_session->get_context( )-selection-screen";
}

// Values a report can read that do not exist, or mean something else, in the
// generated class: system fields held by the session, the SCREEN work area of
// LOOP AT SCREEN, and the list color constants. Statements carried over as
// written get these rewrites, outside string literals; declarations and
// comments do not, since `TYPE sy-repid` must keep naming the field's type.
function dataValueRewrites(context: LoweringContext): Replacement[] {
  const screen = context.screenStateSymbol ?? "<ls_state>";
  const dynproScreen = screenStates(context).kind === "dynpro";
  return [
    ...(context.replacements ?? []),
    ...LIST_COLOR_REWRITES,
    ["sy-ucomm", context.ucomm ?? "sy-ucomm"],
    // SSCRFIELDS-UCOMM holds the selection screen's function code during PAI.
    ["sscrfields-ucomm", context.ucomm ?? "sscrfields-ucomm"],
    ["sy-subrc", context.subrc ?? "sy-subrc"],
    ["sy-dynnr", selectionScreenNumber(context)],
    // The lines a table control shows, which a dynpro module gets from the host.
    ...(context.event === "dynpro" ? [["sy-loopc", "is_context-loop_count"] as Replacement] : []),
    ["screen-name", `${screen}-name`],
    ["screen-group1", `${screen}-modif_id`],
    ["screen-group([2-4])", `${screen}-group$1`],
    ["screen-invisible", `${screen}-password`],
    ["screen-active", `${screen}-visible`],
    ["screen-required", dynproScreen ? `${screen}-required` : `${screen}-obligatory`],
    ["screen-intensified", `${screen}-intensified`],
    ["screen-(input|output)", `${screen}-$1`],
  ];
}

// The session holds these, so they become method call chains, which only an
// operand position that accepts an expression can take.
const SESSION_VALUE_REWRITES: Replacement[] = [
  ["sy-linno", "io_session->get_list( )->get_context( )-line"],
  // The line and the list an interactive event was triggered on.
  ["sy-lilli", "io_session->get_list( )->get_context( )-selected_line"],
  ["sy-listi", "io_session->get_list( )->get_context( )-list_index"],
  ["sy-pagno", "io_session->get_list( )->get_context( )-page"],
  ["sy-repid", "io_session->get_context( )-program-program"],
  ["sy-batch", "io_session->get_context( )-program-batch"],
  ["sy-lsind", "io_session->get_list( )->get_context( )-level"],
];

function rewriteValues(text: string, context: LoweringContext, { session = true } = {}): string {
  const replaced = replaceIdentifiers(text, [...dataValueRewrites(context), ...(session ? SESSION_VALUE_REWRITES : [])]);
  if (screenStates(context).kind === "dynpro") return replaced;
  // A selection screen state has no required flag; its obligatory flag is it.
  const tokens = lexedAst(replaced)?.tokens() ?? [];
  const edits = tokens.flatMap((entry, index) => {
    const [dash, component] = [tokens[index + 1], tokens[index + 2]];
    return /^<[A-Z][A-Z0-9_]*>$/i.test(entry.token.getStr()) && dash?.token.getStr() === "-" && dash.start === entry.end
      && component?.start === dash.end && component.token.getUpperStr() === "REQUIRED"
      ? [{ start: component.start, end: component.end, text: "obligatory" }] : [];
  });
  return spliceText(replaced, edits);
}

// The table LOOP AT SCREEN runs over, see screen-states.ts. Without one from
// the class emitter, the PBO method's own ct_states.
function screenStates(context: LoweringContext): ScreenStates {
  return context.screenStates ?? (context.event === "dynpro"
    ? { kind: "dynpro", table: "ct_states", row: "is_context-row" }
    : { kind: "selection", table: "ct_states" });
}

// A classic statement such as CONCATENATE takes data objects only. When a
// session value makes the statement unparseable, the system field is kept.
function rewriteStatementValues(text: string, context: LoweringContext): string {
  const rewritten = rewriteValues(text, context);
  const dataOnly = rewriteValues(text, context, { session: false });
  return rewritten === dataOnly || parsesAsStatement(rewritten) ? rewritten : dataOnly;
}

// DATA ... VALUE sy-repid: in a report sy-repid is a constant, the program's
// name; in a class it is the class's, and a start value is a literal or a
// constant. The declaration goes without VALUE and the system field is
// assigned after it, read as other statements read it. Other system fields
// are no constants, but are read the same way.
export function systemFieldStartValue(raw: string): { declaration: string; name: string; value: string } | undefined {
  const text = String(raw ?? "").trim();
  const ast = statementAst(text);
  if (!ast || !(ast.is(Statements.Data) || ast.is(Statements.Static))) return undefined;
  const definition = ast.find(Expressions.DataDefinition) ?? ast.node;
  const start = definition.findDirectExpression(Expressions.Value);
  const name = definition.findDirectExpression(Expressions.DefinitionName);
  // The start value ends the declaration.
  const value = start?.getChildren().at(-1);
  if (!start || !name || !value || start !== definition.getChildren().at(-1) || !/^sy-[A-Z]+$/i.test(ast.source(value))) return undefined;
  return { declaration: `${text.slice(0, ast.start(start)).trimEnd()}.`, name: ast.source(name), value: ast.source(value) };
}

export function startValueAssignment(start: { name: string; value: string }, context: LoweringContext): string {
  return rewriteStatementValues(`${start.name} = ${start.value}.`, context);
}

// The work area LOOP AT SCREEN INTO wa names, DATA(wa) included, becomes a
// field symbol over the states, named after it.
function screenLoopBinding(text: string, usedNames: Set<string>): { symbol: string; replacement: Replacement | undefined } {
  const ast = statementAst(text ?? "");
  const target = ast?.after("INTO", ast.node);
  const field = target instanceof Nodes.ExpressionNode ? target.findDirectExpression(Expressions.InlineData)?.findDirectExpression(Expressions.TargetField) ?? target : undefined;
  const sourceName = field && ast && /^[A-Z][A-Z0-9_]*$/i.test(ast.source(field)) ? ast.source(field) : undefined;
  const into = Boolean(sourceName);
  const base = sourceName?.toLowerCase() ?? "ls_state";
  let symbolName = base;
  let suffix = 1;
  while (usedNames.has(symbolName.toUpperCase())) symbolName = `${base}_${suffix++}`;
  usedNames.add(symbolName.toUpperCase());
  return {
    symbol: `<${symbolName}>`,
    replacement: into && sourceName ? [sourceName, `<${symbolName}>`] : undefined,
  };
}

function valueExpression(expression: string, context: LoweringContext): string {
  const value = expression.trim();
  const replacements = [...(context.replacements ?? [])];
  for (const selection of context.selections) {
    const valueSource = context.mutableValues ? "ct_values" : "it_values";
    if (!replacements.some(([name]) => name === selection.name)) {
      replacements.push([selection.name, `${valueSource}[ name = '${selection.name}' ]-${selection.ranges ? "ranges" : "value"}`]);
    }
  }
  return replaceIdentifiers(value, [
    ...replacements,
    ...LIST_COLOR_REWRITES,
    ["sy-ucomm", context.ucomm ?? "iv_ucomm"],
    ["sscrfields-ucomm", context.ucomm ?? "iv_ucomm"],
    ["sy-repid", "io_session->get_context( )-program-program"],
    ["sy-dynnr", selectionScreenNumber(context)],
    ["sy-batch", "io_session->get_context( )-program-batch"],
    ["sy-subrc", context.subrc ?? "sy-subrc"],
    ["sy-lsind", "io_session->get_list( )->get_context( )-level"],
    ["sy-linno", "io_session->get_list( )->get_context( )-line"],
    ["sy-lilli", "io_session->get_list( )->get_context( )-selected_line"],
    ["sy-listi", "io_session->get_list( )->get_context( )-list_index"],
    ["sy-pagno", "io_session->get_list( )->get_context( )-page"],
  ]);
}

function expressionText(expression: string, context: LoweringContext): string {
  const value = valueExpression(expression, context);
  if (/^'.*'$/s.test(value) || /^\|.*\|$/s.test(value)) return value;
  return `|{ ${value} }|`;
}

function catchesControlFlow(ast: StatementAst): boolean {
  return ast.findAll(Expressions.ClassName).some((name) => ["CX_ROOT", "CX_NO_CHECK"].includes(ast.source(name).toUpperCase()));
}

// SCREEN flags are 1 or 0, quoted or not, and so are COND #( WHEN c THEN 1
// ELSE 0 ) values; the state flags they map to are booleans. Required 2 draws
// the marker but leaves validation to the program. Undefined if the
// statement sets no screen flag.
const SCREEN_FLAGS = new Set(["VISIBLE", "INTENSIFIED", "INPUT", "OUTPUT", "PASSWORD", "NO_DISPLAY", "OBLIGATORY", "REQUIRED"]);

function screenFlagAssignment(converted: string): string | undefined {
  const ast = statementAst(converted);
  const target = ast?.is(Statements.Move) ? ast.findDirect(Expressions.Target) : undefined;
  const source = ast?.findDirect(Expressions.Source);
  const [symbol, dash, component] = target?.getChildren() ?? [];
  if (!ast || !source || ast.source(symbol ?? target!).toLowerCase() !== "<ls_state>" || ast.source(dash ?? symbol).trim() !== "-"
      || !SCREEN_FLAGS.has(ast.source(component ?? symbol).toUpperCase())) return undefined;
  const flag = ast.source(component);
  const value = ast.source(source);
  const one = /^['"]?[12]['"]?$/;
  const zero = /^['"]?0['"]?$/;
  if (flag.toUpperCase() === "REQUIRED" && /^'?2'?$/.test(value)) return "<ls_state>-required = abap_false.\n<ls_state>-recommended = abap_true.";
  let assignment: string | undefined;
  const body = source.findDirectExpression(Expressions.CondBody);
  if (body && ast.skeleton(body) === "WHEN _ THEN _ ELSE _" && ast.source(source).toUpperCase().startsWith("COND #(")) {
    const [, condition, , then, , otherwise] = body.getChildren().map((child) => ast.source(child));
    if (one.test(then) && zero.test(otherwise)) assignment = `<ls_state>-${flag} = xsdbool( ${condition} ).`;
    else if (zero.test(then) && one.test(otherwise)) assignment = `<ls_state>-${flag} = xsdbool( NOT ( ${condition} ) ).`;
  } else if (one.test(value)) assignment = `<ls_state>-${flag} = abap_true.`;
  else if (zero.test(value)) assignment = `<ls_state>-${flag} = abap_false.`;
  const written = assignment ?? converted;
  return flag.toUpperCase() === "REQUIRED" ? `${written}\n<ls_state>-recommended = abap_false.` : assignment;
}

function generatedLocalName(prefix: string, statement: Statement): string {
  const span: Metadata = statement.span ?? {};
  const start = span.startOffset ?? `${span.start?.line ?? span.start?.row ?? 0}:${span.start?.column ?? span.start?.col ?? 0}`;
  const value = `${statement.filename ?? ""}:${start}`;
  let hash = 2166136261;
  for (let index = 0; index < value.length; index++) {
    hash = Math.imul(hash ^ value.charCodeAt(index), 16777619);
  }
  return `${prefix}_${(hash >>> 0).toString(16).padStart(8, "0")}`;
}

function continuationId(statement: Statement, context: LoweringContext): string | undefined {
  return context.continuations?.find((item) =>
    item.filename === statement.filename &&
    item.span.start.line === statement.span.start.line &&
    item.span.start.column === statement.span.start.column,
  )?.id;
}

function hiddenFieldEntries(raw: string, context: LoweringContext): string[] {
  return hiddenFields(raw).map((expression, index) => {
    // A field or structure component is hidden under its own name.
    const identifier = /^[A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)*$/i.test(expression) ? expression.toUpperCase() : `HIDE_${index + 1}`;
    return `( name = '${identifier}' value = ${expressionText(expression, context)} )`;
  });
}

function appendHiddenFields(text: string, fields: string[]): string {
  if (!fields.length) return text;
  const suffix = " ) ).";
  const position = text.lastIndexOf(suffix);
  if (position < 0) return text;
  // A chained HIDE adds to the hide group the line already has.
  if (/\bhide = VALUE #\(/.test(text.slice(0, position)) && text.slice(position - 2, position) === " )") {
    return `${text.slice(0, position - 2)} ${fields.join(" ")}${text.slice(position - 2)}`;
  }
  return `${text.slice(0, position)} hide = VALUE #( ${fields.join(" ")} )${text.slice(position)}`;
}

function uniqueHiddenFields(fields: string[], existing: string[] = []): string[] {
  const used = new Set(existing.flatMap((item) => [...item.matchAll(/name\s*=\s*'([^']+)'/gi)].map((match) => match[1])));
  return fields.map((field) => {
    const match = /name\s*=\s*'([^']+)'/i.exec(field);
    if (!match || !match[1].startsWith("HIDE_")) return field;
    let name = match[1];
    let suffix = 1;
    while (used.has(name)) name = `HIDE_${++suffix}`;
    used.add(name);
    return field.replace(match[0], `name = '${name}'`);
  });
}

// The date masks of WRITE, as abaplint reads them: one word each.
const DATE_MASKS = new Set(["DD/MM/YY", "MM/DD/YY", "DD/MM/YYYY", "MM/DD/YYYY", "DDMMYY", "MMDDYY", "YYMMDD"]);

// [AT] [/][pos][(len)] of WRITE and ULINE, with numbers only.
function writePlacement(ast: StatementAst): { newLine: boolean; position?: number; length?: number } {
  const offset = ast.findDirect(Expressions.WriteOffsetLength);
  // WRITE / without an operand has the slash on its own.
  const result: { newLine: boolean; position?: number; length?: number } = { newLine: ast.node.getChildren().some((child) => child instanceof Nodes.TokenNode && ast.source(child) === "/") };
  const children = offset?.getChildren() ?? [];
  for (let index = 0; index < children.length; index++) {
    const text = ast.source(children[index]);
    if (text === "/") result.newLine = true;
    else if (/^\/?\d+$/.test(text)) {
      result.newLine ||= text.startsWith("/");
      result.position = Number(text.replace("/", ""));
    } else if (text === "(" && /^\d+$/.test(ast.source(children[index + 1] ?? children[index]))) {
      result.length = Number(ast.source(children[index + 1]));
      index += 2;
    }
  }
  return result;
}

// The value a WRITE writes: the operand right after WRITE and its placement.
function writeValue(ast: StatementAst): Nodes.ExpressionNode | undefined {
  const children = ast.node.getChildren();
  const first = children.findIndex((child) => child.get() instanceof Expressions.WriteOffsetLength) + 1 || 1;
  return children[first]?.get() instanceof Expressions.Source ? children[first] as Nodes.ExpressionNode : undefined;
}

function parseWrite(raw: string, context: LoweringContext): string {
  const ast = statementAst(raw.trim());
  if (!ast) return "* TODO GGCONV-E516: WRITE abaplint cannot parse requires manual lowering.";
  const { newLine, position, length } = writePlacement(ast);
  const valueNode = writeValue(ast);
  const rest = valueNode ? ast.source(valueNode) : "";
  const operand = (phrase: string) => {
    const node = ast.after(phrase, ast.node);
    return node ? ast.source(node) : undefined;
  };
  const digits = (phrase: string) => {
    const value = operand(phrase);
    return value !== undefined && /^\d+$/.test(value) ? value : undefined;
  };
  const quickinfoOperand = operand("QUICKINFO");
  const quickinfo = quickinfoOperand === undefined ? undefined : expressionText(quickinfoOperand, context);
  const kind = ["CHECKBOX", "ICON", "SYMBOL"].find((word) => ast.hasPhrase(`AS ${word}`));
  const color = ast.findDirect(Expressions.Color)?.getChildren()[1];
  const colorField = color ? LIST_COLOR_FIELDS[ast.source(color).toUpperCase() as keyof typeof LIST_COLOR_FIELDS] : undefined;
  // Field-level switches; OFF and "= flag" are rejected by unsupportedWriteFormat.
  const hotspot = ast.hasPhrase("HOTSPOT");
  const intensified = ast.hasPhrase("INTENSIFIED");
  const inverse = ast.hasPhrase("INVERSE");
  const additions = {
    noGap: ast.hasPhrase("NO-GAP"),
    currency: operand("CURRENCY"),
    unit: operand("UNIT"),
    decimals: digits("DECIMALS"),
    round: digits("ROUND"),
    noZero: ast.hasPhrase("NO-ZERO"),
    noSign: ast.hasPhrase("NO-SIGN"),
    justification: ["LEFT-JUSTIFIED", "CENTERED", "RIGHT-JUSTIFIED"].find((phrase) => ast.hasPhrase(phrase)),
    dateMask: ast.node.getChildren().map((child) => ast.source(child).toUpperCase()).find((word) => DATE_MASKS.has(word)),
  };
  // WRITE /. and WRITE: / . output nothing; they only break the line.
  if (!rest && newLine && position === undefined && length === undefined) return "lo_writer->new_line( ).";
  const placement = [];
  if (position !== undefined) placement.push(`position = ${position}`);
  if (length !== undefined) placement.push(`length = ${length}`);
  if (newLine) placement.push("new_line = abap_true");
  if (additions.noGap) placement.push("no_gap = abap_true");
  const format = [];
  if (additions.decimals !== undefined) format.push(`decimals = ${additions.decimals} decimals_set = abap_true`);
  if (additions.currency) format.push(`currency = |{ ${valueExpression(additions.currency, context)} }|`);
  if (additions.unit) format.push(`unit = |{ ${valueExpression(additions.unit, context)} }|`);
  if (additions.round) format.push(`round = ${additions.round}`);
  if (additions.noZero) format.push("no_zero = abap_true");
  if (additions.noSign) format.push("no_sign = abap_true");
  if (additions.justification) {
    const name = additions.justification === "LEFT-JUSTIFIED" ? "left" : additions.justification === "CENTERED" ? "center" : "right";
    format.push(`justification = zif_gg_list_processing_types_v1=>justify_${name}`);
  }
  const value = valueExpression(rest, context);
  const formatted = /^'(?:''|[^'])*'$|^\|.*\|$/s.test(value)
    ? expressionText(rest, context)
    : `lo_writer->format_value( iv_value = ${value}${additions.dateMask ? ` iv_date_mask = '${additions.dateMask}'` : ""} )`;
  const fields = [`text = ${formatted}`];
  const fieldFormat = [];
  if (colorField) fieldFormat.push(`color = zif_gg_list_processing_types_v1=>${colorField}`);
  if (intensified) fieldFormat.push("intensified = abap_true");
  if (inverse) fieldFormat.push("inverse = abap_true");
  if (hotspot) fieldFormat.push("hotspot = abap_true");
  if (quickinfo) fieldFormat.push(`quickinfo = ${quickinfo}`);
  if (fieldFormat.length) fields.push(`format = VALUE #( ${fieldFormat.join(" ")} )`);
  if (placement.length) fields.push(`placement = VALUE #( ${placement.join(" ")} )`);
  if (format.length) fields.push(`write_format = VALUE #( ${format.join(" ")} )`);
  const type = kind === "CHECKBOX" ? "write_checkbox" : kind === "ICON" ? "write_icon" : kind === "SYMBOL" ? "write_symbol" : "write_field";
  if (type === "write_field") return `lo_writer->${type}( VALUE #( ${fields.join(" ")} ) ).`;
  const controlValue = type === "write_checkbox"
    ? `name = 'CHECKBOX' value = ${valueExpression(rest, context)}`
    : `name = ${/^'[\s\S]*'$/.test(rest) ? rest : quote(valueExpression(rest, context).toUpperCase())}`;
  const typeFields = [controlValue];
  if (placement.length) typeFields.push(`placement = VALUE #( ${placement.join(" ")} )`);
  if (quickinfo) typeFields.push(`quickinfo = ${quickinfo}`);
  return `lo_writer->${type}( VALUE #( ${typeFields.join(" ")} ) ).`;
}

// Whether the list writer represents the WRITE's formatting: a color is one of
// the COL_ constants, and there is no EXPONENT or EDIT MASK.
export function classicWriteFormatSupported(text: string): boolean {
  const ast = statementAst(text.trim());
  if (!ast) return true;
  const color = ast.findDirect(Expressions.Color)?.getChildren()[1];
  if (color && !/^COL_[A-Z_]+$/i.test(ast.source(color))) return false;
  return !ast.hasPhrase("EXPONENT") && !ast.hasPhrase("EDIT MASK");
}

function unsupportedWriteFormat(text: string): boolean {
  const ast = statementAst(text.trim());
  // The writer can only switch these on for a field, not off against FORMAT.
  const children = ast?.node.getChildren() ?? [];
  const switchedOff = children.some((child, index) => ["HOTSPOT", "INTENSIFIED", "INVERSE"].includes(ast!.source(child).toUpperCase())
    && ["OFF", "="].includes(ast!.source(children[index + 1] ?? child).toUpperCase()));
  return switchedOff || !classicWriteFormatSupported(text);
}

function parseFormat(raw: string, context: LoweringContext): string {
  const ast = statementAst(raw);
  if (!ast) return "* TODO GGCONV-E516: FORMAT abaplint cannot parse requires manual lowering.";
  if (ast.words() === "FORMAT RESET") return "lo_writer->reset_format( ).";
  const fields: string[] = [];
  const [, color, operand] = ast.findDirect(Expressions.Color)?.getChildren() ?? [];
  const colorText = color ? ast.source(color).toUpperCase() : "";
  if (/^\d+$/.test(colorText)) fields.push(`color = ${colorText}`);
  const constant = LIST_COLOR_CONSTANTS[colorText as keyof typeof LIST_COLOR_CONSTANTS];
  if (constant) fields.push(`color = zif_gg_list_processing_types_v1=>${constant}`);
  if (colorText === "=" && operand) fields.push(`color = ${valueExpression(ast.source(operand).toUpperCase(), context)}`);
  for (const [keyword, field] of [["INTENSIFIED", "intensified"], ["INVERSE", "inverse"], ["HOTSPOT", "hotspot"], ["INPUT", "input"]]) {
    const value = ast.after(keyword, ast.node);
    const word = value ? ast.source(value).toUpperCase() : "";
    if (word === "ON" || word === "OFF") fields.push(`${field} = abap_${word === "ON" ? "true" : "false"}`);
  }
  return `lo_writer->set_format( VALUE #( BASE lo_writer->get_format( ) ${fields.join(" ")} ) ).`;
}

// A message type is a letter, quoted or not, or a dynamic operand such as
// sy-msgty.
function messageTypeExpression(token: string, context: LoweringContext): string {
  const letter = /^'?([AEISWX])'?$/i.exec(token)?.[1];
  return letter ? `zif_gg_session_types_v1=>${MESSAGE_TYPES[letter.toUpperCase() as keyof typeof MESSAGE_TYPES]}` : valueExpression(token, context);
}

// The values a MESSAGE fills its placeholders with, after WITH.
function messageOperands(ast: StatementAst): string[] {
  return ast.operandsAfter("WITH", ast.node).map((node) => ast.source(node));
}

function messageCall(fields: string[], operands: string[], displayField: string, context: LoweringContext): string {
  operands.slice(0, 4).forEach((operand, index) => fields.push("v" + (index + 1) + " = " + valueExpression(operand, context)));
  return "io_session->message( VALUE #( " + fields.join(" ") + displayField + " ) ).";
}

function parseMessage(raw: string, context: LoweringContext): string {
  const ast = statementAst(raw.trim());
  if (!ast) return "* TODO GGCONV-E516: MESSAGE abaplint cannot parse requires manual lowering.";
  const operandOf = (phrase: string, node: Nodes.StatementNode | Nodes.ExpressionNode = ast.node) => {
    const operand = ast.after(phrase, node);
    return operand ? ast.source(operand) : undefined;
  };
  const source = ast.findDirect(Expressions.MessageSource);
  // TYPE stands in the statement, or in the source of MESSAGE ID ... TYPE ... NUMBER.
  const type = operandOf("TYPE") ?? (source ? operandOf("TYPE", source) : undefined);
  // DISPLAY LIKE is an addition that sits after TYPE (or after the message
  // operands); it is never part of the emitted text.
  const displayLike = operandOf("DISPLAY LIKE");
  const displayField = displayLike ? ` display_like = ${messageTypeExpression(displayLike, context)}` : "";
  const typeExpr = messageTypeExpression(type ?? "I", context);
  const operands = messageOperands(ast);
  // MESSAGE ID mid TYPE mtype NUMBER num, where every part may be dynamic.
  if (source && ast.has("ID", source)) {
    return messageCall(["type = " + typeExpr, "id = " + valueExpression(operandOf("ID", source)!, context), "number = " + valueExpression(operandOf("NUMBER", source)!, context)], operands, displayField, context);
  }
  const first = ast.node.getChildren()[1];
  const literal = first?.get() instanceof Expressions.MessageSourceSource
    ? (first as Nodes.ExpressionNode).findDirectExpression(Expressions.Source)?.findDirectExpression(Expressions.Constant)?.findDirectExpression(Expressions.ConstantString)
    : undefined;
  if (literal && ast.source(literal).startsWith("'") && ast.node.getChildren()[2]?.getFirstToken().getUpperStr() === "TYPE") {
    return `io_session->message( VALUE #( type = ${typeExpr} text = ${ast.source(literal)}${displayField} ) ).`;
  }
  // MESSAGE e017(zmsg), or MESSAGE e017 with the class from REPORT ... MESSAGE-ID.
  // Without parentheses or TYPE, the operand cannot be a text field.
  const numbered = source?.findDirectExpression(Expressions.MessageTypeAndNumber);
  const reference = numbered ? /^([AEISWX])(\d{3})$/i.exec(ast.source(numbered)) : undefined;
  const messageClass = source?.findDirectExpression(Expressions.MessageClass);
  if (source && reference && (messageClass || !type)) {
    const id = messageClass ? ast.source(messageClass) : context.messageId;
    if (!id) return `* TODO GGCONV-E501: MESSAGE ${ast.source(source)} names no message class and the program declares no MESSAGE-ID.`;
    return messageCall([
      "type = zif_gg_session_types_v1=>" + MESSAGE_TYPES[reference[1].toUpperCase() as keyof typeof MESSAGE_TYPES],
      "id = '" + id.toUpperCase() + "'",
      "number = '" + reference[2] + "'",
    ], operands, displayField, context);
  }
  // MESSAGE zmsg(017), which abaplint reads as a substring of zmsg.
  const chain = first?.get() instanceof Expressions.MessageSourceSource
    ? (first as Nodes.ExpressionNode).findDirectExpression(Expressions.Source)?.findDirectExpression(Expressions.FieldChain) : undefined;
  const [head, length] = chain?.getChildren() ?? [];
  const number = length?.get() instanceof Expressions.FieldLength && chain?.getChildren().length === 2 ? /^\((\d+)\)$/.exec(ast.source(length)) : undefined;
  if (head && number) {
    return messageCall(["type = " + typeExpr, "id = '" + ast.source(head).toUpperCase() + "'", "number = '" + number[1].padStart(3, "0") + "'"], operands, displayField, context);
  }
  const value = valueExpression(first ? ast.source(first) : "", context);
  if (/^'.*'$/s.test(value) || /^\|.*\|$/s.test(value) || /^`.*`$/s.test(value)) {
    return `io_session->message( VALUE #( type = ${typeExpr} text = ${value}${displayField} ) ).`;
  }
  // `MESSAGE oref TYPE ...` and `MESSAGE text TYPE ...` look the same here: the
  // operand may be an exception object, whose text a string template cannot
  // produce, so the session inspects it at runtime.
  return [
    "io_session->message(",
    `  is_message = VALUE #( type = ${typeExpr}${displayField} )`,
    `  ia_text    = ${value} ).`,
  ].join("\n");
}

// A static event handler of a local class cannot receive io_owner and
// io_session, so registering it stores both in the helper class first.
// Handlers are named `class=>method`, or just `method` inside their own class.
function staticHandlerBindings(raw: string, context: LoweringContext): string[] {
  const ast = statementAst(raw);
  const classes = new Set<string>();
  for (const handler of ast?.is(Statements.SetHandler) ? ast.node.findDirectExpressions(Expressions.MethodSource) : []) {
    const qualified = handler.findDirectExpression(Expressions.ClassName);
    const method = qualified ? handler.findDirectExpression(Expressions.AttributeName) : handler.findDirectExpression(Expressions.SourceField);
    if (!method || handler.getChildren().length !== (qualified ? 3 : 1)) continue;
    const className = (qualified ? ast!.source(qualified) : context.localClassName ?? "").toUpperCase();
    if (context.localClassStaticEventHandlers?.[className]?.has(ast!.source(method).toUpperCase())) classes.add(className);
  }
  const owner = context.localClassOwner ?? "me";
  const session = context.sessionVariable ?? "io_session";
  return [...classes].flatMap((className) => {
    // Inside the helper class itself its static attributes need no class name.
    const prefix = className === (context.localClassName ?? "").toUpperCase()
      ? ""
      : `${context.localClassRenames?.[className] ?? className.toLowerCase()}=>`;
    return [`${prefix}go_owner = ${owner}.`, `${prefix}go_session = ${session}.`];
  });
}

// Whether a parameter list, or the EXPORTING of one, names a parameter.
function namesParameter(ast: StatementAst, list: Nodes.ExpressionNode | undefined, name: string): boolean {
  const lists = list?.get() instanceof Expressions.ParameterListS ? [list] : list?.findDirectExpressions(Expressions.ParameterListS) ?? [];
  return lists.some((item) => item.findDirectExpressions(Expressions.ParameterS)
    .some((parameter) => ast.source(parameter.findDirectExpression(Expressions.ParameterName)!).toUpperCase() === name));
}

// A static method of a local class takes the owner and the session, see
// withImportingParameters in emit/class-source.ts, so every call passes them:
// as a statement, in an expression, nested in other arguments, and as
// CALL METHOD without parentheses. Inside its own class the method may be
// called without the class name. A single unnamed argument gets the name of
// the method's first IMPORTING parameter, as it is no longer the only one.
function bridgeLocalStaticCalls(statement: Statement, context: LoweringContext): Statement {
  const statics = context.localClassStaticMethods ?? {};
  const owner = context.localClassOwner;
  if (!owner || !Object.values(statics).some((methods) => methods.size) || typeof statement.text !== "string") return statement;
  const session = context.sessionVariable ?? "io_session";
  const bridge = `io_owner = ${owner} io_session = ${session}`;
  const own = context.localClassName?.toUpperCase();
  const target = (className: string | undefined, method: string) => {
    const name = (className ?? own ?? "").toUpperCase();
    return statics[name]?.has(method.toUpperCase()) ? name : undefined;
  };
  // The calls with parentheses, the last one first: each rewrite parses the
  // text again, so a call takes the arguments its nested calls were given.
  let text = statement.text;
  for (let ast = statementAst(text); ast; ast = statementAst(text)) {
    const tokens = ast.tokens();
    const calls = ast.findEvery(Expressions.MethodCallParam).flatMap((parameter) => {
      const at = tokens.findIndex((entry) => entry.start === ast!.start(parameter));
      const method = tokens[at - 1];
      if (!method || method.end !== tokens[at].start || !(method.node instanceof Nodes.TokenNodeRegex)) return [];
      // class=>method( ), or method( ) of the own class; not object->method( ).
      const arrow = tokens[at - 2]?.token.getStr();
      const qualified = arrow === "=>" ? tokens[at - 3]?.token.getStr() : undefined;
      if (arrow === "=>" ? !qualified : ["->", "-", "~"].includes(arrow ?? "")) return [];
      const className = target(qualified, method.token.getStr());
      const [, content] = parameter.getChildren();
      const list = content instanceof Nodes.ExpressionNode ? content : undefined;
      return className && !namesParameter(ast!, list, "IO_OWNER") ? [{ parameter, list, className, method: method.token.getStr() }] : [];
    });
    const call = calls.sort((left, right) => ast!.start(left.parameter) - ast!.start(right.parameter)).at(-1);
    if (!call) break;
    const opening = ast.start(call.parameter);
    const closing = ast.offset(call.parameter.getLastToken());
    const argumentsText = text.slice(opening + 1, closing).trim();
    const keyword = call.list?.get() instanceof Expressions.MethodParameters ? call.list.getFirstToken() : undefined;
    let bridged: string;
    if (keyword?.getUpperStr() === "EXPORTING") {
      const at = ast.offset(keyword) + keyword.getStr().length;
      text = `${text.slice(0, at)} ${bridge}${text.slice(at)}`;
      continue;
    } else if (keyword) {
      bridged = `EXPORTING ${bridge} ${argumentsText}`;
    } else if (!argumentsText) {
      bridged = bridge;
    } else {
      const parameter = context.localClassStaticParameters?.[call.className]?.[call.method.toUpperCase()];
      bridged = parameter && call.list?.get() instanceof Expressions.Source
        ? `${bridge} ${parameter.toLowerCase()} = ${argumentsText}`
        : `${bridge} ${argumentsText}`;
    }
    text = `${text.slice(0, opening + 1)} ${bridged} ${text.slice(closing)}`;
  }
  // CALL METHOD class=>method, without parentheses.
  const ast = statementAst(text);
  const source = ast?.is(Statements.Call) ? ast.findDirect(Expressions.MethodSource) : undefined;
  const qualified = source?.findDirectExpression(Expressions.ClassName);
  const method = qualified ? source!.findDirectExpression(Expressions.AttributeName) : source?.findDirectExpression(Expressions.SourceField);
  const body = ast?.findDirect(Expressions.MethodCallBody);
  if (ast && source && method && source.getChildren().length === (qualified ? 3 : 1) && !body?.findDirectExpression(Expressions.MethodCallParam)
      && target(qualified ? ast.source(qualified) : undefined, ast.source(method))
      && !ast.findEvery(Expressions.ParameterName).some((name) => ast.source(name).toUpperCase() === "IO_OWNER")) {
    const exporting = body?.findDirectExpression(Expressions.MethodParameters)?.getFirstToken();
    text = exporting?.getUpperStr() === "EXPORTING"
      ? `${text.slice(0, ast.offset(exporting) + exporting.getStr().length)} ${bridge}${text.slice(ast.offset(exporting) + exporting.getStr().length)}`
      : `${text.slice(0, ast.end(source))} EXPORTING ${bridge}${text.slice(ast.end(source))}`;
  }
  return text === statement.text ? statement : { ...statement, text };
}

// A local class becomes a helper class whose constructor takes the owner and
// the session, so NEW lcl( ... ) passes them like CREATE OBJECT does. A single
// unnamed constructor argument would need the parameter name and is left as is.
function bridgeLocalConstructors(statement: Statement, context: LoweringContext): Statement {
  const localClasses = new Set(Object.keys(context.localClassRenames ?? {}).map((name) => name.toUpperCase()));
  const ast = localClasses.size ? statementAst(statement.text) : undefined;
  if (!ast) return statement;
  const owner = context.localClassOwner ?? "me";
  const session = context.sessionVariable ?? "io_session";
  const edits: { start: number; end: number; text: string }[] = [];
  // The arguments of NEW type( ... ): none, or named ones.
  const bridgeable = (node: Nodes.ExpressionNode) => {
    const [, type, open, content] = node.getChildren();
    const unnamed = content instanceof Nodes.ExpressionNode && !(content.get() instanceof Expressions.ParameterListS);
    return type && open?.getFirstToken().getStr() === "(" && !unnamed ? { type, next: content } : undefined;
  };
  for (const node of ast.findEvery(Expressions.NewObject)) {
    const parts = bridgeable(node);
    if (!parts || !localClasses.has(ast.source(parts.type).toUpperCase())) continue;
    edits.push({ start: ast.start(node), end: ast.start(parts.next), text: `NEW ${ast.source(parts.type)}( io_owner = ${owner} io_session = ${session} ` });
  }
  // variable = NEW #( ... ) for a variable typed with a local class.
  const target = ast.is(Statements.Move) ? ast.findDirect(Expressions.Target) : undefined;
  const created = ast.findDirect(Expressions.Source)?.getChildren();
  const inferred = created?.length === 1 && created[0].get() instanceof Expressions.MethodCallChain
    ? (created[0] as Nodes.ExpressionNode).findDirectExpression(Expressions.NewObject) : undefined;
  const parts = inferred && (created![0] as Nodes.ExpressionNode).getChildren().length === 1 ? bridgeable(inferred) : undefined;
  if (target && parts && ast.source(parts.type) === "#" && /^[A-Z][A-Z0-9_]*$/i.test(ast.source(target))
      && context.controlObjectTypes?.[ast.source(target).toUpperCase()]?.startsWith("LOCAL:")) {
    edits.push({ start: ast.start(parts.next), end: ast.start(parts.next), text: `io_owner = ${owner} io_session = ${session} ` });
  }
  const text = spliceText(statement.text, edits);
  return text === statement.text ? statement : { ...statement, text };
}

export function lowerStatement(original: Statement, context: LoweringContext): string | undefined {
  const statement = bridgeLocalStaticCalls(bridgeLocalConstructors(original, context), context);
  const lowered = lowerSingleStatement(statement, context);
  if (statement.kind !== "SetHandler" || typeof lowered !== "string") return lowered;
  const bindings = staticHandlerBindings(statement.text.trim(), context);
  return bindings.length ? [...bindings, lowered].join("\n") : lowered;
}

// The text of a literal, 'text', without its quotes; undefined for anything else.
function literalText(operand: string | undefined): string | undefined {
  return operand !== undefined && /^'(?:''|[^'])*'$/.test(operand) ? operand.slice(1, -1) : undefined;
}

function digitsOf(operand: string | undefined): string | undefined {
  return operand !== undefined && /^\d+$/.test(operand) ? operand : undefined;
}

// The value a CALL FUNCTION passes for a parameter, as written.
function functionArgument(ast: StatementAst, name: string): string | undefined {
  const parameter = [...ast.findAll(Expressions.ParameterS), ...ast.findAll(Expressions.ParameterT)]
    .find((node) => ast.source(node.findDirectExpression(Expressions.ParameterName)!).toUpperCase() === name);
  const value = parameter?.getChildren().at(-1);
  return value ? ast.source(value) : undefined;
}

function lowerSingleStatement(statement: Statement, context: LoweringContext): string | undefined {
  const raw = statement.text.trim();
  const ast = statementAst(raw);
  const operand = (phrase: string) => ast?.operand(phrase);
  const dynamicAlvFactory = lowerDynamicAlvFactory(raw, context);
  if (dynamicAlvFactory) return dynamicAlvFactory;
  if (statement.kind === "Comment") return raw;
  const convertibleFreeChain = statement.kind === "Free"
    && context.freeChainControlKeys?.has(freeChainKey(statement)!);
  if (isConvertibleControlStatement(statement, context.controlObjectTypes) || convertibleFreeChain) {
    // A chain element, such as one handler of SET HANDLER: a FOR x, b FOR x.,
    // ends in its comma; emitted on its own, that becomes its terminator.
    let lowered = statement.kind === "Free"
      ? `CLEAR: ${lexedAst(raw)?.body() ?? ""}.`
      : raw.replace(/,\s*$/, ".");
    if (statement.kind === "CreateObject" && ast) {
      const created = createdObject(ast);
      const target = created.target?.toUpperCase();
      const explicitType = created.explicitType?.toUpperCase();
      const resolvedTargetType = target && String(context.controlObjectTypes?.[target] ?? "").toUpperCase();
      const resolvedExplicitType = explicitType
        && Object.values(context.controlObjectTypes ?? {}).some((value) => String(value).toUpperCase() === `LOCAL:${explicitType}`)
        ? `LOCAL:${explicitType}`
        : "";
      const objectType = resolvedExplicitType || resolvedTargetType;
      // In a helper class the target becomes io_owner->target; the open-abap
      // transpiler would create the owner's class for it, so the declared
      // class is named.
      if (context.localClassName && !explicitType && resolvedTargetType && !resolvedTargetType.startsWith("LOCAL:")) {
        const end = ast.end(created.targetToken!);
        lowered = `${lowered.slice(0, end)} TYPE ${resolvedTargetType.toLowerCase()}${lowered.slice(end)}`;
      }
      if (objectType?.startsWith("LOCAL:") && context.localClassOwner) {
        const owner = context.localClassOwner;
        const session = context.sessionVariable ?? "io_session";
        const constructor = `io_owner = ${owner} io_session = ${session}`;
        const exporting = ast.node.getChildren().find((child) => child instanceof Nodes.TokenNode && isKeyword(child)
          && child.getFirstToken().getUpperStr() === "EXPORTING");
        // The TYPE added above shifts what follows the target.
        const shift = lowered.length - raw.replace(/,\s*$/, ".").length;
        lowered = exporting
          ? `${lowered.slice(0, ast.end(exporting) + shift)} ${constructor}${lowered.slice(ast.end(exporting) + shift)}`
          : `${lowered.replace(/\.\s*$/, "")} EXPORTING ${constructor}.`;
      }
    }
    if (context.dynamicAlv && ast?.tokens().slice(0, 3).map((entry) => entry.token.getUpperStr()).join(" ") === "GO_GRID -> REFRESH_TABLE_DISPLAY") {
      return "go_grid->set_table_for_first_display( CHANGING it_outtab = gt_output it_fieldcatalog = gt_fieldcat ).";
    }
    if ((statement.kind === "Call" || statement.kind === "CallMethod") && ast) lowered = integerModeCall(ast, lowered);
    return wrapPopup(statement, context, rewriteStatementValues(lowered, context));
  }
  if (statement.kind === "Write") {
    const iconAssignment = iconWrite(raw);
    if (iconAssignment) return `${iconAssignment.target.toLowerCase()} = '@ICON:${iconAssignment.icon.toLowerCase().replace(/^icon_/, "")}'.`;
    const writeTo = writeToTarget(statement);
    if (writeTo) {
      if (!writeTo.supported) return `* TODO GGCONV-E516: ${writeTo.dynamic ? "WRITE (name) TO names its source at runtime" : "WRITE ... TO itab INDEX is obsolete"} and requires manual lowering.`;
      return rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
    }
    const dynamic = dynamicWriteOperand(statement);
    if (dynamic) {
      const targets = context.dynamicWriteTargets ?? [];
      if (!dynamic.supported || targets.length === 0) return lowerDynamicWriteFallback(dynamic, context);
      const target = valueExpression(dynamic.operand, context);
      const cases = targets.flatMap(({ name, expression }) => [
        `WHEN '${name}'.`,
        parseWrite(dynamic.rewrite(expression), context),
      ]);
      return [`CASE ${target}.`, ...cases, "WHEN OTHERS.", "RETURN.", "ENDCASE."].join("\n");
    }
    if (unsupportedWriteFormat(raw)) {
      return "* TODO GGCONV-E501: unsupported WRITE formatting addition requires manual lowering.";
    }
    return parseWrite(raw, context);
  }
  if (statement.kind === "Format") return parseFormat(raw, context);
  if (statement.kind === "Skip") return `lo_writer->skip( ${ast?.sourceOf(Expressions.Source) ?? "1"} ).`;
  if (statement.kind === "Uline") {
    // ULINE [AT] [/][pos][(len)]; the writer starts a new line and leaves
    // the list cursor at the start of the next one.
    const { position, length } = ast ? writePlacement(ast) : { position: undefined, length: undefined };
    const placement = [
      position !== undefined ? `position = ${position}` : "",
      length !== undefined ? `length = ${length}` : "",
    ].filter(Boolean).join(" ");
    return placement ? `lo_writer->uline( VALUE #( ${placement} ) ).` : "lo_writer->uline( VALUE #( ) ).";
  }
  if (statement.kind === "NewLine") return "lo_writer->new_line( ).";
  if (statement.kind === "Reserve") return "lo_writer->reserve( " + (ast?.sourceOf(Expressions.Source) ?? "") + " ).";
  if (statement.kind === "SetBlank") return `lo_writer->set_blank_lines( ${ast?.hasPhrase("ON") ? "abap_true" : "abap_false"} ).`;
  if (statement.kind === "NewPage") {
    const fields: string[] = [];
    if (ast?.hasPhrase("NO-TITLE")) fields.push("no_title = abap_true");
    if (ast?.hasPhrase("NO-HEADING")) fields.push("no_heading = abap_true");
    const lineSize = digitsOf(operand("LINE-SIZE"));
    if (lineSize) fields.push(`line_size = ${lineSize}`);
    return `lo_writer->new_page( VALUE #( ${fields.join(" ")} ) ).`;
  }
  if (statement.kind === "ScrollList") {
    if (ast?.hasPhrase("TO FIRST PAGE")) return "lo_writer->scroll_to_first_page( ).";
    if (ast?.hasPhrase("TO LAST PAGE")) return "lo_writer->scroll_to_last_page( ).";
    return "* TODO GGCONV-E516: unsupported SCROLL LIST target requires manual lowering.";
  }
  if (statement.kind === "Stop") return "io_session->stop( ).";
  if (statement.kind === "Message") {
    // MESSAGE ... INTO sends nothing; it only fills the target and sy-msg*,
    // which is valid in a class method, so it is carried over as written.
    const ast = statementAst(raw);
    if (ast?.hasPhrase("INTO")) {
      // The generated class has no MESSAGE-ID, so a short form names it.
      const source = ast.findDirect(Expressions.MessageSource);
      const numbered = source?.findDirectExpression(Expressions.MessageTypeAndNumber);
      const named = context.messageId && numbered && !source!.findDirectExpression(Expressions.MessageClass)
        && /^[AEISWX]\d{3}$/i.test(ast.source(numbered))
        ? `${raw.slice(0, ast.end(numbered))}(${context.messageId.toLowerCase()})${raw.slice(ast.end(numbered))}`
        : raw;
      return rewriteStatementValues(named.replace(/,\s*$/, "."), context);
    }
    // A message in AT SELECTION-SCREEN ON <field> belongs to that field, which
    // gets the cursor.
    const message = parseMessage(raw, context);
    return context.messageField && message.startsWith("io_session->message( VALUE #(")
      ? message.replace(/ \) \)\.$/, ` field = ${context.messageField} ) ).`)
      : message;
  }
  if (statement.kind === "FieldSymbol") {
    const name = fieldSymbolsIn(raw)[0];
    // Like DATA, a chain arrives one element per statement with its comma.
    return name && context.safeFieldSymbols?.includes(name) ? replaceOutsideStrings(raw.replace(/,\s*$/, "."), context.replacements) : undefined;
  }
  if (statement.kind === "Ranges") {
    const declared = ast?.hasPhrase("FOR") ? ast.sourceOf(Expressions.DefinitionName) : undefined;
    if (!declared) return undefined;
    const name = declared.toLowerCase();
    const type = context.rangeDeclarations?.[declared.toUpperCase()] ?? "TYPE RANGE OF string";
    // RANGES has a header line, see header-lines.ts.
    const header = context.headerLines?.[declared.toUpperCase()];
    return [`DATA ${name} ${type}.`, ...(header ? [`DATA ${header} LIKE LINE OF ${name}.`] : [])].join("\n");
  }
  // A static ASSIGN is carried over like any other statement. Whether its
  // target has a declaration is settled in lowerStatements, as for every use.
  if (statement.kind === "Assign" && !isStaticAssign(raw)) return undefined;
  if (statement.kind === "SetPFStatus") {
    const status = ast?.sourceOf(Expressions.Source);
    const name = status === undefined ? undefined : literalText(status) ?? status;
    if (!name) return "* TODO GGCONV-E501: dynamic PF-STATUS.";
    const statusMetadata = context.guiStatusMetadata?.[name.toUpperCase()] ?? context.guiStatusMetadata?.[name] ?? {};
    // EXCLUDING a function code, or a table of them.
    const excluding = operand("EXCLUDING");
    const dynamicExcluding = excluding !== undefined && /^[A-Z][A-Z0-9_]*$/i.test(excluding);
    const excludedCode = excluding !== undefined && !dynamicExcluding ? literalText(excluding) ?? excluding : undefined;
    const excluded = [...new Set([
      ...(excludedCode ? [excludedCode.toUpperCase()] : []),
      ...(statusMetadata.excludedUcomm ?? statusMetadata.excluded_ucomm ?? []).map((command: unknown) => String(command).toUpperCase()),
    ])];
    const active = [...new Set((statusMetadata.activeUcomm ?? statusMetadata.active_ucomm ?? context.activeCommands ?? []).map((command: unknown) => String(command).toUpperCase()))];
    const fields = [`status = '${name.toUpperCase()}'`];
    if (active.length) fields.push(`active_ucomm = VALUE #( ${active.map((command) => `( '${command}' )`).join(" ")} )`);
    if (excluded.length) fields.push(`excluded_ucomm = VALUE #( ${excluded.map((command) => `( '${command}' )`).join(" ")} )`);
    const activePFKeys = statusMetadata.activePFKeys ?? statusMetadata.active_pf_keys ?? context.activePFKeys ?? [];
    if (activePFKeys.length) fields.push(`active_pf_keys = VALUE #( ${[...new Set(activePFKeys)].map((key) => `( ${Number(key)} )`).join(" ")} )`);
    const exitUcomm = statusMetadata.exitUcomm ?? [];
    if (exitUcomm.length) fields.push(`exit_ucomm = VALUE #( ${exitUcomm.map((command: unknown) => `( '${String(command).toUpperCase()}' )`).join(" ")} )`);
    const iconBar = statusMetadata.iconBar ?? statusMetadata.icon_bar ?? [];
    if (iconBar.length) fields.push(`icon_bar = VALUE #( ${iconBar.map((item: Metadata) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' label = ${textLiteral(String(item.label ?? ""))} icon = ${quote(String(item.icon ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} )`);
    if (statusMetadata.pfActions?.length || statusMetadata.pf_actions?.length) {
      const actions = statusMetadata.pfActions ?? statusMetadata.pf_actions;
      fields.push(`pf_actions = VALUE #( ${actions.map((item: Metadata) => `( number = ${Number(item.number ?? item.functionKey)} ucomm = '${String(item.ucomm ?? item.functionCode ?? "").toUpperCase()}' )`).join(" ")} )`);
    }
    if (statusMetadata.menus?.length) {
      fields.push(`menus = VALUE #( ${statusMetadata.menus.map((menu: Metadata) => `( code = ${quote(String(menu.code ?? ""))} text = ${quote(String(menu.text ?? ""))} path = ${quote(String(menu.path ?? ""))} items = VALUE #( ${(
        menu.items ?? []
      ).map((item: Metadata) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' text = ${quote(String(item.text ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} ) )`).join(" ")} )`);
    }
    const target = context.event === "dynpro" ? "io_session->get_dialog( )" : "io_session->get_list( )";
    const body = `${target}->set_status( VALUE #( ${fields.join(" ")}${dynamicExcluding ? " excluded_ucomm = lt_ggconv_excluded" : ""} ) ).`;
    if (!dynamicExcluding) return body;
    const variable = replaceOutsideStrings(excluding!, context.replacements);
    return [
      "DATA lt_ggconv_excluded TYPE zif_gg_session_types_v1=>ty_ucomms.",
      "CLEAR lt_ggconv_excluded.",
      `LOOP AT ${variable} INTO DATA(lv_ggconv_excluded).`,
      // A move converts any character-like line, without a CONV that is
      // redundant for the usual table of sy-ucomm.
      "  APPEND INITIAL LINE TO lt_ggconv_excluded ASSIGNING FIELD-SYMBOL(<lv_ggconv_excluded>).",
      "  <lv_ggconv_excluded> = lv_ggconv_excluded.",
      "ENDLOOP.",
      body,
    ].join("\n");
  }
  if (statement.kind === "Move" && ast?.sourceOf(Expressions.Target)?.toUpperCase() === "SY-LSIND") {
    return `io_session->get_list( )->set_level( iv_level = ${valueExpression(ast.sourceOf(Expressions.Source)!, context)} ).`;
  }
  // A LOOP with an INTO or ASSIGNING target is carried over as written. One
  // without reads a header line, which a class cannot have: a header-line
  // table's loop already got its work area in headerLineStatement, otherwise
  // it is omitted.
  if (statement.kind === "Loop" && !isMethodSafeLoop(statement)) return undefined;
  if (statement.kind === "SetTitlebar") {
    const titleOperand = ast?.sourceOf(Expressions.Source);
    const title = titleOperand === undefined ? undefined : literalText(titleOperand) ?? titleOperand;
    if (!title) return "* TODO GGCONV-E501: dynamic titlebar.";
    const metadata = context.titlebarMetadata?.[title.toUpperCase()] ?? context.titlebarMetadata?.[title];
    const operands = ast ? ast.operandsAfter("WITH", ast.node).map((node) => ast.source(node)) : [];
    const value = metadata?.text
      ? (operands.length ? titlebarExpression(metadata.text, operands, context) : textLiteral(metadata.text))
      : quote(title.toUpperCase());
    const target = context.event === "dynpro" ? "io_session->get_dialog( )" : "io_session->get_list( )";
    return `${target}->set_title( ${value} ).`;
  }
  if (statement.kind === "CallSelectionScreen") {
    const screen = digitsOf(ast?.sourceOf(Expressions.Source));
    if (!ast || !screen) return undefined;
    const fields = [`screen = '${screen.padStart(4, "0")}'`];
    const modal = ast.operandsAfter("STARTING AT", ast.node).map((node) => digitsOf(ast.source(node)));
    if (modal[0] && modal[1]) fields.push(`modal = VALUE #( start_row = ${modal[0]} start_column = ${modal[1]} )`);
    const id = continuationId(statement, context);
    if (!id) return undefined;
    return continuationCall("io_session->get_dialog( )->call_selection_screen", "is_call", `VALUE #( ${fields.join(" ")} )`, id);
  }
  if (statement.kind === "CallScreen") {
    const screen = digitsOf(ast?.sourceOf(Expressions.Source));
    if (!ast || !screen) return undefined;
    const fields = [`screen = '${screen.padStart(4, "0")}'`];
    const start = ast.operandsAfter("STARTING AT", ast.node).map((node) => digitsOf(ast.source(node)));
    const end = ast.operandsAfter("ENDING AT", ast.node).map((node) => digitsOf(ast.source(node)));
    if (start[0] && start[1]) fields.push(`modal = VALUE #( start_row = ${start[0]} start_column = ${start[1]}${end[0] && end[1] ? ` end_row = ${end[0]} end_column = ${end[1]}` : ""} )`);
    const id = continuationId(statement, context);
    if (!id) return undefined;
    return continuationCall("io_session->get_dialog( )->call_screen", "is_call", `VALUE #( ${fields.join(" ")} )`, id);
  }
  if (statement.kind === "Submit") {
    const children = ast?.node.getChildren() ?? [];
    const program = children[1] && ast ? ast.source(children[1]).toUpperCase() : undefined;
    if (!ast || !program) return undefined;
    const fields = [`program = '${program}'`];
    const variant = operand("USING SELECTION-SET");
    const name = (value: string | undefined) => value !== undefined && /^[A-Z][A-Z0-9_]*$/i.test(value) ? value : undefined;
    if (literalText(variant)) fields.push(`variant = '${literalText(variant)!.toUpperCase()}'`);
    else if (name(variant)) fields.push(`variant = ${valueExpression(variant!, context)}`);
    if (ast.hasPhrase("EXPORTING LIST TO MEMORY")) fields.push("list_to_memory = abap_true");
    const selectionTable = name(operand("WITH SELECTION-TABLE"));
    if (selectionTable) {
      fields.push(`values = io_session->get_compatibility( )->selection_table_to_values( ${valueExpression(selectionTable, context)} )`);
    }
    if (ast.hasPhrase("VIA SELECTION-SCREEN")) fields.push("via_selection_screen = abap_true");
    // WITH s_x IN VALUE #( ... ), as the last selection before AND RETURN.
    const last = children.filter((child) => !(child.get() instanceof Expressions.AndReturn) && !/^[.,]$/.test(ast.source(child))).slice(-4);
    if (last.length === 4 && ast.source(last[0]).toUpperCase() === "WITH" && last[1].get() instanceof Expressions.FieldSub
        && ast.source(last[2]).toUpperCase() === "IN" && /^VALUE\s+#\(/i.test(ast.source(last[3]))) {
      fields.push(`values = VALUE #( ( name = '${ast.source(last[1]).toUpperCase()}' ranges = ${ast.source(last[3])} ) )`);
    }
    const id = continuationId(statement, context);
    if (ast.findDirect(Expressions.AndReturn)) {
      if (!id) return undefined;
      return continuationCall("io_session->get_navigation( )->submit_and_return", "is_submit", `VALUE #( ${fields.join(" ")} )`, id);
    }
    return `io_session->get_navigation( )->submit( VALUE #( ${fields.join(" ")} ) ).`;
  }
  if (statement.kind === "CallTransaction") {
    // The transaction, a literal or a data object.
    const transaction = ast?.sourceOf(Expressions.Source);
    const valid = transaction !== undefined && (literalText(transaction) !== undefined || /^[A-Z][A-Z0-9_]*(?:(?:-|->|=>)[A-Z][A-Z0-9_]*)*$/i.test(transaction));
    const id = continuationId(statement, context);
    if (!ast || !valid || !id) return undefined;
    // A batch-input table drives the called transaction's screens, which the
    // host cannot replay; the call is reported rather than run without it.
    if (ast.hasPhrase("USING")) return "* TODO GGCONV-E516: CALL TRANSACTION ... USING batch-input data requires manual lowering.";
    const tcode = literalText(transaction);
    const target = tcode === undefined ? `CONV #( ${valueExpression(transaction!, context)} )` : `'${tcode.toUpperCase()}'`;
    return continuationCall("io_session->get_navigation( )->call_transaction", "is_call", `VALUE #( tcode = ${target}${ast.hasPhrase("SKIP FIRST SCREEN") ? " skip_first_screen = abap_true" : ""} )`, id);
  }
  if (statement.kind === "SuppressDialog") {
    return "io_session->get_dialog( )->suppress_dialog( ).";
  }
  if (statement.kind === "SetParameter") {
    const id = literalText(operand("ID"));
    const field = operand("FIELD");
    if (!id || field === undefined) return undefined;
    return `io_session->get_compatibility( )->set_parameter( iv_id = ${quote(id.toUpperCase())} iv_value = CONV string( ${valueExpression(field, context)} ) ).`;
  }
  if (statement.kind === "GetParameter") {
    const id = literalText(operand("ID"));
    const field = operand("FIELD");
    if (!id || field === undefined) return undefined;
    return `${replaceOutsideStrings(field, context.replacements)} = CONV #( io_session->get_compatibility( )->get_parameter( iv_id = ${quote(id.toUpperCase())} ) ).`;
  }
  if (statement.kind === "AuthorityCheck" && ast) {
    // Each ID ... FIELD is checked; ID ... DUMMY checks nothing.
    const object = literalText(operand("OBJECT"));
    const children = ast.node.getChildren();
    const fields = children.flatMap((child, index) => child instanceof Nodes.TokenNode && isKeyword(child) && child.getFirstToken().getUpperStr() === "ID"
      ? [{ id: literalText(ast.source(children[index + 1])), field: children[index + 2]?.getFirstToken().getUpperStr() === "FIELD" ? ast.source(children[index + 3]) : undefined }]
      : []);
    const checked = fields.filter((item) => item.field !== undefined);
    if (!object || !checked.length || fields.some((item) => !item.id)) return undefined;
    const checks = checked.map(({ id, field }) =>
      `io_session->get_compatibility( )->authority_check( iv_object = ${quote(object.toUpperCase())} iv_id = ${quote(id!.toUpperCase())} iv_value = CONV string( ${valueExpression(field!, context)} ) ) = abap_true`);
    return `sy-subrc = COND #( WHEN ${checks.join(" AND ")} THEN 0 ELSE 4 ).`;
  }
  if (statement.kind === "CallFunction") {
    const functionName = functionModule(raw);
    // The table the first TABLES parameter passes.
    const tables = ast?.findDirect(Expressions.FunctionParameters);
    const tableArgument = tables && ast?.has("TABLES", tables) ? ast.after("TABLES", tables) : undefined;
    const tableTarget = tableArgument instanceof Nodes.ExpressionNode ? tableArgument.findDirectExpression(Expressions.ParameterT)?.getChildren().at(-1) : undefined;
    const target = tableTarget && ast && /^[A-Z][A-Z0-9_>-]*$/i.test(ast.source(tableTarget)) ? ast.source(tableTarget) : undefined;
    if (functionName === "LIST_FROM_MEMORY" && target) {
      return `zcl_gg_list_memory=>from_lines( EXPORTING it_lines = io_session->get_navigation( )->get_list_from_memory( ) CHANGING ct_list = ${valueExpression(target, context)} ).\nsy-subrc = COND #( WHEN ${valueExpression(target, context)} IS INITIAL THEN 4 ELSE 0 ).`;
    }
    if (functionName === "LIST_TO_ASCI" && ast) {
      const list = functionArgument(ast, "LISTOBJECT");
      const ascii = functionArgument(ast, "LISTASCI");
      if (list && ascii) return `zcl_gg_list_memory=>to_ascii( EXPORTING it_list = ${valueExpression(list, context)} CHANGING ct_ascii = ${valueExpression(ascii, context)} ).\nsy-subrc = 0.`;
    }
    // Function modules with a compatibility adapter become session calls; any
    // other function module is the target system's and is called as written.
    const compatible = lowerCompatibilityFunction(replaceOutsideStrings(raw, [
      ...context.replacements,
      ["sy-repid", "io_session->get_context( )-program-program"],
      ["sy-dynnr", selectionScreenNumber(context)],
    ])) ?? rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
    const popupContinuation = context.continuations?.find(item => item.filename === statement.filename
      && item.span.start.line === statement.span.start.line && item.span.start.column === statement.span.start.column);
    if (popupContinuation && functionName?.startsWith("POPUP_")) {
      return `TRY.\n${compatible}\nCATCH zcx_gg_control_flow INTO DATA(lx_popup_${popupContinuation.id.toLowerCase()}).\nRAISE EXCEPTION TYPE zcx_gg_control_flow\n  EXPORTING\n    iv_kind = lx_popup_${popupContinuation.id.toLowerCase()}->mv_kind\n    iv_operation = lx_popup_${popupContinuation.id.toLowerCase()}->mv_operation\n    iv_continuation = '${popupContinuation.id}'.\nENDTRY.`;
    }
    return compatible;
  }
  if (statement.kind === "Leave") {
    if (ast?.hasPhrase("LIST-PROCESSING")) {
      if (!ast.hasPhrase("TO LIST-PROCESSING")) return "io_session->get_list( )->leave_list_processing( ).";
      const returnScreen = digitsOf(operand("TO SCREEN"));
      return [
        "io_session->get_list( )->enter_list_processing( ).",
        returnScreen ? `io_session->get_dialog( )->set_next_screen( '${returnScreen.padStart(4, "0")}' ).` : "",
      ].filter(Boolean).join("\n");
    }
    if (ast?.hasPhrase("PROGRAM")) return "io_session->get_navigation( )->leave_program( ).";
    if (ast?.hasPhrase("TO TRANSACTION")) {
      const tcode = literalText(operand("TO TRANSACTION"));
      return tcode ? `io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = '${tcode.toUpperCase()}' ) ).` : undefined;
    }
    if (ast?.hasPhrase("TO SCREEN")) {
      const screen = digitsOf(operand("TO SCREEN"));
      return screen ? `io_session->get_dialog( )->leave_to_screen( '${screen.padStart(4, "0")}' ).` : undefined;
    }
    return "io_session->get_dialog( )->leave_screen( ).";
  }
  if (statement.kind === "SetScreen") {
    const screen = digitsOf(ast?.sourceOf(Expressions.Source));
    return screen ? `io_session->get_dialog( )->set_next_screen( '${screen.padStart(4, "0")}' ).` : undefined;
  }
  if (statement.kind === "SetCursor") {
    const fieldOperand = operand("FIELD");
    if (fieldOperand === undefined) return "* TODO GGCONV-E516: dynamic SET CURSOR requires manual lowering.";
    const field = literalText(fieldOperand);
    const fieldValue = field === undefined
      ? `CONV string( ${valueExpression(fieldOperand, context)} )`
      : `'${field.toUpperCase()}'`;
    const line = operand("LINE");
    const row = line ? ` row = CONV i( ${valueExpression(line, context)} )` : "";
    return `io_session->get_dialog( )->set_cursor( VALUE #( field = ${fieldValue}${row} ) ).`;
  }
  if (statement.kind === "LeaveScreen") return "io_session->get_dialog( )->leave_screen( ).";
  if (statement.kind === "LeaveToScreen") {
    const screen = digitsOf(ast?.sourceOf(Expressions.Source));
    return screen ? `io_session->get_dialog( )->leave_to_screen( '${screen.padStart(4, "0")}' ).` : undefined;
  }
  if (statement.kind === "GetCursor") {
    // GET CURSOR FIELD f [LINE l], into data objects named statically.
    const simple = (value: string | undefined) => value !== undefined && /^[A-Z][A-Z0-9_-]*$/i.test(value) ? value : undefined;
    const cursorField = simple(operand("FIELD"));
    const cursorLine = cursorField ? simple(operand("LINE")) : undefined;
    if (context.event === "dynpro") {
      if (!cursorField) return "RETURN.";
      const assignments = [`${replaceOutsideStrings(cursorField, context.replacements)} = is_context-cursor_field`];
      if (cursorLine) assignments.push(`${replaceOutsideStrings(cursorLine, context.replacements)} = is_context-cursor_row`);
      return assignments.map((item) => `${item}.`).join("\n");
    }
    if (!cursorField) return "DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).";
    const assignments = [`${replaceOutsideStrings(cursorField, context.replacements)} = ls_cursor-field`];
    if (cursorLine) assignments.push(`${replaceOutsideStrings(cursorLine, context.replacements)} = ls_cursor-line`);
    return [`DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).`, ...assignments.map((item) => `${item}.`)].join("\n");
  }
  if (statement.kind === "ReadLine") {
    const number = /^READ LINE _/.test(ast?.words() ?? "") ? operand("LINE") : undefined;
    if (number === undefined) return undefined;
    const index = valueExpression(number, context);
    const levelOperand = operand("INDEX");
    const level = levelOperand !== undefined ? valueExpression(levelOperand, context) : undefined;
    return `DATA(ls_line) = io_session->get_list( )->read_line( ${level ? `iv_level = ${level} ` : ""}iv_index = ${index} ).\nsy-subrc = COND #( WHEN ls_line-index > 0 THEN 0 ELSE 4 ).`;
  }
  if (statement.kind === "ModifyLine") {
    // MODIFY LINE n [INDEX level] or MODIFY CURRENT LINE, with LINE FORMAT
    // additions. A bare INTENSIFIED, INVERSE, ... means ON.
    const counter = context.temporaries ?? { count: 0 };
    counter.count++;
    const line = `ls_modify_line_${counter.count}`;
    const number = /^MODIFY LINE _/.test(ast?.words() ?? "") ? operand("LINE") : undefined;
    const level = operand("INDEX");
    const index = number ? valueExpression(number, context) : "io_session->get_list( )->get_context( )-line";
    const lines = [`DATA(${line}) = io_session->get_list( )->read_line( ${level ? `iv_level = ${valueExpression(level, context)} ` : ""}iv_index = ${index} ).`];
    // The additions after LINE FORMAT, each word in upper case.
    const children = ast?.node.getChildren() ?? [];
    const formatStart = children.findIndex((child, at) => ast!.source(child).toUpperCase() === "LINE" && ast!.source(children[at + 1] ?? child).toUpperCase() === "FORMAT");
    const format = formatStart < 0 ? [] : children.slice(formatStart + 2);
    const words = format.map((child) => ast!.source(child).toUpperCase());
    if (words.includes("RESET")) lines.push(`CLEAR ${line}-format.`);
    for (const [keyword, field] of [["INTENSIFIED", "intensified"], ["INVERSE", "inverse"], ["HOTSPOT", "hotspot"], ["INPUT", "input"]]) {
      const at = words.indexOf(keyword);
      if (at >= 0) lines.push(`${line}-format-${field} = abap_${words[at + 1] === "OFF" ? "false" : "true"}.`);
    }
    const color = format.find((child) => child.get() instanceof Expressions.Color);
    if (color && ast) {
      const [, value, toggle] = (color as Nodes.ExpressionNode).getChildren().map((child) => ast.source(child));
      const constant = LIST_COLOR_CONSTANTS[(value ?? "").toUpperCase() as keyof typeof LIST_COLOR_CONSTANTS];
      lines.push(`${line}-format-color = ${toggle?.toUpperCase() === "OFF" ? "zif_gg_list_processing_types_v1=>color_background"
        : constant ? `zif_gg_list_processing_types_v1=>${constant}` : valueExpression(value ?? "", context)}.`);
    }
    lines.push(`io_session->get_list( )->modify_line( ${line} ).`);
    return lines.join("\n");
  }
  if (statement.kind === "Perform") {
    // A dynamic PERFORM names a FORM that became a method; a FORM in another
    // program is not converted and is still called as written.
    if (statementAst(raw)?.findDirect(Expressions.Dynamic)) return "* TODO GGCONV-E401: dynamic PERFORM requires a manual method mapping.";
    if (isExternalPerform(raw)) return rewriteStatementValues(inProgramPerform(raw).replace(/,\s*$/, "."), context);
    // PERFORM: a, b. arrives as PERFORM a, and PERFORM b., each ending in its
    // chain separator.
    const name = performedForm(raw);
    const routine = context.routines?.find((item) => item.name === name);
    const receiver = context.ownerPrefix ?? "";
    const session = context.sessionVariable ?? "io_session";
    // A FORM the program does not define has no method; see capability.ts.
    if (!routine) return "* TODO GGCONV-E516: PERFORM of a FORM the program does not define requires manual conversion.";
    // Arguments pair with parameters per section; TABLES and CHANGING both
    // become CHANGING, but each keeps its own position count.
    const argumentsBySection = new Map(Object.entries(performArguments(raw)).map(([section, values]) => [section, [...values]]));
    if (!(routine.parameters ?? []).length) return `${receiver}${routine.methodName}( io_session = ${session} ).`;
    const parameterWidth = Math.max("io_session".length, ...(routine.parameters ?? []).map((parameter) => parameter.name.length));
    const fieldsByDirection: Record<"EXPORTING" | "CHANGING", string[]> = { EXPORTING: [`${"io_session".padEnd(parameterWidth, " ")} = ${session}`], CHANGING: [] };
    const temporaries = [];
    for (const parameter of routine.parameters ?? []) {
      const values = argumentsBySection.get(parameter.section ?? (parameter.direction === "IMPORTING" ? "USING" : "CHANGING")) ?? [];
      const raw = values.shift();
      if (!raw) continue;
      let value = valueExpression(raw, context);
      const temporary = performTemporary(parameter, value, raw, context);
      if (temporary) {
        temporaries.push(...temporary.declaration);
        value = temporary.name;
      }
      fieldsByDirection[parameter.direction === "IMPORTING" ? "EXPORTING" : "CHANGING"]
        .push(`${parameter.name.padEnd(parameterWidth, " ")} = ${value}`);
    }
    const fields = Object.entries(fieldsByDirection).filter(([, values]) => values.length);
    const lines = [...temporaries, `${receiver}${routine.methodName}(`];
    // A call with importing parameters only leaves out EXPORTING.
    if (fields.length === 1 && fields[0][0] === "EXPORTING") {
      const values = fields[0][1];
      lines.push(...values.map((value, valueIndex) => `  ${value}${valueIndex === values.length - 1 ? " )." : ""}`));
      return lines.join("\n");
    }
    for (let directionIndex = 0; directionIndex < fields.length; directionIndex++) {
      const [direction, values] = fields[directionIndex];
      lines.push(`  ${direction}`);
      const isLastDirection = directionIndex === fields.length - 1;
      lines.push(...values.map((value, valueIndex) => `    ${value}${isLastDirection && valueIndex === values.length - 1 ? " )." : ""}`));
    }
    return lines.join("\n");
  }
  if (statement.kind === "Free" && context.dynamicAlv
      && ast?.tokens().some((entry) => entry.token.getUpperStr() === context.dynamicAlv!.referenceMember.toUpperCase())) {
    return `CLEAR ${context.dynamicAlv.referenceMember.toLowerCase()}.`;
  }
  if (["Export", "Import", "FreeMemory"].includes(statement.kind)) return memoryCallLines(statement, context).join("\n");
  if (statement.kind === "Include") return "* INCLUDE expanded by converter.";
  if (statement.kind === "TypePools") return "";
  if (statement.kind === "Controls") return "* CONTROLS declaration represented by dynpro metadata.";
  if (statement.kind === "LoopAtScreen") {
    const states = screenStates(context);
    return [
      ...(states.todo ? [`* TODO GGCONV-E501: ${states.todo}`] : []),
      ...(states.guard ? [`IF ${states.guard} IS BOUND.`] : []),
      `LOOP AT ${states.table} ASSIGNING FIELD-SYMBOL(${context.screenStateSymbol ?? "<ls_state>"})${states.row ? ` WHERE row = ${states.row}` : ""}.`,
    ].join("\n");
  }
  if (statement.kind === "ModifyScreen") return "* SCREEN state is already changed through <ls_state>.";
  // The ACTIVETAB, PROG and DYNNR fields of a tabbed block.
  const tabField = (text: string | undefined, fields: string[]) => {
    const [block, field] = (text ?? "").toUpperCase().split("-");
    return Boolean(field && fields.includes(field) && (context.tabbedBlocks ?? []).some((name) => name.toUpperCase() === block));
  };
  if (statement.kind === "Case" && tabField(ast?.sourceOf(Expressions.Source), ["ACTIVETAB"])) {
    return "CASE mv_active_tab.";
  }
  if (statement.kind === "Move") {
    // A chained MOVE: arrives one part at a time, each ending in a comma.
    const converted = rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
    const target = ast?.sourceOf(Expressions.Target);
    if (tabField(target, ["ACTIVETAB"])) {
      const written = statementAst(converted);
      const assignment = written ? `mv_active_tab${converted.slice(written.end(written.findDirect(Expressions.Target)!))}` : converted;
      return context.event === "initialization" ? `IF mv_active_tab IS INITIAL.\n${assignment}\nENDIF.` : assignment;
    }
    if (tabField(target, ["PROG", "DYNNR"])) return "* Selection tab state is maintained by the host screen.";
    const flagged = screenFlagAssignment(converted);
    if (flagged !== undefined) return flagged;
    const name = target !== undefined && /^[A-Z][A-Z0-9_]*$/i.test(target) ? target.toUpperCase() : undefined;
    if (name && context.dynamicCommentNames?.includes(name) && context.event !== "local_class" && converted.endsWith(".")) {
      return `${converted}\nio_session->get_dialog( )->set_status( VALUE #( status = CONV string( ${name.toLowerCase()} ) ) ).`;
    }
    return converted;
  }
  if (["Data", "DataBegin", "DataEnd", "Type", "TypeBegin", "TypeEnd", "Constant", "ConstantBegin", "ConstantEnd", "Static", "StaticBegin", "StaticEnd"].includes(statement.kind)) {
    const first = ast?.tokens()[0];
    const statics = statement.kind.startsWith("Static") && first ? `DATA${raw.slice(first.end)}` : raw;
    const declaration = context.likeMember ? likeTyping(statics, context.likeMember) : statics;
    // abaplint splits a chained declaration into one statement per element and
    // repeats the keyword while keeping the separating comma. Each emitted
    // element is a standalone statement, so a trailing comma must become its
    // terminator; BEGIN OF and END OF included, which gives the valid unchained
    // `TYPES BEGIN OF x. TYPES id TYPE i. TYPES END OF x.` form.
    const start = ["Data", "Static"].includes(statement.kind) ? systemFieldStartValue(declaration) : undefined;
    if (start) return `${replaceOutsideStrings(start.declaration, context.replacements)}\n${startValueAssignment(start, context)}`;
    return replaceOutsideStrings(declaration.replace(/,\s*$/, "."), context.replacements);
  }
  // Suspensions, MESSAGE and LEAVE unwind the generated method with
  // zcx_gg_control_flow, a cx_no_check. A handler for cx_root or cx_no_check
  // would catch that unwinding, which the statement it models never raises,
  // so a dedicated handler first passes it on unchanged.
  if (statement.kind === "Catch" && ast && catchesControlFlow(ast)) {
    const catchText = rewriteStatementValues(raw, context);
    const hasTarget = ast.hasPhrase("INTO");
    const forwardedCatch = hasTarget ? catchText : `${stripPeriod(catchText)} INTO lx_ggconv_caught.`;
    const caught = generatedLocalName("lx_ggconv_flow", statement);
    return [
      `CATCH zcx_gg_control_flow INTO DATA(${caught}).`,
      `zcx_gg_control_flow=>propagate( ${caught} ).`,
      forwardedCatch,
    ].join("\n");
  }
  // A statement abaplint could not parse is already reported as GGCONV-E201;
  // copying it would only make the generated class unparseable too.
  if (statement.kind === "Unknown") return "* TODO GGCONV-E201: statement abaplint could not classify requires manual conversion.";
  // The rules above are the fixed set of statements that need rewriting.
  // Everything else is carried over as written, with only the value rewrites;
  // abaplint splits a chained statement into one statement per element, so a
  // trailing comma becomes the terminator.
  return wrapPopup(statement, context, rewriteStatementValues(raw.replace(/,\s*$/, "."), context));
}

// The mode setters of the text and editor controls take 0 or 1, where a
// program may pass a boolean converted with CONV #( flag ).
const INTEGER_MODE_SETTERS = new Set(["SET_READONLY_MODE", "SET_TOOLBAR_MODE", "SET_STATUSBAR_MODE", "SET_FONT_FIXED"]);

function integerModeCall(ast: StatementAst, lowered: string): string {
  const tokens = ast.tokens();
  for (const parameter of ast.findEvery(Expressions.MethodCallParam)) {
    const at = tokens.findIndex((entry) => entry.start === ast.start(parameter));
    const method = tokens[at - 1];
    const [, argument] = parameter.getChildren();
    if (!method || method.end !== tokens[at].start || !INTEGER_MODE_SETTERS.has(method.token.getUpperStr())) continue;
    if (!(argument instanceof Nodes.ExpressionNode) || ast.skeleton(parameter) !== "( _ )" || ast.skeleton(argument) !== "CONV _( _ )") continue;
    const flag = argument.findDirectExpression(Expressions.ConvBody);
    if (ast.source(argument.findDirectExpression(Expressions.TypeNameOrInfer)!) !== "#" || !flag || !/^[A-Z][A-Z0-9_]*$/i.test(ast.source(flag))) continue;
    return `${lowered.slice(0, method.end)}( COND i( WHEN ${ast.source(flag)} = abap_true THEN 1 ELSE 0 ) )${lowered.slice(ast.end(parameter))}`;
  }
  return lowered;
}

function wrapPopup(statement: Statement, context: LoweringContext, rewritten: string): string {
  const continuation = isPopupStatement(statement) && context.continuations?.find(item => item.filename === statement.filename
    && item.span.start.line === statement.span.start.line && item.span.start.column === statement.span.start.column);
  if (!continuation) return rewritten;
  const caught = `lx_popup_${continuation.id.toLowerCase()}`;
  return `TRY.\n${rewritten}\nCATCH zcx_gg_control_flow INTO DATA(${caught}).\nRAISE EXCEPTION TYPE zcx_gg_control_flow\n  EXPORTING\n    iv_kind = ${caught}->mv_kind\n    iv_operation = ${caught}->mv_operation\n    iv_continuation = '${continuation.id}'.\nENDTRY.`;
}

// A block opener that lowers to nothing but a comment cannot leave its body and
// its closer behind: the generated method no longer balances, and the body would
// run outside the loop or guard that used to control it. Opener, body and closer
// are therefore dropped together, with the omitted source kept as comments.
const BLOCK_CLOSERS = new Map([
  ["If", "EndIf"], ["Do", "EndDo"], ["Loop", "EndLoop"],
  ["Case", "EndCase"], ["Try", "EndTry"], ["While", "EndWhile"],
]);
const BLOCK_CLOSER_KINDS = new Set(BLOCK_CLOSERS.values());
const UNKNOWN_BLOCK_OPENERS = new Map([["IF", "If"], ["DO", "Do"], ["LOOP", "Loop"], ["CASE", "Case"], ["TRY", "Try"], ["WHILE", "While"]]);

// A statement abaplint could not classify still opens its block when it starts
// with the keyword of one, `IF itab[ ... ]` under an older release for example:
// its closer parses, so it is dropped with it.
function blockOpenerKind(statement: Statement): string {
  if (statement.kind !== "Unknown") return statement.kind;
  return UNKNOWN_BLOCK_OPENERS.get(lexedAst(statement.text)?.tokens()[0]?.token.getUpperStr() ?? "") ?? statement.kind;
}

function blockEndIndex(statements: Statement[], start: number): number {
  const closer = BLOCK_CLOSERS.get(blockOpenerKind(statements[start]));
  let depth = 0;
  for (let index = start + 1; index < statements.length; index++) {
    const kind = blockOpenerKind(statements[index]);
    if (BLOCK_CLOSERS.has(kind)) depth++;
    else if (BLOCK_CLOSER_KINDS.has(kind)) {
      if (depth > 0) depth--;
      else return kind === closer ? index : -1;
    }
  }
  return -1;
}

function normalizeDynamicAlvStatement(statement: Statement, context: LoweringContext): Statement {
  const model = context.dynamicAlv;
  if (!model) return statement;
  const symbol = `<${model.tableSymbol}>`.toUpperCase();
  const raw = String(statement.text ?? "").trim();
  const ast = lexedAst(raw);
  if (!ast) return statement;
  const words = ast.tokens().map((entry) => entry.token.getUpperStr()).filter((word, index, all) => index < all.length - 1 || word !== ".");
  const reference = model.referenceMember.toUpperCase();
  if (words.join(" ") === `ASSIGN ${reference} -> * TO ${symbol}`) {
    return {...statement, kind: "Comment", text: "* Dynamic ALV table reference is represented by the typed class table."};
  }
  if (words.join(" ") === `UNASSIGN ${symbol}`) {
    return {...statement, kind: "Clear", text: `CLEAR ${model.referenceMember}.`};
  }
  const tokens = ast.tokens();
  const edits: { start: number; end: number; text: string }[] = [];
  tokens.forEach((entry, index) => {
    if (entry.token.getUpperStr() !== symbol) return;
    // <table> IS [NOT] ASSIGNED asks whether the reference is bound.
    const check = tokens.slice(index + 1, index + 4).map((item) => item.token.getUpperStr());
    const negated = check.join(" ") === "IS NOT ASSIGNED";
    if (negated || check.slice(0, 2).join(" ") === "IS ASSIGNED") {
      const end = tokens[index + (negated ? 3 : 2)].end;
      edits.push({ start: entry.start, end, text: `${model.referenceMember.toLowerCase()} IS ${negated ? "NOT " : ""}BOUND` });
    } else {
      edits.push({ start: entry.start, end: entry.end, text: model.tableMember.toLowerCase() });
    }
  });
  return edits.length ? {...statement, text: spliceText(raw, edits)} : statement;
}

// SELECT without INTO reads into the TABLES work area of the database table,
// which a class has as a member of that name; the INTO is written out after
// the FROM clause and its additions, as CLIENT SPECIFIED, BYPASSING BUFFER and
// UP TO n ROWS. SELECT ... FROM *dbtab reads dbtab into the work area *dbtab,
// which is named star_dbtab, see renameStarWorkAreas.
const SELECT_CLAUSES_AFTER_FROM = ["WHERE", "GROUP BY", "HAVING", "ORDER BY", "UP TO", "FOR ALL ENTRIES"];

function tablesWorkAreaSelect(statement: Statement, context: LoweringContext): Statement {
  if (!["Select", "SelectLoop"].includes(statement.kind) || !context.tablesWorkAreas?.size) return statement;
  const ast = statementAst(statement.text);
  const from = ast?.find(Expressions.DatabaseTable);
  const name = from ? ast!.source(from) : "";
  const table = from ? context.tablesWorkAreas.get(name.toUpperCase()) : undefined;
  if (!ast || !from || !table) return statement;
  const nameAt = ast.start(from);
  const text = `${statement.text.slice(0, nameAt)}${table.toLowerCase()}${statement.text.slice(ast.end(from))}`;
  if (ast.containsPhrase("INTO") || ast.containsPhrase("APPENDING")) return text === statement.text ? statement : { ...statement, text };
  // The INTO goes before the first clause after FROM, or at the end.
  const shift = table.length - name.length;
  const fromIndex = ast.tokens().findIndex((entry) => entry.start === nameAt);
  const stops = SELECT_CLAUSES_AFTER_FROM.map((phrase) => ast.phraseIndex(phrase, fromIndex)).filter((index) => index >= 0);
  const tokens = ast.tokens();
  const last = tokens.at(-1)!;
  const end = /^[.,]$/.test(last.token.getStr()) ? tokens.at(-2)!.end : last.end;
  const at = stops.length ? tokens[Math.min(...stops) - 1].end : end;
  return { ...statement, text: `${text.slice(0, at + shift)} INTO ${name.toLowerCase()}${text.slice(at + shift)}` };
}

// The statement without the header lines of the tables in scope, see
// header-lines.ts. A local declaration of such a table declares the table and
// its work area instead.
function headerLineStatement(statement: Statement, context: LoweringContext): Statement {
  const headerLines = context.headerLines ?? {};
  if (!Object.keys(headerLines).length || ["Comment", "Unknown", "Ranges", "SelectOption"].includes(statement.kind)) return statement;
  const raw = statement.text.trim();
  const ast = statementAst(raw);
  const name = ast?.find(Expressions.DefinitionName) ? ast.sourceOf(Expressions.DefinitionName)!.toUpperCase() : undefined;
  if (statement.scope === "local" && statement.kind === "Data") {
    if (name && headerLines[name] && ast!.containsPhrase("WITH HEADER LINE")) {
      const isDataObject = (operand: string) => Boolean(context.dataObjects?.has(operand.split("-")[0].toUpperCase()));
      return { ...statement, text: headerLineDeclarations(raw, headerLines[name], isDataObject, headerLines).join("\n") };
    }
  }
  if (statement.scope === "local" && statement.kind === "DataBegin") {
    return name && headerLines[name] && ast!.hasPhrase("OCCURS") ? { ...statement, text: headerLineBegin(raw, headerLines[name]) } : statement;
  }
  if (statement.scope === "local" && statement.kind === "DataEnd") {
    return name && headerLines[name] ? { ...statement, text: headerLineEnd(raw, name, headerLines[name]).join("\n") } : statement;
  }
  const text = withoutHeaderLines(statement.text, headerLines);
  return text === statement.text ? statement : { ...statement, text };
}

function referencedFieldSymbols(text: string): string[] {
  return fieldSymbolsIn(text);
}

// A dynamic ASSIGN is omitted, so a field symbol it declares inline is never
// declared either.
function inlineFieldSymbols(statements: Statement[] | undefined): string[] {
  return (statements ?? [])
    .filter((statement) => statement.kind !== "Assign" || isStaticAssign(statement.text))
    .flatMap((statement) => inlineFieldSymbolsIn(statement.text));
}

// A field symbol whose declaration and binding were both dropped as
// unconvertible has no declaration in the generated class, so a statement that
// still reads or writes it cannot compile. The use has to go with the binding.
function unboundFieldSymbols(statement: Statement, bound: Set<string>): string[] {
  if (statement.kind === "Comment") return [];
  return [...new Set(referencedFieldSymbols(statement.text))].filter((name) => !bound.has(name));
}

function unsupportedAlvTableBoundary(statement: Statement, unbound: string[], context: LoweringContext): string | undefined {
  if (!unbound.length) return undefined;
  const words = (lexedAst(statement.text.trim())?.tokens() ?? []).map((entry) => entry.token.getStr());
  const [name, arrow, method] = words.slice(0, 2).join(" ").toUpperCase() === "CALL METHOD" ? words.slice(2) : words;
  if (!name || !/^[A-Z][A-Z0-9_]*$/i.test(name) || arrow !== "->" || method?.toUpperCase() !== "SET_TABLE_FOR_FIRST_DISPLAY") return undefined;
  const receiver = replaceOutsideStrings(name.toLowerCase(), context.replacements ?? []);
  const omitted = `* TODO GGCONV-E515: statement omitted, field symbol${unbound.length > 1 ? "s" : ""} ${unbound.map((name) => `<${name.toLowerCase()}>`).join(" ")} ${unbound.length > 1 ? "have" : "has"} no convertible binding: ${statement.text.trim().replace(/\s+/g, " ")}`;
  return [
    omitted,
    `${receiver}->show_capability_boundary( heading = 'Dynamic ALV output unavailable' explanation = 'This report depends on generic field-symbol table bindings that the browser converter cannot safely reproduce. Its rows and row changes are not displayed.' ).`,
    "RETURN.",
  ].join("\n");
}

/** field = 'text', or field+n = 'text': the field, the offset and the literal. */
export function literalAssignment(text: string): { target: string; offset?: number; literal: string } | undefined {
  const ast = statementAst(text.trim());
  const target = ast?.is(Statements.Move) ? ast.findDirect(Expressions.Target) : undefined;
  const [field, offset, ...rest] = target?.getChildren() ?? [];
  const literal = ast?.findDirect(Expressions.Source)?.findDirectExpression(Expressions.Constant)?.findDirectExpression(Expressions.ConstantString);
  if (!ast || !field || rest.length || !literal || ast.source(ast.findDirect(Expressions.Source)!) !== ast.source(literal)) return undefined;
  if (offset && !(offset.get() instanceof Expressions.FieldOffset && /^\+\d+$/.test(ast.source(offset)))) return undefined;
  if (!/^[A-Z][A-Z0-9_]*$/i.test(ast.source(field)) || !ast.source(literal).startsWith("'")) return undefined;
  return { target: ast.source(field), ...(offset ? { offset: Number(ast.source(offset).slice(1)) } : {}), literal: ast.source(literal) };
}

function isCommentOnly(lowered: string | undefined): boolean {
  return lowered === undefined || lowered.split("\n").every((line) => line.trim().startsWith("*"));
}

// `*` only starts a comment in column 1, so the omitted source is flattened
// rather than kept at its original indentation.
function commentedSource(statement: Statement): string {
  return statement.text.trim().split("\n")
    .map((line) => line.trim())
    .map((line) => (line.startsWith("*") ? line : `* ${line}`))
    .join("\n");
}

export function lowerStatements(statements: Statement[], context: LoweringContext): LoweredStatement[] {
  const output: LoweredStatement[] = [];
  let pendingHidden: string[] = [];
  let lastWriteIndex = -1;
  const screenLoops: { kind: "screen" | "other"; symbol?: string; replacement?: Replacement; guarded?: boolean }[] = [];
  const usedScreenNames = new Set<string>();
  const freeChains = new Map<string, Statement[]>();
  for (const statement of statements) {
    const key = freeChainKey(statement);
    if (key) freeChains.set(key, [...(freeChains.get(key) ?? []), statement]);
  }
  const freeChainControlKeys = new Set([
    ...convertibleFreeChainKeys(statements, context.controlObjectTypes),
    ...(context.freeChainControlKeys ?? []),
  ]);
  // An inline `FIELD-SYMBOL(<fs>)` declares the symbol where it is bound, so it
  // is available to the rest of this statement list without a declaration of
  // its own. `safeFieldSymbols` is absent when a caller lowers statements
  // outside a generated class, and the check then stays off.
  const bound = Array.isArray(context.safeFieldSymbols)
    ? new Set([...context.safeFieldSymbols, ...inlineFieldSymbols(statements)])
    : undefined;
  const kept = Object.keys(context.fieldSymbolReferences ?? {})
    .filter((name) => statements.some((statement) => referencedFieldSymbols(statement.text).includes(name)));
  for (let index = 0; index < statements.length; index++) {
    let statement = statements[index];
    // HIDE stores its fields for the line written last. Before any WRITE of
    // this block they go to the next one.
    if (statement.kind === "Hide") {
      const fields = uniqueHiddenFields(hiddenFieldEntries(statement.text, context), pendingHidden);
      if (lastWriteIndex >= 0) output[lastWriteIndex].text = appendHiddenFields(output[lastWriteIndex].text, fields);
      else pendingHidden.push(...fields);
      continue;
    }
    const screenBinding = statement.kind === "LoopAtScreen" ? screenLoopBinding(statement.text, usedScreenNames) : undefined;
    const screenStateSymbol = screenBinding?.symbol ?? [...screenLoops].reverse().find((loop) => loop.kind === "screen")?.symbol;
    const screenReplacements = [...screenLoops]
      .filter((loop) => loop.kind === "screen" && loop.replacement)
      .map((loop) => loop.replacement!);
    const statementContext = {
      ...context,
      freeChainControlKeys,
      replacements: [...screenReplacements, ...(context.replacements ?? [])],
      screenStateSymbol,
    };
    statement = normalizeDynamicAlvStatement(statement, statementContext);
    statement = headerLineStatement(statement, statementContext);
    statement = tablesWorkAreaSelect(statement, statementContext);
    const freeKey = freeChainKey(statement);
    const freeMembers = freeKey ? freeChains.get(freeKey) : undefined;
    // A chain that frees a control is lowered as one CLEAR: chain. FREE itself
    // takes a single operand, so any other chain stays one FREE per element.
    if (statement.kind === "Free" && freeMembers && freeMembers.length > 1 && freeChainControlKeys.has(freeKey!)) {
      if (freeMembers[0] !== statement) continue;
      const chainText = freeMembers.map((member) => lexedAst(member.text.trim())?.body() ?? "").join(", ");
      statement = { ...statement, text: `FREE ${chainText}.` };
    }
    // WRITE icon AS ICON TO field, then field+n = 'text': the text follows
    // the icon.
    const assignment = statement.kind === "Move" ? literalAssignment(statement.text) : undefined;
    const iconAppend = assignment?.offset !== undefined ? assignment : undefined;
    const icon = statements[index - 1]?.kind === "Write" ? iconWrite(statements[index - 1].text, false) : undefined;
    const iconValue = icon ? `${icon.target.toLowerCase()} = '@ICON:${icon.icon.toLowerCase().replace(/^icon_/, "")}` : "";
    if (iconAppend && icon && iconAppend.target.toUpperCase() === icon.target.toUpperCase() && output.at(-1)?.text === `${iconValue}'.`) {
      output.at(-1)!.text = `${iconValue} ${iconAppend.literal.slice(1, -1).trimStart()}'.`;
      continue;
    }
    // ULINE leaves the cursor on a new line, where WRITE / would start another.
    const writeAst = statement.kind === "Write" && statements[index - 1]?.kind === "Uline" ? statementAst(statement.text.trim()) : undefined;
    const slash = writeAst?.tokens()[1];
    const lowerInput = writeAst && slash?.token.getStr() === "/"
      ? { ...statement, text: `WRITE ${writeAst.text.slice(slash.end).trimStart()}` }
      : statement;
    const unbound = bound ? unboundFieldSymbols(statement, bound) : [];
    const lowered = unbound.length
      ? unsupportedAlvTableBoundary(statement, unbound, statementContext)
      : lowerStatement(lowerInput, statementContext);
    const omitted = unbound.length
      ? `* TODO GGCONV-E515: statement omitted, field symbol${unbound.length > 1 ? "s" : ""} ${unbound.map((name) => `<${name.toLowerCase()}>`).join(" ")} ${unbound.length > 1 ? "have" : "has"} no convertible binding: ${statement.text.trim().replace(/\s+/g, " ")}`
      : `* TODO GGCONV-E501: unsupported statement omitted: ${statement.text.trim().replace(/\s+/g, " ")}`;
    const blockEnd = BLOCK_CLOSERS.has(blockOpenerKind(statement)) && isCommentOnly(lowered)
      ? blockEndIndex(statements, index)
      : -1;
    if (blockEnd >= 0) {
      output.push({
        text: [lowered ?? omitted, ...statements.slice(index + 1, blockEnd + 1).map(commentedSource)].join("\n"),
        statement,
        supported: false,
      });
      index = blockEnd;
      continue;
    }
    if (lowered !== undefined) {
      const following = kept.length && !isCommentOnly(lowered) ? keptFieldSymbolBindings(statement, kept, statementContext) : [];
      const item = { text: [lowered, ...following].join("\n"), statement, supported: !lowered.includes("TODO GGCONV") };
      // WRITE ... TO writes no line, so HIDE does not attach to it.
      const listWrite = statement.kind === "Write" && !writeToTarget(statement);
      if (pendingHidden.length && !listWrite && lastWriteIndex >= 0) {
        output[lastWriteIndex].text = appendHiddenFields(output[lastWriteIndex].text, pendingHidden);
        pendingHidden = [];
      }
      if (listWrite && pendingHidden.length) {
        item.text = appendHiddenFields(item.text, pendingHidden);
        pendingHidden = [];
      }
      if (statement.kind === "EndLoop" && screenLoops.at(-1)?.guarded) item.text = `${item.text}\nENDIF.`;
      output.push(item);
      if (listWrite) lastWriteIndex = output.length - 1;
      if (statement.kind === "LoopAtScreen") screenLoops.push({ kind: "screen", ...screenBinding, guarded: Boolean(screenStates(statementContext).guard) });
      if (statement.kind === "Loop") screenLoops.push({ kind: "other" });
      if (statement.kind === "EndLoop") screenLoops.pop();
    } else output.push({ text: omitted, statement, supported: false });
  }
  if (pendingHidden.length) output.push({
    text: `* TODO GGCONV-E501: HIDE values had no following WRITE statement.`,
    statement: statements.at(-1)!,
    supported: false,
  });
  for (const item of output) item.text = mergeAdjacentTemplates(item.text);
  return output;
}

// |a| && |b| written over two lines comes out as one line; one template says
// the same.
export function mergeAdjacentTemplates(text: string): string {
  if (typeof text !== "string" || !text.includes("&&")) return text;
  const tokens = lexedAst(text)?.tokens() ?? [];
  const edits: { start: number; end: number; text: string }[] = [];
  // Templates inside the { } of another one stay as written.
  let depth = 0;
  tokens.forEach((entry, index) => {
    if (entry.token instanceof Tokens.StringTemplateBegin) depth++;
    if (entry.token instanceof Tokens.StringTemplateEnd) depth--;
    const closes = entry.token instanceof Tokens.StringTemplate || entry.token instanceof Tokens.StringTemplateEnd;
    const [operator, next] = [tokens[index + 1], tokens[index + 2]];
    const opens = next?.token instanceof Tokens.StringTemplate || next?.token instanceof Tokens.StringTemplateBegin;
    // |a| && |b| without the closing and opening bars and the operator.
    if (depth === 0 && closes && operator?.token.getStr() === "&&" && opens) edits.push({ start: entry.end - 1, end: next.start + 1, text: "" });
  });
  return spliceText(text, edits);
}

export function selectionType(options: SelectionOptions): string {
  const name = (options.type ?? "STRING").toUpperCase();
  const parts = [`typ = '${TYPE_CODES.get(name) ?? name}'`];
  if (options.length) parts.push(`length = ${options.length}`);
  if (options.decimals) parts.push(`decimals = ${options.decimals}`);
  return `VALUE #( ${parts.join(" ")} )`;
}

export function selectionExpression(value: string | undefined): string | undefined {
  if (!value) return undefined;
  if (/^'(?:''|[^'])*'$|^\|[^|]*\|$/s.test(value)) return value;
  // CONV string( 3 ) is '3 ', the blank reserved for the sign.
  return /^\d+$/.test(value) ? `'${value}'` : `CONV string( ${value} )`;
}
