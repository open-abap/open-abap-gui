import { lowerCompatibilityFunction } from "../function-modules.mjs";
import { parsesAsStatement } from "../parser.mjs";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

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

function runtimeClassFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  const result = [];
  const visit = (current) => {
    for (const entry of fs.readdirSync(current, {withFileTypes: true}).sort((left, right) => left.name.localeCompare(right.name))) {
      const filename = path.join(current, entry.name);
      if (entry.isDirectory()) visit(filename);
      else if (/\.clas\.abap$/i.test(entry.name)) result.push(filename);
    }
  };
  visit(directory);
  return result;
}

const RUNTIME_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../src");
const RUNTIME_CLASS_FILES = runtimeClassFiles(RUNTIME_ROOT);

// These classes are implemented by the shipped runtime. Deriving the set
// from src/ keeps converter coverage aligned with the runtime inventory, while
// unknown GUI objects remain explicit converter gaps.
export const CONVERTIBLE_CONTROL_CLASSES = new Set(
  RUNTIME_CLASS_FILES
    .map((filename) => path.basename(filename).replace(/\.clas\.abap$/i, "").toUpperCase())
    .filter((name) => name.startsWith("CL_")),
);

export const CONVERTIBLE_STATIC_CLASSES = new Set([
  ...CONVERTIBLE_CONTROL_CLASSES,
  "ZCL_GG_GUI_DEMO_HELPER",
]);

function runtimeMethodReturns() {
  const result = new Map();
  for (const filename of RUNTIME_CLASS_FILES) {
    const className = path.basename(filename).replace(/\.clas\.abap$/i, "").toUpperCase();
    const source = fs.readFileSync(filename, "utf8");
    const methods = new Map();
    for (const match of source.matchAll(/\b(?:CLASS-)?METHODS\s+([A-Z][A-Z0-9_]*)\b([\s\S]*?\.)/gi)) {
      const returnType = /\bRETURNING\b[\s\S]*?\bTYPE\s+REF\s+TO\s+([A-Z][A-Z0-9_]*)/i.exec(match[2])?.[1];
      if (returnType) methods.set(match[1].toUpperCase(), returnType.toUpperCase());
    }
    if (methods.size) result.set(className, methods);
  }
  return result;
}

const RUNTIME_METHOD_RETURNS = runtimeMethodReturns();

function runtimeEventSignatures() {
  const result = new Map();
  for (const filename of RUNTIME_CLASS_FILES) {
    const className = path.basename(filename).replace(/\.clas\.abap$/i, "").toUpperCase();
    const source = fs.readFileSync(filename, "utf8");
    const events = new Map();
    for (const match of source.matchAll(/\bEVENTS\s+([A-Z][A-Z0-9_]*)\b([\s\S]*?)(?=\.)\./gi)) {
      const parameters = {};
      for (const parameter of match[2].matchAll(/(?:VALUE\s*\(\s*)?([A-Z][A-Z0-9_]*)\s*\)?\s+TYPE\s+REF\s+TO\s+([A-Z][A-Z0-9_]*)/gi)) {
        parameters[parameter[1].toUpperCase()] = parameter[2].toUpperCase();
      }
      events.set(match[1].toUpperCase(), parameters);
    }
    if (events.size) result.set(className, events);
  }
  return result;
}

const RUNTIME_EVENT_SIGNATURES = runtimeEventSignatures();

function runtimeClassParents() {
  const result = new Map();
  for (const filename of RUNTIME_CLASS_FILES) {
    const className = path.basename(filename).replace(/\.clas\.abap$/i, "").toUpperCase();
    const source = fs.readFileSync(filename, "utf8");
    const parent = /\bCLASS\s+[A-Z][A-Z0-9_]*\s+DEFINITION\b[\s\S]*?\bINHERITING\s+FROM\s+([A-Z][A-Z0-9_]*)/i.exec(source)?.[1];
    if (parent) result.set(className, parent.toUpperCase());
  }
  return result;
}

const RUNTIME_CLASS_PARENTS = runtimeClassParents();

function runtimeEventSignature(className, eventName) {
  let current = String(className ?? "").toUpperCase();
  const visited = new Set();
  while (current && !visited.has(current)) {
    visited.add(current);
    const signature = RUNTIME_EVENT_SIGNATURES.get(current)?.get(String(eventName ?? "").toUpperCase());
    if (signature) return signature;
    current = RUNTIME_CLASS_PARENTS.get(current);
  }
  return undefined;
}

function localClassObjectTypes(localClasses) {
  const result = new Set((localClasses ?? []).map((item) => String(item.name ?? "").toUpperCase()));
  return result;
}

function localClassStaticMethods(localClasses) {
  return Object.fromEntries((localClasses ?? []).map((localClass) => [
    String(localClass.name ?? "").toUpperCase(),
    new Set((localClass.methods ?? [])
      .filter((method) => /^\s*CLASS-METHODS\b/i.test(method.definition?.text ?? ""))
      .map((method) => String(method.name ?? "").toUpperCase())),
  ]));
}

function eventHandlerObjectTypes(localClasses) {
  const result = {};
  for (const localClass of localClasses ?? []) {
    for (const method of localClass.methods ?? []) {
      const definition = method.definition?.text ?? "";
      const event = /\bFOR\s+EVENT\s+([A-Z][A-Z0-9_]*)\s+OF\s+([A-Z][A-Z0-9_]*)\b/i.exec(definition);
      if (!event) continue;
      const signature = runtimeEventSignature(event[2], event[1]);
      if (!signature) continue;
      const importing = /\bIMPORTING\s+([\s\S]*?)(?=\b(?:EXPORTING|CHANGING|RETURNING|RAISING)\b|\.?\s*$)/i.exec(definition)?.[1] ?? "";
      for (const parameter of importing.matchAll(/\b([A-Z][A-Z0-9_]*)\b/gi)) {
        const name = parameter[1].toUpperCase();
        const type = signature[name];
        if (type && CONVERTIBLE_CONTROL_CLASSES.has(type)) result[name] = type;
      }
    }
  }
  return result;
}

export function controlObjectTypes(declarations = [], localClasses = [], {parameters = [], statements = []} = {}) {
  const result = {};
  const localClassNames = localClassObjectTypes(localClasses);
  for (const localClassName of localClassNames) result[localClassName] = `LOCAL:${localClassName}`;
  for (const declaration of declarations) {
    for (const entry of declaration.entries ?? []) {
      const type = /\bTYPE\s+REF\s+TO\s+([A-Z][A-Z0-9_]*)/i.exec(entry.definition ?? "")?.[1]?.toUpperCase();
      if (type && (CONVERTIBLE_CONTROL_CLASSES.has(type) || localClassNames.has(type))) {
        result[entry.name.toUpperCase()] = localClassNames.has(type) ? `LOCAL:${type}` : type;
      }
    }
  }
  for (const parameter of parameters ?? []) {
    const type = /\bREF\s+TO\s+([A-Z][A-Z0-9_]*)/i.exec(parameter.type ?? "")?.[1]?.toUpperCase();
    if (!type || (!CONVERTIBLE_CONTROL_CLASSES.has(type) && !localClassNames.has(type))) continue;
    result[String(parameter.name ?? "").toUpperCase()] = localClassNames.has(type) ? `LOCAL:${type}` : type;
  }
  for (const statement of statements ?? []) {
    const match = /\bDATA\s*\(\s*([A-Z][A-Z0-9_]*)\s*\)\s*=\s*([A-Z][A-Z0-9_]*)\s*->\s*([A-Z][A-Z0-9_]*)\s*\(/i.exec(statement.text ?? "");
    if (!match) continue;
    const receiver = match[2].toUpperCase();
    const receiverType = result[receiver] ?? receiver;
    const returned = RUNTIME_METHOD_RETURNS.get(receiverType)?.get(match[3].toUpperCase());
    if (returned && CONVERTIBLE_CONTROL_CLASSES.has(returned)) result[match[1].toUpperCase()] = returned;
  }
  Object.assign(result, eventHandlerObjectTypes(localClasses));
  return result;
}

function convertibleControlType(type, objectTypes) {
  return CONVERTIBLE_CONTROL_CLASSES.has(String(type ?? "").toUpperCase())
    || String(objectTypes?.[String(type ?? "").toUpperCase()] ?? "").toUpperCase().startsWith("LOCAL:")
    || CONVERTIBLE_CONTROL_CLASSES.has(String(objectTypes?.[String(type ?? "").toUpperCase()] ?? "").toUpperCase());
}

function freeReceivers(statement) {
  return String(statement?.text ?? "")
    .replace(/^FREE\s*:??\s*/i, "")
    .replace(/\.$/, "")
    .split(",")
    .map((item) => item.trim().match(/^[A-Z][A-Z0-9_]*/i)?.[0])
    .filter(Boolean);
}

export function freeChainKey(statement) {
  if (statement?.kind !== "Free") return undefined;
  const span = statement.span ?? {};
  const start = span.startOffset ?? `${span.start?.line ?? span.start?.row ?? 0}:${span.start?.column ?? span.start?.col ?? 0}`;
  return `${statement.filename ?? ""}:${start}`;
}

export function convertibleFreeChainKeys(statements, objectTypes = {}) {
  const groups = new Map();
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
export function isConvertibleControlStatement(statement, objectTypes = {}) {
  const raw = String(statement?.text ?? "").trim();
  if (statement?.kind === "CreateObject") {
    const target = /^CREATE\s+OBJECT\s+([A-Z][A-Z0-9_]*)\b/i.exec(raw)?.[1];
    const explicitType = /\bTYPE\s+(?:REF\s+TO\s+)?([A-Z][A-Z0-9_]*)\b/i.exec(raw)?.[1];
    return convertibleControlType(explicitType, objectTypes) || convertibleControlType(target, objectTypes);
  }
  if (statement?.kind === "Call" || statement?.kind === "CallMethod") {
    const receiver = /(?:CALL\s+METHOD\s+)?([A-Z][A-Z0-9_]*)\s*->/i.exec(raw)?.[1];
    const staticClass = /(?:CALL\s+METHOD\s+)?([A-Z][A-Z0-9_]*)\s*=>/i.exec(raw)?.[1];
    return convertibleControlType(receiver, objectTypes)
      || CONVERTIBLE_STATIC_CLASSES.has(String(staticClass ?? "").toUpperCase())
      || convertibleControlType(staticClass, objectTypes);
  }
  if (statement?.kind === "SetHandler") {
    const receiver = /\bFOR\s+([A-Z][A-Z0-9_]*)\b/i.exec(raw)?.[1];
    return convertibleControlType(receiver, objectTypes);
  }
  if (statement?.kind === "Free") {
    return freeReceivers(statement).some((receiver) => convertibleControlType(receiver, objectTypes));
  }
  return false;
}

function replaceListColorConstants(value) {
  let result = value;
  for (const [name, constant] of Object.entries(LIST_COLOR_CONSTANTS)) {
    result = result.replace(new RegExp(`\\b${name}\\b`, "gi"), `zif_gg_list_processing_types_v1=>${constant}`);
  }
  return result;
}

function replaceListContextFields(value) {
  return value
    .replace(/\bsy-(?:linno|lilli)\b/gi, "io_session->get_list( )->get_context( )-line")
    .replace(/\bsy-pagno\b/gi, "io_session->get_list( )->get_context( )-page");
}

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

// Statements known to be valid unchanged inside a generated method, which the
// manifest marks methodSafe. They have no lowering rule and are carried over
// as written; only local-class receivers are rewritten.
export const METHOD_SAFE_STATEMENTS = new Set([
  "Append", "Collect", "InsertInternal", "DeleteInternal", "ModifyInternal", "ReadTable",
  "Clear", "Add", "Subtract", "Multiply", "Divide", "Compute",
  "Select", "SelectLoop", "EndSelect", "InsertDatabase", "UpdateDatabase", "DeleteDatabase", "ModifyDatabase",
  "Raise", "Continue", "Unassign", "Sort", "CreateData", "GetReference", "Exit",
  "CreateObject", "Call", "CallMethod", "SetHandler",
]);

export function isMethodSafeLoop(statement) {
  if (statement.kind !== "Loop") return false;
  const body = statement.text.replace(/'(?:''|[^'])*'/g, "");
  const loopTarget = "(?:[A-Z][A-Z0-9_-]*(?:(?:->|-)[A-Z][A-Z0-9_-]*)+|[A-Z][A-Z0-9_-]*)";
  // The target may end in `>` or `)`, so the trailing guard has to be a
  // lookahead: a `\b` after either of those can never match. TRANSPORTING NO
  // FIELDS reads no row at all, so it needs no target either.
  return new RegExp(`^\\s*LOOP\\s+AT\\s+${loopTarget}\\s+(?:ASSIGNING\\s+(?:FIELD-SYMBOL\\s*\\(\\s*<[A-Z][A-Z0-9_]*>\\s*\\)|<[A-Z][A-Z0-9_]*>)|(?:REFERENCE\\s+)?INTO\\s+(?:DATA\\s*\\(\\s*[A-Z][A-Z0-9_-]*\\s*\\)|[A-Z][A-Z0-9_-]*)|TRANSPORTING\\s+NO\\s+FIELDS)(?![A-Z0-9_-])`, "i").test(body)
    && !/^\s*LOOP\s+AT\s+SCREEN\b/i.test(body);
}

function dynamicWriteExpressionSupported(operand) {
  if (!operand || /\b(?:CALL|COMMIT|GET|MESSAGE|PERFORM|RAISE|ROLLBACK|SELECT|SUBMIT|WAIT)\b|(?:->|=>)/i.test(operand)) return false;
  const callLike = /\b[A-Z][A-Z0-9_]*\s*\(/i.test(operand);
  const safeSubstring = /^\s*[A-Z][A-Z0-9_]*(?:\+\d+)?\(\d+\)\s*$/i.test(operand);
  if (callLike && !safeSubstring) return false;
  return /^[A-Z0-9_.'"|+\-*/&<>=(),\s]+$/i.test(operand);
}

function dynamicWriteClose(raw, opening) {
  let depth = 0;
  let quoted = false;
  for (let index = opening; index < raw.length; index++) {
    const char = raw[index];
    if (char === "'" && quoted && raw[index + 1] === "'") {
      index++;
      continue;
    }
    if (char === "'") {
      quoted = !quoted;
      continue;
    }
    if (quoted) continue;
    if (char === "(") depth++;
    else if (char === ")") {
      depth--;
      if (depth === 0) return index;
    }
  }
  return -1;
}

export function dynamicWriteOperand(statement) {
  if (statement.kind !== "Write") return undefined;
  const raw = statement.text.trim();
  const prefix = /^(\s*WRITE\s*:?\s*(?:\/\s*)?(?:AT\s+\d+(?:\(\d+\))?\s+)?)/i.exec(raw)?.[1];
  if (prefix === undefined || raw[prefix.length] !== "(") return undefined;
  const closing = dynamicWriteClose(raw, prefix.length);
  if (closing < 0) return undefined;
  const operand = raw.slice(prefix.length + 1, closing).trim();
  const suffix = raw.slice(closing + 1);
  return {
    operand,
    supported: dynamicWriteExpressionSupported(operand),
    rewrite: (target) => `${prefix}${target}${suffix}`,
  };
}

function lowerDynamicWriteFallback(dynamic, context) {
  const dynamicName = "lv_ggconv_dynamic_name";
  const dynamicValue = "<ggconv_dynamic_value>";
  const rewritten = dynamic.rewrite(dynamicValue);
  const unsupportedFormatting = /\b(COLOR|CURRENCY|UNIT|EXPONENT|EDIT\s+MASK|SIGN\s+AS\s+POSTFIX)\b/i.test(rewritten);
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

function stripPeriod(text) {
  return text.trim().replace(/\.\s*$/, "");
}

function quote(value) {
  return `'${String(value).replaceAll("'", "''")}'`;
}

function titlebarExpression(text, operands, context) {
  let result = String(text ?? "").replaceAll("|", "\\|");
  for (let index = 0; index < operands.length; index++) {
    const expression = valueExpression(operands[index], context);
    result = result.replaceAll(`&${index + 1}`, `{ ${expression} }`);
  }
  return `|${result}|`;
}

function splitOutsideStrings(text, delimiter = ",") {
  const parts = [];
  let current = "";
  let quotedString = false;
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (char === "'" && quotedString && text[index + 1] === "'") {
      current += "''";
      index++;
    } else if (char === "'") {
      quotedString = !quotedString;
      current += char;
    } else if (char === delimiter && !quotedString) {
      parts.push(current);
      current = "";
    } else current += char;
  }
  parts.push(current);
  return parts;
}

function splitPerformOperands(text) {
  return [...String(text ?? "").matchAll(/'(?:''|[^'])*'|[^\s,]+/g)].map((match) => match[0]);
}

function lowerDynamicAlvFactory(raw, context) {
  const model = context.dynamicAlv;
  if (!model || !/CL_ALV_TABLE_CREATE\s*=>\s*CREATE_DYNAMIC_TABLE/i.test(raw)) return undefined;
  return [
    `GET REFERENCE OF ${model.tableMember.toLowerCase()} INTO ${model.referenceMember.toLowerCase()}.`,
    `${model.styleMember.toLowerCase()} = '${model.styleComponent}'.`,
  ].join("\n");
}

function memoryBindings(text) {
  const tokens = splitPerformOperands(text);
  const bindings = [];
  for (let index = 0; index < tokens.length;) {
    const name = tokens[index++];
    if (!/^[A-Z][A-Z0-9_-]*(?:\+[0-9]+)?$/i.test(name)) continue;
    if (tokens[index] === "=") {
      const value = tokens[index + 1];
      if (!value) break;
      bindings.push({ name, value });
      index += 2;
    } else bindings.push({ name, value: name });
  }
  return bindings;
}

function memoryCallLines(statement, context) {
  const raw = stripPeriod(statement.text);
  const exportMatch = /^EXPORT\s+([\s\S]+?)\s+TO\s+MEMORY\s+ID\s+([\s\S]+)$/i.exec(raw);
  const importMatch = /^IMPORT\s+([\s\S]+?)\s+FROM\s+MEMORY\s+ID\s+([\s\S]+)$/i.exec(raw);
  const freeMatch = /^FREE\s+MEMORY\s+ID\s+([\s\S]+)$/i.exec(raw);
  if (freeMatch) return [`io_session->free_memory( iv_id = ${valueExpression(freeMatch[1], context)} ).`];
  if (exportMatch) return memoryBindings(exportMatch[1]).map(({ name, value }) =>
    `io_session->export_memory( iv_id = ${valueExpression(exportMatch[2], context)} iv_name = ${quote(name.toUpperCase())} iv_value = ${valueExpression(value, context)} ).`);
  if (importMatch) return memoryBindings(importMatch[1]).map(({ name, value }) =>
    `io_session->import_memory( EXPORTING iv_id = ${valueExpression(importMatch[2], context)} iv_name = ${quote(name.toUpperCase())} CHANGING cv_value = ${valueExpression(value, context)} ).`);
  return [];
}

// Index just past the literal that starts at `start`: '...' or `...` (a doubled
// quote escapes it), or a |...| template, whose { ... } expressions may hold
// literals and templates of their own and whose text escapes with a backslash.
function literalEnd(text, start) {
  const opener = text[start];
  if (opener === "'" || opener === "`") {
    let index = start + 1;
    while (index < text.length) {
      if (text[index] === opener && text[index + 1] === opener) index += 2;
      else if (text[index] === opener) return index + 1;
      else index++;
    }
    return text.length;
  }
  let index = start + 1;
  while (index < text.length) {
    const char = text[index];
    if (char === "\\") index += 2;
    else if (char === "|") return index + 1;
    else if (char === "{") {
      index++;
      while (index < text.length && text[index] !== "}") {
        index = "'`|".includes(text[index]) ? literalEnd(text, index) : index + 1;
      }
      index++;
    } else index++;
  }
  return text.length;
}

function splitMessageOperands(text) {
  const parts = [];
  let current = "";
  let depth = 0;
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if ("'`|".includes(char)) {
      // A literal or template is one operand, whatever spaces it holds.
      const end = literalEnd(text, index);
      current += text.slice(index, end);
      index = end - 1;
    } else if (char === "(") {
      depth++;
      current += char;
    } else if (char === ")") {
      depth = Math.max(0, depth - 1);
      current += char;
    } else if (depth === 0 && /[\s,]/.test(char)) {
      if (current.trim()) parts.push(current.trim());
      current = "";
    } else current += char;
  }
  if (current.trim()) parts.push(current.trim());
  return parts;
}

function continuationCall(target, parameter, value, id) {
  const width = Math.max(parameter.length, "is_continuation".length);
  const named = (name, expression) => `${name.padEnd(width, " ")} = ${expression}`;
  return `${target}(\n  ${named(parameter, value)}\n  ${named("is_continuation", `VALUE #( id = '${id}' )`)} ).`;
}

function transformOutsideStrings(text, transform) {
  let result = "";
  let current = "";
  let quotedString = false;
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (char === "'" && quotedString && text[index + 1] === "'") {
      result += "''";
      index++;
      continue;
    }
    if (char === "'") {
      if (!quotedString) result += transform(current);
      result += char;
      current = "";
      quotedString = !quotedString;
      continue;
    }
    if (quotedString) result += char;
    else current += char;
  }
  return result + (quotedString ? current : transform(current));
}

function replaceOutsideStrings(text, replacements) {
  return transformOutsideStrings(text, (part) => applyReplacements(part, replacements));
}

// Values a report can read that do not exist, or mean something else, in the
// generated class: system fields held by the session, the SCREEN work area of
// LOOP AT SCREEN, and the list color constants. Statements carried over as
// written get these rewrites, outside string literals; declarations and
// comments do not, since `TYPE sy-repid` must keep naming the field's type.
function dataValueRewrites(context) {
  const screen = context.screenStateSymbol ?? "<ls_state>";
  const dynproScreen = screenStates(context).kind === "dynpro";
  return [
    ...(context.replacements ?? []),
    ...Object.entries(LIST_COLOR_CONSTANTS).map(([name, constant]) => [name, `zif_gg_list_processing_types_v1=>${constant}`]),
    ["sy-ucomm", context.ucomm ?? "sy-ucomm"],
    ["sy-subrc", context.subrc ?? "sy-subrc"],
    ["sy-dynnr", context.event?.startsWith("at_selection_screen") ? "iv_screen" : "''"],
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
const SESSION_VALUE_REWRITES = [
  ["sy-(?:linno|lilli)", "io_session->get_list( )->get_context( )-line"],
  ["sy-pagno", "io_session->get_list( )->get_context( )-page"],
  ["sy-repid", "io_session->get_context( )-program-program"],
  ["sy-batch", "io_session->get_context( )-program-batch"],
  ["sy-lsind", "io_session->get_list( )->get_context( )-level"],
];

function rewriteValues(text, context, { session = true } = {}) {
  const replacements = [...dataValueRewrites(context), ...(session ? SESSION_VALUE_REWRITES : [])];
  return transformOutsideStrings(text, (part) => {
    const replaced = applyReplacements(part, replacements);
    return screenStates(context).kind === "dynpro" ? replaced : replaced.replace(/(<[A-Z][A-Z0-9_]*>)-required\b/gi, "$1-obligatory");
  });
}

// The table LOOP AT SCREEN runs over, see screen-states.mjs. Without one from
// the class emitter, the PBO method's own ct_states.
function screenStates(context) {
  return context.screenStates ?? (context.event === "dynpro"
    ? { kind: "dynpro", table: "ct_states", row: "is_context-row" }
    : { kind: "selection", table: "ct_states" });
}

// A classic statement such as CONCATENATE takes data objects only. When a
// session value makes the statement unparseable, the system field is kept.
function rewriteStatementValues(text, context) {
  const rewritten = rewriteValues(text, context);
  const dataOnly = rewriteValues(text, context, { session: false });
  return rewritten === dataOnly || parsesAsStatement(rewritten) ? rewritten : dataOnly;
}

function applyReplacements(text, replacements) {
  let output = text;
  for (const [name, replacement] of replacements) {
    output = output.replace(new RegExp(`\\b${name}\\b`, "gi"), replacement);
  }
  return output;
}

function screenLoopBinding(text, usedNames) {
  const into = /\bINTO\s+(?:DATA\s*\(\s*([A-Z][A-Z0-9_]*)\s*\)|([A-Z][A-Z0-9_]*))/i.exec(text ?? "");
  const assigning = /\bASSIGNING\s+(?:FIELD-SYMBOL\s*\(\s*<\s*([A-Z][A-Z0-9_]*)\s*>\s*\)|<\s*([A-Z][A-Z0-9_]*)\s*>)/i.exec(text ?? "");
  const sourceName = into?.[1] ?? into?.[2] ?? assigning?.[1] ?? assigning?.[2];
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

function valueExpression(expression, context) {
  let value = expression.trim();
  const replacements = [...(context.replacements ?? [])];
  for (const selection of context.selections) {
    const valueSource = context.mutableValues ? "ct_values" : "it_values";
    if (!replacements.some(([name]) => name === selection.name)) {
      replacements.push([selection.name, `${valueSource}[ name = '${selection.name}' ]-${selection.ranges ? "ranges" : "value"}`]);
    }
  }
  value = replaceOutsideStrings(value, replacements);
  value = replaceListColorConstants(value);
  value = value.replace(/\bsy-ucomm\b/gi, context.ucomm ?? "iv_ucomm");
  value = value.replace(/\bsscrfields-ucomm\b/gi, context.ucomm ?? "iv_ucomm");
  value = value.replace(/\bsy-repid\b/gi,
    context.event === "dynpro" ? "''" : "io_session->get_context( )-program-program");
  value = value.replace(/\bsy-dynnr\b/gi,
    context.event?.startsWith("at_selection_screen") ? "iv_screen" : "''");
  value = value.replace(/\bsy-batch\b/gi, "io_session->get_context( )-program-batch");
  value = value.replace(/\bsy-subrc\b/gi, context.subrc ?? "sy-subrc");
  value = value.replace(/\bsy-index\b/gi, "sy-index");
  value = value.replace(/\bsy-lsind\b/gi, "io_session->get_list( )->get_context( )-level");
  value = replaceListContextFields(value);
  return value;
}

function expressionText(expression, context) {
  const value = valueExpression(expression, context);
  if (/^'.*'$/s.test(value) || /^\|.*\|$/s.test(value)) return value;
  return `|{ ${value} }|`;
}

function continuationId(statement, context) {
  return context.continuations?.find((item) =>
    item.filename === statement.filename &&
    item.span.start.line === statement.span.start.line &&
    item.span.start.column === statement.span.start.column,
  )?.id;
}

function hiddenFieldEntries(raw, context) {
  const body = stripPeriod(raw).replace(/^HIDE\s*:??\s*/i, "");
  return body.split(",").map((part) => part.trim()).filter(Boolean).map((expression, index) => {
    const identifier = /^[A-Z][A-Z0-9_]*$/i.test(expression) ? expression.toUpperCase() : `HIDE_${index + 1}`;
    return `( name = '${identifier}' value = ${expressionText(expression, context)} )`;
  });
}

function appendHiddenFields(text, fields) {
  if (!fields.length) return text;
  const suffix = " ) ).";
  const position = text.lastIndexOf(suffix);
  if (position < 0) return text;
  return `${text.slice(0, position)} hide = VALUE #( ${fields.join(" ")} )${text.slice(position)}`;
}

function uniqueHiddenFields(fields, existing = []) {
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

function parseWrite(raw, context) {
  const writeBody = stripPeriod(raw).replace(/^WRITE\s*:?\s*/i, "").replace(/,\s*$/, "");
  if (writeBody.includes(",")) {
    const parts = splitOutsideStrings(writeBody).map((part) => part.trim()).filter(Boolean);
    if (parts.length > 1) return parts.map((part) => parseWrite("WRITE " + part, context)).join("\n");
  }
  let rest = writeBody;
  let newLine = false;
  let position;
  let length;
  if (/^\/\s*/.test(rest)) {
    newLine = true;
    rest = rest.replace(/^\/\s*/, "");
  }
  const at = /^AT\s+(\d+)(?:\((\d+)\))?\s+/i.exec(rest);
  if (at) {
    position = Number(at[1]);
    length = at[2] ? Number(at[2]) : undefined;
    rest = rest.slice(at[0].length);
  } else {
    const column = /^(\d+)(?:\((\d+)\))?\s+/.exec(rest);
    if (column) {
      position = Number(column[1]);
      length = column[2] ? Number(column[2]) : undefined;
      rest = rest.slice(column[0].length);
    }
  }
  const kind = /\s+AS\s+(CHECKBOX|ICON|SYMBOL)\b/i.exec(rest)?.[1]?.toUpperCase();
  if (kind) rest = rest.replace(new RegExp(`\\s+AS\\s+${kind}\\b`, "i"), "");
  const colorName = /\bCOLOR\s+(COL_[A-Z_]+)\b/i.exec(rest)?.[1]?.toUpperCase();
  const colorField = LIST_COLOR_FIELDS[colorName];
  // Field-level switches; OFF and "= flag" are rejected by unsupportedWriteFormat.
  const hotspot = /\bHOTSPOT\b/i.test(rest);
  const intensified = /\bINTENSIFIED\b/i.test(rest);
  const inverse = /\bINVERSE\b/i.test(rest);
  const additions = {
    noGap: /\bNO-GAP\b/i.test(rest),
    currency: /\bCURRENCY\s+([^\s,]+)/i.exec(rest)?.[1],
    decimals: /\bDECIMALS\s+(\d+)/i.exec(rest)?.[1],
    round: /\bROUND\s+(\d+)/i.exec(rest)?.[1],
    noZero: /\bNO-ZERO\b/i.test(rest),
    noSign: /\bNO-SIGN\b/i.test(rest),
    justification: /\b(LEFT-JUSTIFIED|CENTERED|RIGHT-JUSTIFIED)\b/i.exec(rest)?.[1],
  };
  rest = rest
    .replace(/\b(?:HOTSPOT|INTENSIFIED|INVERSE)(?:\s+ON)?\b/gi, "")
    .replace(/\bCOLOR\s+COL_[A-Z_]+\b/gi, "")
    .replace(/\bCURRENCY\s+[^\s,]+/gi, "")
    .replace(/\bNO-GAP\b|\bNO-ZERO\b|\bNO-SIGN\b/gi, "")
    // The list writer never inserts thousands separators, so every field is
    // already written without grouping.
    .replace(/\bNO-GROUPING\b/gi, "")
    .replace(/\bDECIMALS\s+\d+/gi, "")
    .replace(/\bROUND\s+\d+/gi, "")
    .replace(/\b(LEFT-JUSTIFIED|CENTERED|RIGHT-JUSTIFIED)\b/gi, "")
    .trim();
  const placement = [];
  if (position !== undefined) placement.push(`position = ${position}`);
  if (length !== undefined) placement.push(`length = ${length}`);
  if (newLine) placement.push("new_line = abap_true");
  if (additions.noGap) placement.push("no_gap = abap_true");
  const format = [];
  if (additions.decimals) format.push(`decimals = ${additions.decimals}`);
  if (additions.currency) format.push(`currency = |{ ${valueExpression(additions.currency, context)} }|`);
  if (additions.round) format.push(`round = ${additions.round}`);
  if (additions.noZero) format.push("no_zero = abap_true");
  if (additions.noSign) format.push("no_sign = abap_true");
  if (additions.justification) {
    const name = additions.justification === "LEFT-JUSTIFIED" ? "left" : additions.justification === "CENTERED" ? "center" : "right";
    format.push(`justification = zif_gg_list_processing_types_v1=>justify_${name}`);
  }
  const fields = [`text = ${expressionText(rest, context)}`];
  const fieldFormat = [];
  if (colorField) fieldFormat.push(`color = zif_gg_list_processing_types_v1=>${colorField}`);
  if (intensified) fieldFormat.push("intensified = abap_true");
  if (inverse) fieldFormat.push("inverse = abap_true");
  if (hotspot) fieldFormat.push("hotspot = abap_true");
  if (fieldFormat.length) fields.push(`format = VALUE #( ${fieldFormat.join(" ")} )`);
  if (placement.length) fields.push(`placement = VALUE #( ${placement.join(" ")} )`);
  if (format.length) fields.push(`write_format = VALUE #( ${format.join(" ")} )`);
  const type = kind === "CHECKBOX" ? "write_checkbox" : kind === "ICON" ? "write_icon" : kind === "SYMBOL" ? "write_symbol" : "write_field";
  if (type === "write_field") return `lo_writer->${type}( VALUE #( ${fields.join(" ")} ) ).`;
  const value = type === "write_checkbox"
    ? `name = 'CHECKBOX' value = ${valueExpression(rest, context)}`
    : `name = ${/^'[\s\S]*'$/.test(rest) ? rest : quote(valueExpression(rest, context).toUpperCase())}`;
  const typeFields = [value];
  if (placement.length) typeFields.push(`placement = VALUE #( ${placement.join(" ")} )`);
  return `lo_writer->${type}( VALUE #( ${typeFields.join(" ")} ) ).`;
}

function unsupportedWriteFormat(text) {
  const withoutLiterals = text.replace(/'(?:''|[^'])*'/g, "");
  // The writer can only switch these on for a field, not off against FORMAT.
  if (/\b(?:HOTSPOT|INTENSIFIED|INVERSE)\s*(?:OFF\b|=)/i.test(withoutLiterals)) return true;
  const classic = withoutLiterals
    .replace(/\bHOTSPOT\b/gi, "")
    .replace(/\bCOLOR\s+COL_[A-Z_]+\b/gi, "")
    .replace(/\bCURRENCY\b/gi, "");
  return /\b(COLOR|CURRENCY|UNIT|EXPONENT|EDIT\s+MASK|SIGN\s+AS\s+POSTFIX)\b/i.test(classic);
}

function parseFormat(raw, context) {
  const text = stripPeriod(raw).toUpperCase();
  if (text === "FORMAT RESET") return "lo_writer->reset_format( ).";
  const fields = [];
  const colorNames = {
    COL_BACKGROUND: "color_background", COL_HEADING: "color_heading", COL_NORMAL: "color_normal",
    COL_TOTAL: "color_total", COL_KEY: "color_key", COL_POSITIVE: "color_positive",
    COL_NEGATIVE: "color_negative", COL_GROUP: "color_group",
  };
  const colorNumber = /COLOR\s+(\d+)/.exec(text)?.[1];
  const colorName = /COLOR\s+(COL_[A-Z_]+)/.exec(text)?.[1];
  const colorExpression = /COLOR\s*=\s*([A-Z][A-Z0-9_-]*)/.exec(text)?.[1];
  if (colorNumber) fields.push(`color = ${colorNumber}`);
  if (colorName && colorNames[colorName]) fields.push(`color = zif_gg_list_processing_types_v1=>${colorNames[colorName]}`);
  if (colorExpression) fields.push(`color = ${valueExpression(colorExpression, context)}`);
  for (const [keyword, field] of [["INTENSIFIED", "intensified"], ["INVERSE", "inverse"], ["HOTSPOT", "hotspot"], ["INPUT", "input"]]) {
    const match = new RegExp(`${keyword}\\s+(ON|OFF)`).exec(text);
    if (match) fields.push(`${field} = abap_${match[1] === "ON" ? "true" : "false"}`);
  }
  return `lo_writer->set_format( VALUE #( ${fields.join(" ")} ) ).`;
}

function parseMessage(raw, context) {
  const body = stripPeriod(raw).replace(/^MESSAGE\s+/i, "");
  // DISPLAY LIKE is an addition that sits after TYPE (or after the message
  // operands). Detect it once and strip it from the text/operand payload so it
  // is never copied into the emitted string template.
  const displayLike = /DISPLAY\s+LIKE\s+'?([AEISWX])'?/i.exec(body)?.[1]?.toUpperCase();
  const displayField = displayLike ? ` display_like = zif_gg_session_types_v1=>${MESSAGE_TYPES[displayLike]}` : "";
  const type = /TYPE\s+'?([AEISWX])'?/i.exec(body)?.[1]?.toUpperCase() ?? "I";
  const typeExpr = `zif_gg_session_types_v1=>${MESSAGE_TYPES[type]}`;
  const withPart = (source) => (/\bWITH\s+(.+?)(?:\s+DISPLAY\s+LIKE\b[\s\S]*)?$/i.exec(source)?.[1] ?? "");
  const text = /^('(?:''|[^'])*')\s+TYPE/i.exec(body)?.[1];
  if (text) {
    return `io_session->message( VALUE #( type = ${typeExpr} text = ${text}${displayField} ) ).`;
  }
  const messageReference = /^([AEISWX])(\d{3})\(([A-Z0-9_]+)\)/i.exec(body);
  if (messageReference) {
    const operands = splitMessageOperands(withPart(body));
    const fields = [
      "type = zif_gg_session_types_v1=>" + MESSAGE_TYPES[messageReference[1].toUpperCase()],
      "id = '" + messageReference[3].toUpperCase() + "'",
      "number = '" + messageReference[2] + "'",
    ];
    operands.slice(0, 4).forEach((operand, index) => fields.push("v" + (index + 1) + " = " + valueExpression(operand, context)));
    return "io_session->message( VALUE #( " + fields.join(" ") + displayField + " ) ).";
  }
  const reference = /^([A-Z0-9_]+)\((\d+)\)/i.exec(body);
  if (reference) {
    const operands = splitMessageOperands(withPart(body));
    const fields = [
      "type = " + typeExpr,
      "id = '" + reference[1].toUpperCase() + "'",
      "number = '" + reference[2].padStart(3, "0") + "'",
    ];
    operands.slice(0, 4).forEach((operand, index) => fields.push("v" + (index + 1) + " = " + valueExpression(operand, context)));
    return "io_session->message( VALUE #( " + fields.join(" ") + displayField + " ) ).";
  }
  const operand = body
    .replace(/\s+DISPLAY\s+LIKE\s+'?[AEISWX]'?\s*$/i, "")
    .replace(/\s+TYPE\s+['"]?[AEISWX]['"]?\s*$/i, "")
    .trim();
  const value = valueExpression(operand, context);
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
function staticHandlerBindings(raw, context) {
  const handlers = /\bSET\s+HANDLER\s+([\s\S]*?)(?:\s+FOR\b|$)/i.exec(raw.replace(/\.\s*$/, ""))?.[1] ?? "";
  const classes = new Set();
  for (const handler of handlers.split(/\s+/).filter(Boolean)) {
    const qualified = /^([A-Z][A-Z0-9_]*)\s*=>\s*([A-Z][A-Z0-9_]*)$/i.exec(handler);
    const className = (qualified ? qualified[1] : context.localClassName ?? "").toUpperCase();
    const method = (qualified ? qualified[2] : handler).toUpperCase();
    if (context.localClassStaticEventHandlers?.[className]?.has(method)) classes.add(className);
  }
  const owner = context.localClassOwner ?? "me";
  const session = context.sessionVariable ?? "io_session";
  return [...classes].flatMap((className) => {
    const helper = context.localClassRenames?.[className] ?? className.toLowerCase();
    return [`${helper}=>go_owner = ${owner}.`, `${helper}=>go_session = ${session}.`];
  });
}

// Inside a local class, a static method of that class may be called without
// the class name; qualifying it lets the static call bridge add io_owner and
// io_session.
function qualifyOwnStaticCall(statement, context) {
  if (statement.kind !== "Call" || !context.localClassName) return statement;
  const call = /^(\s*)([A-Z][A-Z0-9_]*)(\s*\()/i.exec(statement.text);
  if (!call || !context.localClassStaticMethods?.[context.localClassName]?.has(call[2].toUpperCase())) return statement;
  return { ...statement, text: `${call[1]}${context.localClassName.toLowerCase()}=>${call[2]}${call[3]}${statement.text.slice(call[0].length)}` };
}

export function lowerStatement(original, context) {
  const statement = qualifyOwnStaticCall(original, context);
  let lowered = lowerSingleStatement(statement, context);
  if (statement !== original && typeof lowered === "string") {
    // The class name was only added for the bridge; the call stays unqualified.
    const helper = context.localClassRenames?.[context.localClassName] ?? context.localClassName.toLowerCase();
    lowered = lowered.replace(new RegExp(`^(\\s*)${helper}\\s*=>\\s*`, "i"), "$1");
  }
  if (statement.kind !== "SetHandler" || typeof lowered !== "string") return lowered;
  const bindings = staticHandlerBindings(statement.text.trim(), context);
  return bindings.length ? [...bindings, lowered].join("\n") : lowered;
}

function lowerSingleStatement(statement, context) {
  const raw = statement.text.trim();
  const normalized = raw.replace(/\s+/g, " ").toUpperCase();
  const dynamicAlvFactory = lowerDynamicAlvFactory(raw, context);
  if (dynamicAlvFactory) return dynamicAlvFactory;
  if (statement.kind === "Comment") return raw;
  const convertibleFreeChain = statement.kind === "Free"
    && context.freeChainControlKeys?.has(freeChainKey(statement));
  if (isConvertibleControlStatement(statement, context.controlObjectTypes) || convertibleFreeChain) {
    let lowered = statement.kind === "Free"
      ? raw.replace(/^FREE\s*:??\s*/i, "CLEAR: ").replace(/,\s*$/, ".")
      : raw;
    if (statement.kind === "CreateObject") {
      const target = /^CREATE\s+OBJECT\s+([A-Z][A-Z0-9_]*)\b/i.exec(lowered)?.[1]?.toUpperCase();
      const explicitType = /\bTYPE\s+([A-Z][A-Z0-9_]*)\b/i.exec(lowered)?.[1]?.toUpperCase();
      const resolvedTargetType = target && String(context.controlObjectTypes?.[target] ?? "").toUpperCase();
      const resolvedExplicitType = explicitType
        && Object.values(context.controlObjectTypes ?? {}).some((value) => String(value).toUpperCase() === `LOCAL:${explicitType}`)
        ? `LOCAL:${explicitType}`
        : "";
      const objectType = resolvedExplicitType || resolvedTargetType;
      if (objectType.startsWith("LOCAL:") && context.localClassOwner) {
        const owner = context.localClassOwner;
        const session = context.sessionVariable ?? "io_session";
        const constructor = `io_owner = ${owner} io_session = ${session}`;
        lowered = /\bEXPORTING\b/i.test(lowered)
          ? lowered.replace(/\bEXPORTING\b/i, `EXPORTING ${constructor}`)
          : `${lowered.replace(/\.\s*$/, "")} EXPORTING ${constructor}.`;
      }
    }
    if (context.dynamicAlv && /^GO_GRID\s*->\s*REFRESH_TABLE_DISPLAY\b/i.test(lowered)) {
      return "go_grid->set_table_for_first_display( CHANGING it_outtab = gt_output it_fieldcatalog = gt_fieldcat ).";
    }
    if (statement.kind === "Call" || statement.kind === "CallMethod") {
      lowered = lowered.replace(
        /\b(SET_(?:READONLY_MODE|TOOLBAR_MODE|STATUSBAR_MODE|FONT_FIXED))\(\s*CONV\s*#\(\s*([A-Z][A-Z0-9_]*)\s*\)\s*\)/i,
        "$1( COND i( WHEN $2 = abap_true THEN 1 ELSE 0 ) )",
      );
      const staticCall = /(?:CALL\s+METHOD\s+)?([A-Z][A-Z0-9_]*)\s*=>\s*([A-Z][A-Z0-9_]*)\s*\(/i.exec(lowered);
      const staticMethods = staticCall && context.localClassStaticMethods?.[staticCall[1].toUpperCase()];
      if (staticCall && staticMethods?.has(staticCall[2].toUpperCase()) && context.localClassOwner
        && !/\bIO_OWNER\s*=/i.test(lowered)) {
        const helperName = context.localClassRenames?.[staticCall[1].toUpperCase()] ?? staticCall[1].toLowerCase();
        const owner = context.localClassOwner;
        const session = context.sessionVariable ?? "io_session";
        const renamed = lowered.replace(
          new RegExp(`\\b${staticCall[1]}\\s*=>\\s*${staticCall[2]}\\s*\\(`, "i"),
          `${helperName}=>${staticCall[2]}(`,
        );
        const opening = renamed.indexOf("(", staticCall.index);
        const closing = renamed.lastIndexOf(")");
        if (opening < 0 || closing < opening) return rewriteStatementValues(renamed, context);
        let argumentsText = renamed.slice(opening + 1, closing).trim();
        const originalParameter = context.localClassStaticParameters?.[staticCall[1].toUpperCase()]?.[staticCall[2].toUpperCase()];
        if (argumentsText && originalParameter && !/^[A-Z][A-Z0-9_]*\s*=/i.test(argumentsText)) {
          argumentsText = `${originalParameter} = ${argumentsText}`;
        }
        const bridgedArguments = `io_owner = ${owner} io_session = ${session}${argumentsText ? ` ${argumentsText}` : ""}`;
        const bridged = `${renamed.slice(0, opening + 1)} ${bridgedArguments} ${renamed.slice(closing)}`;
        return rewriteStatementValues(bridged, context);
      }
    }
    return rewriteStatementValues(lowered, context);
  }
  if (statement.kind === "Write") {
    const iconAssignment = /^WRITE\s+([A-Z][A-Z0-9_]*)\s+AS\s+ICON(?:\s+QUICKINFO\s+.+?)?\s+TO\s+([A-Z][A-Z0-9_]*)\.?$/i.exec(raw);
    if (iconAssignment) return `${iconAssignment[2].toLowerCase()} = '@ICON:${iconAssignment[1].toLowerCase().replace(/^icon_/, "")}'.`;
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
  if (statement.kind === "Skip") return `lo_writer->skip( ${stripPeriod(raw).replace(/^SKIP\s*/i, "") || "1"} ).`;
  if (statement.kind === "Uline") {
    // ULINE [AT] [/][pos][(len)]; the writer always starts a new line.
    const match = /^ULINE\s*(?:AT\b\s*)?\/?\s*(\d+)?(?:\(\s*(\d+)\s*\))?/i.exec(stripPeriod(raw));
    const placement = [
      match?.[1] ? `position = ${match[1]}` : "",
      match?.[2] ? `length = ${match[2]}` : "",
    ].filter(Boolean).join(" ");
    return `lo_writer->uline( VALUE #( ${placement} ) ).\nlo_writer->new_line( ).\nlo_writer->set_position( 5 ).`;
  }
  if (statement.kind === "NewLine" || normalized === "NEW-LINE.") return "lo_writer->new_line( ).";
  if (statement.kind === "Reserve") {
    const amount = stripPeriod(raw).replace(/^RESERVE\s*/i, "").replace(/\s+LINES?$/i, "");
    return "lo_writer->reserve( " + amount + " ).";
  }
  if (statement.kind === "SetBlank") return `lo_writer->set_blank_lines( ${/\bON\b/i.test(raw) ? "abap_true" : "abap_false"} ).`;
  if (statement.kind === "NewPage") {
    const fields = [];
    if (/NO-TITLE/i.test(raw)) fields.push("no_title = abap_true");
    if (/NO-HEADING/i.test(raw)) fields.push("no_heading = abap_true");
    const lineSize = /LINE-SIZE\s+(\d+)/i.exec(raw)?.[1];
    if (lineSize) fields.push(`line_size = ${lineSize}`);
    return `lo_writer->new_page( VALUE #( ${fields.join(" ")} ) ).`;
  }
  if (statement.kind === "ScrollList") {
    if (/TO\s+FIRST\s+PAGE/i.test(raw)) return "lo_writer->scroll_to_first_page( ).";
    if (/TO\s+LAST\s+PAGE/i.test(raw)) return "lo_writer->scroll_to_last_page( ).";
    return "* TODO GGCONV-E516: unsupported SCROLL LIST target requires manual lowering.";
  }
  if (statement.kind === "Stop") return "io_session->stop( ).";
  if (statement.kind === "Message") {
    // MESSAGE ... INTO sends nothing; it only fills the target and sy-msg*,
    // which is valid in a class method, so it is carried over as written.
    if (/\bINTO\b/i.test(raw.replace(/'(?:''|[^'])*'|`(?:``|[^`])*`/g, ""))) {
      return rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
    }
    return parseMessage(raw, context);
  }
  if (statement.kind === "FieldSymbol") {
    const name = /<([A-Z][A-Z0-9_]*)>/i.exec(raw)?.[1]?.toUpperCase();
    return name && context.safeFieldSymbols?.includes(name) ? replaceOutsideStrings(raw, context.replacements) : undefined;
  }
  if (statement.kind === "Ranges") {
    const match = /^RANGES\s+([A-Z][A-Z0-9_]*)\s+FOR\s+(.+)$/i.exec(stripPeriod(raw));
    if (!match) return undefined;
    const name = match[1].toLowerCase();
    const type = context.rangeDeclarations?.[match[1].toUpperCase()] ?? "zif_gg_selection_screen_types=>ty_ranges";
    return `DATA ${name} TYPE ${type}.`;
  }
  if (statement.kind === "Assign") {
    const name = /\bTO\s+<([A-Z][A-Z0-9_]*)>/i.exec(raw)?.[1]?.toUpperCase();
    return name && context.safeFieldSymbols?.includes(name) ? replaceOutsideStrings(raw, context.replacements) : undefined;
  }
  if (statement.kind === "SetPFStatus") {
    const name = /SET PF-STATUS\s+['"]?([^\s.'"]+)/i.exec(raw)?.[1];
    if (!name) return "* TODO GGCONV-E501: dynamic PF-STATUS.";
    const statusMetadata = context.guiStatusMetadata?.[name.toUpperCase()] ?? context.guiStatusMetadata?.[name] ?? {};
    const excluding = /EXCLUDING\s+(['"]?)([A-Z0-9_%+-]+)/i.exec(raw);
    const dynamicExcluding = excluding && !excluding[1] && /^[A-Z][A-Z0-9_]*$/i.test(excluding[2]);
    const excluded = [...new Set([
      ...(excluding && !dynamicExcluding ? [excluding[2].toUpperCase()] : []),
      ...(statusMetadata.excludedUcomm ?? statusMetadata.excluded_ucomm ?? []).map((command) => String(command).toUpperCase()),
    ])];
    const active = [...new Set((statusMetadata.activeUcomm ?? statusMetadata.active_ucomm ?? context.activeCommands ?? []).map((command) => String(command).toUpperCase()))];
    const fields = [`status = '${name.toUpperCase()}'`];
    if (active.length) fields.push(`active_ucomm = VALUE #( ${active.map((command) => `( '${command}' )`).join(" ")} )`);
    if (excluded.length) fields.push(`excluded_ucomm = VALUE #( ${excluded.map((command) => `( '${command}' )`).join(" ")} )`);
    const activePFKeys = statusMetadata.activePFKeys ?? statusMetadata.active_pf_keys ?? context.activePFKeys ?? [];
    if (activePFKeys.length) fields.push(`active_pf_keys = VALUE #( ${[...new Set(activePFKeys)].map((key) => `( ${Number(key)} )`).join(" ")} )`);
    const iconBar = statusMetadata.iconBar ?? statusMetadata.icon_bar ?? [];
    if (iconBar.length) fields.push(`icon_bar = VALUE #( ${iconBar.map((item) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' label = ${quote(String(item.label ?? ""))} icon = ${quote(String(item.icon ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} )`);
    if (statusMetadata.pfActions?.length || statusMetadata.pf_actions?.length) {
      const actions = statusMetadata.pfActions ?? statusMetadata.pf_actions;
      fields.push(`pf_actions = VALUE #( ${actions.map((item) => `( number = ${Number(item.number ?? item.functionKey)} ucomm = '${String(item.ucomm ?? item.functionCode ?? "").toUpperCase()}' )`).join(" ")} )`);
    }
    if (statusMetadata.menus?.length) {
      fields.push(`menus = VALUE #( ${statusMetadata.menus.map((menu) => `( code = ${quote(String(menu.code ?? ""))} text = ${quote(String(menu.text ?? ""))} path = ${quote(String(menu.path ?? ""))} items = VALUE #( ${(
        menu.items ?? []
      ).map((item) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' text = ${quote(String(item.text ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} ) )`).join(" ")} )`);
    }
    const target = context.event === "dynpro" ? "io_session->get_dialog( )" : "io_session->get_list( )";
    const body = `${target}->set_status( VALUE #( ${fields.join(" ")}${dynamicExcluding ? " excluded_ucomm = lt_ggconv_excluded" : ""} ) ).`;
    if (!dynamicExcluding) return body;
    const variable = replaceOutsideStrings(excluding[2], context.replacements);
    return [
      "DATA lt_ggconv_excluded TYPE zif_gg_session_types_v1=>ty_ucomms.",
      `LOOP AT ${variable} INTO DATA(lv_ggconv_excluded).`,
      "  APPEND CONV #( lv_ggconv_excluded ) TO lt_ggconv_excluded.",
      "ENDLOOP.",
      body,
    ].join("\n");
  }
  if (/^SY-LSIND\s*=/i.test(raw)) {
    const value = raw.replace(/^SY-LSIND\s*=\s*/i, "").replace(/\.$/, "");
    return `io_session->get_list( )->set_level( iv_level = ${valueExpression(value, context)} ).`;
  }
  // A LOOP with an INTO or ASSIGNING target is carried over as written. One
  // without reads a header line, which a class cannot have: over a
  // select-option it is given an explicit range row, otherwise it is omitted.
  if (statement.kind === "Loop" && !isMethodSafeLoop(statement)) {
    const name = /^LOOP\s+AT\s+([A-Z][A-Z0-9_]*)\b/i.exec(raw)?.[1]?.toUpperCase();
    const selection = context.selections?.find((item) => item.name === name && item.ranges);
    if (selection) {
      const member = context.selectionState?.[name]?.member;
      if (member) return `LOOP AT ${member} INTO DATA(ls_${name.toLowerCase()}_range).`;
      const source = context.mutableValues ? "ct_values" : "it_values";
      return `LOOP AT ${source}[ name = '${name}' ]-ranges INTO DATA(ls_${name.toLowerCase()}_range).`;
    }
    return undefined;
  }
  if (statement.kind === "SetTitlebar") {
    const title = /SET TITLEBAR\s+['"]?([^\s.'"]+)/i.exec(raw)?.[1];
    if (!title) return "* TODO GGCONV-E501: dynamic titlebar.";
    const metadata = context.titlebarMetadata?.[title.toUpperCase()] ?? context.titlebarMetadata?.[title];
    const operandsText = /\bWITH\s+(.+)$/i.exec(stripPeriod(raw))?.[1] ?? "";
    const operands = splitMessageOperands(operandsText);
    const value = metadata?.text
      ? (operands.length ? titlebarExpression(metadata.text, operands, context) : quote(metadata.text))
      : quote(title.toUpperCase());
    const target = context.event === "dynpro" ? "io_session->get_dialog( )" : "io_session->get_list( )";
    return `${target}->set_title( ${value} ).`;
  }
  if (statement.kind === "CallSelectionScreen") {
    const match = /CALL\s+SELECTION-SCREEN\s+(\d+)(.*)$/i.exec(stripPeriod(raw));
    if (!match) return undefined;
    const fields = [`screen = '${match[1].padStart(4, "0")}'`];
    const modal = /STARTING\s+AT\s+(\d+)\s+(\d+)/i.exec(match[2]);
    if (modal) fields.push(`modal = VALUE #( start_row = ${modal[1]} start_column = ${modal[2]} )`);
    const id = continuationId(statement, context);
    if (!id) return undefined;
    return continuationCall("io_session->get_dialog( )->call_selection_screen", "is_call", `VALUE #( ${fields.join(" ")} )`, id);
  }
  if (statement.kind === "CallScreen") {
    const match = /CALL\s+SCREEN\s+(\d+)(.*)$/i.exec(stripPeriod(raw));
    if (!match) return undefined;
    const fields = [`screen = '${match[1].padStart(4, "0")}'`];
    const modal = /STARTING\s+AT\s+(\d+)\s+(\d+)(?:\s+ENDING\s+AT\s+(\d+)\s+(\d+))?/i.exec(match[2]);
    if (modal) fields.push(`modal = VALUE #( start_row = ${modal[1]} start_column = ${modal[2]}${modal[3] ? ` end_row = ${modal[3]} end_column = ${modal[4]}` : ""} )`);
    const id = continuationId(statement, context);
    if (!id) return undefined;
    return continuationCall("io_session->get_dialog( )->call_screen", "is_call", `VALUE #( ${fields.join(" ")} )`, id);
  }
  if (statement.kind === "Submit") {
    const body = stripPeriod(raw).replace(/^SUBMIT\s+/i, "");
    const program = /^([^\s]+)/.exec(body)?.[1]?.toUpperCase();
    if (!program) return undefined;
    const fields = [`program = '${program}'`];
    const variantLiteral = /USING\s+SELECTION-SET\s+'([^']+)'/i.exec(body)?.[1];
    const variantDynamic = /USING\s+SELECTION-SET\s+([A-Z][A-Z0-9_]*)/i.exec(body)?.[1];
    if (variantLiteral) fields.push(`variant = '${variantLiteral.toUpperCase()}'`);
    else if (variantDynamic) fields.push(`variant = ${valueExpression(variantDynamic, context)}`);
    if (/EXPORTING\s+LIST\s+TO\s+MEMORY/i.test(body)) fields.push("list_to_memory = abap_true");
    const selectionTable = /WITH\s+SELECTION-TABLE\s+([A-Z][A-Z0-9_]*)/i.exec(body)?.[1];
    if (selectionTable) {
      fields.push(`values = io_session->get_compatibility( )->selection_table_to_values( ${valueExpression(selectionTable, context)} )`);
    }
    if (/VIA\s+SELECTION-SCREEN/i.test(body)) fields.push("via_selection_screen = abap_true");
    const withValue = /WITH\s+([A-Z][A-Z0-9_]*)\s+IN\s+(VALUE\s+#\(.*?\))\s*(?:AND\s+RETURN)?$/i.exec(body);
    if (withValue) fields.push(`values = VALUE #( ( name = '${withValue[1].toUpperCase()}' ranges = ${withValue[2]} ) )`);
    const id = continuationId(statement, context);
    if (/AND\s+RETURN/i.test(body)) {
      if (!id) return undefined;
      return continuationCall("io_session->get_navigation( )->submit_and_return", "is_submit", `VALUE #( ${fields.join(" ")} )`, id);
    }
    return `io_session->get_navigation( )->submit( VALUE #( ${fields.join(" ")} ) ).`;
  }
  if (statement.kind === "CallTransaction") {
    const tcode = /CALL\s+TRANSACTION\s+'([^']+)'/i.exec(raw)?.[1];
    const id = continuationId(statement, context);
    if (!tcode || !id) return undefined;
    return continuationCall("io_session->get_navigation( )->call_transaction", "is_call", `VALUE #( tcode = '${tcode.toUpperCase()}'${/SKIP\s+FIRST\s+SCREEN/i.test(raw) ? " skip_first_screen = abap_true" : ""} )`, id);
  }
  if (statement.kind === "SuppressDialog") {
    return "io_session->get_dialog( )->suppress_dialog( ).";
  }
  if (statement.kind === "SetParameter") {
    const match = /SET\s+PARAMETER\s+ID\s+'([^']+)'\s+FIELD\s+(.+)$/i.exec(stripPeriod(raw));
    if (!match) return undefined;
    return `io_session->get_compatibility( )->set_parameter( iv_id = ${quote(match[1].toUpperCase())} iv_value = CONV string( ${valueExpression(match[2], context)} ) ).`;
  }
  if (statement.kind === "GetParameter") {
    const match = /GET\s+PARAMETER\s+ID\s+'([^']+)'\s+FIELD\s+(.+)$/i.exec(stripPeriod(raw));
    if (!match) return undefined;
    return `${replaceOutsideStrings(match[2], context.replacements)} = CONV #( io_session->get_compatibility( )->get_parameter( iv_id = ${quote(match[1].toUpperCase())} ) ).`;
  }
  if (statement.kind === "AuthorityCheck") {
    const match = /AUTHORITY-CHECK\s+OBJECT\s+'([^']+)'\s+ID\s+'([^']+)'\s+FIELD\s+(.+)$/i.exec(stripPeriod(raw));
    if (!match) return undefined;
    return `sy-subrc = COND #( WHEN io_session->get_compatibility( )->authority_check( iv_object = ${quote(match[1].toUpperCase())} iv_id = ${quote(match[2].toUpperCase())} iv_value = CONV string( ${valueExpression(match[3], context)} ) ) = abap_true THEN 0 ELSE 4 ).`;
  }
  if (statement.kind === "CallFunction") {
    const target = /TABLES\s+([A-Z][A-Z0-9_]*)\s*=/i.exec(raw)?.[1];
    if (/CALL\s+FUNCTION\s+'LIST_FROM_MEMORY'/i.test(raw) && target) {
      return `${target} = io_session->get_navigation( )->get_list_from_memory( ).`;
    }
    // Function modules with a compatibility adapter become session calls; any
    // other function module is the target system's and is called as written.
    return lowerCompatibilityFunction(replaceOutsideStrings(raw, [
      ...context.replacements,
      ["sy-repid", context.event === "dynpro"
        ? "''"
        : "io_session->get_context( )-program-program"],
      ["sy-dynnr", "''"],
    ])) ?? rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
  }
  if (statement.kind === "Leave") {
    if (/LIST-PROCESSING/i.test(raw)) {
      if (!/TO LIST/i.test(raw)) return "io_session->get_list( )->leave_list_processing( ).";
      const returnScreen = /RETURN\s+TO\s+SCREEN\s+(\d+)/i.exec(raw)?.[1];
      return [
        "io_session->get_list( )->enter_list_processing( ).",
        returnScreen ? `io_session->get_dialog( )->set_next_screen( '${returnScreen.padStart(4, "0")}' ).` : "",
      ].filter(Boolean).join("\n");
    }
    if (/PROGRAM/i.test(raw)) return "io_session->get_navigation( )->leave_program( ).";
    if (/TO TRANSACTION/i.test(raw)) {
      const tcode = /TO\s+TRANSACTION\s+'([^']+)'/i.exec(raw)?.[1];
      return tcode ? `io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = '${tcode.toUpperCase()}' ) ).` : undefined;
    }
    if (/TO\s+SCREEN/i.test(raw)) {
      const screen = /TO\s+SCREEN\s+(\d+)/i.exec(raw)?.[1];
      return screen ? `io_session->get_dialog( )->leave_to_screen( '${screen.padStart(4, "0")}' ).` : undefined;
    }
    return "io_session->get_dialog( )->leave_screen( ).";
  }
  if (statement.kind === "SetScreen") {
    const screen = /SET\s+SCREEN\s+(\d+)/i.exec(raw)?.[1];
    return screen ? `io_session->get_dialog( )->set_next_screen( '${screen.padStart(4, "0")}' ).` : undefined;
  }
  if (statement.kind === "SetCursor") {
    const body = stripPeriod(raw);
    const match = /SET\s+CURSOR\s+FIELD\s+(.+?)(?:\s+LINE\s+(.+))?$/i.exec(body);
    if (!match) return "* TODO GGCONV-E516: dynamic SET CURSOR requires manual lowering.";
    const fieldOperand = match[1].trim();
    const field = /^'([^']*)'$/s.exec(fieldOperand)?.[1];
    const fieldValue = field === undefined
      ? `CONV string( ${valueExpression(fieldOperand, context)} )`
      : `'${field.toUpperCase()}'`;
    const line = match[2]?.trim();
    const row = line ? ` row = CONV i( ${valueExpression(line, context)} )` : "";
    return `io_session->get_dialog( )->set_cursor( VALUE #( field = ${fieldValue}${row} ) ).`;
  }
  if (statement.kind === "LeaveScreen") return "io_session->get_dialog( )->leave_screen( ).";
  if (statement.kind === "LeaveToScreen") {
    const screen = /LEAVE\s+TO\s+SCREEN\s+(\d+)/i.exec(raw)?.[1];
    return screen ? `io_session->get_dialog( )->leave_to_screen( '${screen.padStart(4, "0")}' ).` : undefined;
  }
  if (statement.kind === "GetCursor") {
    const match = /GET\s+CURSOR\s+FIELD\s+([A-Z][A-Z0-9_-]*)(?:\s+LINE\s+([A-Z][A-Z0-9_-]*))?/i.exec(raw);
    if (context.event === "dynpro") {
      if (!match) return "RETURN.";
      const assignments = [`${replaceOutsideStrings(match[1], context.replacements)} = is_context-cursor_field`];
      if (match[2]) assignments.push(`${replaceOutsideStrings(match[2], context.replacements)} = is_context-cursor_row`);
      return assignments.map((item) => `${item}.`).join("\n");
    }
    if (!match) return "DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).";
    const assignments = [`${replaceOutsideStrings(match[1], context.replacements)} = ls_cursor-field`];
    if (match[2]) assignments.push(`${replaceOutsideStrings(match[2], context.replacements)} = ls_cursor-line`);
    return [`DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).`, ...assignments.map((item) => `${item}.`)].join("\n");
  }
  if (statement.kind === "ReadLine") {
    const match = /READ\s+LINE\s+(\d+)(?:\s+INDEX\s+(\d+))?(?:\s+LEVEL\s+(\d+))?/i.exec(raw);
    const index = match?.[2] ?? match?.[1] ?? "1";
    const level = match?.[3];
    return `DATA(ls_line) = io_session->get_list( )->read_line( ${level ? `iv_level = ${level} ` : ""}iv_index = ${index} ).`;
  }
  if (statement.kind === "ModifyLine") {
    const fields = [];
    const text = raw.toUpperCase();
    for (const [keyword, field] of [["INTENSIFIED", "intensified"], ["INVERSE", "inverse"], ["HOTSPOT", "hotspot"], ["INPUT", "input"]]) {
      const match = new RegExp(`${keyword}\\s+(ON|OFF)`).exec(text);
      if (match) fields.push(`ls_line-format-${field} = abap_${match[1] === "ON" ? "true" : "false"}`);
    }
    return `${fields.length ? `${fields.join(".\n")}.\n` : ""}io_session->get_list( )->modify_line( ls_line ).`;
  }
  if (statement.kind === "Perform") {
    // A dynamic PERFORM names a FORM that became a method; a FORM in another
    // program is not converted and is still called as written.
    if (/\bPERFORM\s+\(/i.test(raw)) return "* TODO GGCONV-E401: dynamic PERFORM requires a manual method mapping.";
    if (/\bIN\s+PROGRAM\b/i.test(raw)) return rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
    const name = /^PERFORM\s+([^\s.]+)/i.exec(raw)?.[1];
    const routine = context.routines?.find((item) => item.name === name?.toUpperCase());
    const receiver = context.ownerPrefix ?? "";
    const session = context.sessionVariable ?? "io_session";
    if (!routine) return name ? `${receiver}form_${name.toLowerCase()}( ).` : "* TODO GGCONV-E401: dynamic PERFORM.";
    const argumentsByDirection = new Map();
    let direction;
    for (const token of splitPerformOperands(raw.replace(/^PERFORM\s+[^\s.]+\s*/i, "").replace(/\.$/, ""))) {
      const upper = token.toUpperCase();
      if (["USING", "CHANGING", "TABLES"].includes(upper)) {
        direction = upper === "USING" ? "EXPORTING" : "CHANGING";
        argumentsByDirection.set(direction, []);
      } else if (direction) {
        argumentsByDirection.get(direction).push(token);
      }
    }
    if (!(routine.parameters ?? []).length) return `${receiver}${routine.methodName}( io_session = ${session} ).`;
    const parameterWidth = Math.max("io_session".length, ...(routine.parameters ?? []).map((parameter) => parameter.name.length));
    const fieldsByDirection = { EXPORTING: [`${"io_session".padEnd(parameterWidth, " ")} = ${session}`], CHANGING: [] };
    for (const parameter of routine.parameters ?? []) {
      const values = argumentsByDirection.get(parameter.direction === "IMPORTING" ? "EXPORTING" : "CHANGING") ?? [];
      const value = values.shift();
      if (value) fieldsByDirection[parameter.direction === "IMPORTING" ? "EXPORTING" : "CHANGING"]
        .push(`${parameter.name.padEnd(parameterWidth, " ")} = ${valueExpression(value, context)}`);
    }
    const fields = Object.entries(fieldsByDirection).filter(([, values]) => values.length);
    const lines = [`${receiver}${routine.methodName}(`];
    for (let directionIndex = 0; directionIndex < fields.length; directionIndex++) {
      const [direction, values] = fields[directionIndex];
      lines.push(`  ${direction}`);
      const isLastDirection = directionIndex === fields.length - 1;
      lines.push(...values.map((value, valueIndex) => `    ${value}${isLastDirection && valueIndex === values.length - 1 ? " )." : ""}`));
    }
    return lines.join("\n");
  }
  if (statement.kind === "Free" && context.dynamicAlv
      && new RegExp(`\\b${context.dynamicAlv.referenceMember}\\b`, "i").test(raw)) {
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
  if (statement.kind === "Case" && context.event === "at_selection_screen" && /^CASE\s+G_TABS-ACTIVETAB\b/i.test(raw)) {
    return "CASE COND string( WHEN iv_ucomm <> 'ONLI' THEN iv_ucomm ELSE mv_active_tab ).";
  }
  if (statement.kind === "Move") {
    let converted = rewriteStatementValues(raw, context);
    if (/^G_TABS-ACTIVETAB\s*=/i.test(raw)) {
      const assignment = converted.replace(/^G_TABS-ACTIVETAB/i, "mv_active_tab");
      return context.event === "initialization" ? `IF mv_active_tab IS INITIAL.\n  ${assignment}\nENDIF.` : assignment;
    }
    if (/^G_TABS-(?:PROG|DYNNR)\s*=/i.test(raw)) return "* Selection tab state is maintained by the host screen.";
    converted = converted.replace(/<ls_state>-password\s*=\s*'1'/i, "<ls_state>-password = abap_true");
    converted = converted.replace(/<ls_state>-password\s*=\s*'0'/i, "<ls_state>-password = abap_false");
    converted = converted.replace(/<ls_state>-no_display\s*=\s*['"]?1['"]?/i, "<ls_state>-no_display = abap_true");
    converted = converted.replace(/<ls_state>-no_display\s*=\s*['"]?0['"]?/i, "<ls_state>-no_display = abap_false");
    converted = converted.replace(/<ls_state>-(input|output)\s*=\s*['"]?1['"]?/gi, "<ls_state>-$1 = abap_true");
    converted = converted.replace(/<ls_state>-(input|output)\s*=\s*['"]?0['"]?/gi, "<ls_state>-$1 = abap_false");
    converted = converted.replace(/<ls_state>-intensified\s*=\s*['"]?1['"]?/i, "<ls_state>-intensified = abap_true");
    converted = converted.replace(/<ls_state>-intensified\s*=\s*['"]?0['"]?/i, "<ls_state>-intensified = abap_false");
    converted = converted.replace(/<ls_state>-visible\s*=\s*COND\s*#\(\s*WHEN\s+(.+?)\s+THEN\s+'1'\s+ELSE\s+'0'\s*\)\./i, "<ls_state>-visible = xsdbool( $1 ).");
    converted = converted.replace(/<ls_state>-intensified\s*=\s*COND\s*#\(\s*WHEN\s+(.+?)\s+THEN\s+'1'\s+ELSE\s+'0'\s*\)\./i, "<ls_state>-intensified = xsdbool( $1 ).");
    converted = converted.replace(/<ls_state>-visible\s*=\s*'1'/i, "<ls_state>-visible = abap_true");
    converted = converted.replace(/<ls_state>-visible\s*=\s*'0'/i, "<ls_state>-visible = abap_false");
    converted = converted.replace(/<ls_state>-obligatory\s*=\s*'2'/i, "<ls_state>-obligatory = abap_true");
    converted = converted.replace(/<ls_state>-obligatory\s*=\s*'0'/i, "<ls_state>-obligatory = abap_false");
    const target = /^\s*([A-Z][A-Z0-9_]*)\s*=/i.exec(raw)?.[1]?.toUpperCase();
    if (target && context.dynamicCommentNames?.includes(target)
        && context.event !== "local_class") {
      const assignment = /^(\s*[^=]+\s*=\s*)([\s\S]+)\.$/.exec(converted);
      if (assignment) {
        return `${converted}\nio_session->get_dialog( )->set_status( VALUE #( status = CONV string( ${target.toLowerCase()} ) ) ).`;
      }
    }
    return converted;
  }
  if (["Data", "DataBegin", "DataEnd", "Type", "TypeBegin", "TypeEnd", "Constant", "Static"].includes(statement.kind)) {
    const declaration = statement.kind === "Static" ? raw.replace(/^STATICS\b/i, "DATA") : raw;
    // abaplint splits a chained declaration into one statement per element and
    // repeats the keyword while keeping the separating comma. Each emitted
    // element is a standalone statement, so a trailing comma must become its
    // terminator; BEGIN OF and END OF included, which gives the valid unchained
    // `TYPES BEGIN OF x. TYPES id TYPE i. TYPES END OF x.` form.
    return replaceOutsideStrings(declaration.replace(/,\s*$/, "."), context.replacements);
  }
  // A statement abaplint could not parse is already reported as GGCONV-E201;
  // copying it would only make the generated class unparseable too.
  if (statement.kind === "Unknown") return "* TODO GGCONV-E201: statement abaplint could not classify requires manual conversion.";
  // The rules above are the fixed set of statements that need rewriting.
  // Everything else is carried over as written, with only the value rewrites;
  // abaplint splits a chained statement into one statement per element, so a
  // trailing comma becomes the terminator.
  return rewriteStatementValues(raw.replace(/,\s*$/, "."), context);
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

function blockEndIndex(statements, start) {
  const closer = BLOCK_CLOSERS.get(statements[start].kind);
  let depth = 0;
  for (let index = start + 1; index < statements.length; index++) {
    const kind = statements[index].kind;
    if (BLOCK_CLOSERS.has(kind)) depth++;
    else if (BLOCK_CLOSER_KINDS.has(kind)) {
      if (depth > 0) depth--;
      else return kind === closer ? index : -1;
    }
  }
  return -1;
}

// ABAP string literals and templates can hold angle brackets that are not
// field symbols at all - HTML fragments in particular - so literal template
// text is removed while expressions inside `{ ... }` remain searchable.
export function withoutLiteralTemplateText(text) {
  let result = "";
  let inTemplate = false;
  let expressionDepth = 0;
  let quoted = false;
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (!inTemplate) {
      if (char === "|") {
        inTemplate = true;
        result += " ";
      } else result += char;
      continue;
    }
    if (char === "'" && quoted && text[index + 1] === "'") {
      result += "''";
      index++;
      continue;
    }
    if (char === "'") {
      quoted = !quoted;
      if (expressionDepth > 0) result += char;
      continue;
    }
    if (quoted) {
      if (expressionDepth > 0) result += char;
      continue;
    }
    if (char === "|" && text[index + 1] === "|") {
      index++;
      if (expressionDepth > 0) result += "||";
      continue;
    }
    if (char === "|" && expressionDepth === 0) {
      inTemplate = false;
      result += " ";
      continue;
    }
    if (char === "{" && expressionDepth >= 0) {
      expressionDepth++;
      result += " ";
      continue;
    }
    if (char === "}" && expressionDepth > 0) {
      expressionDepth--;
      result += " ";
      continue;
    }
    if (expressionDepth > 0) result += char;
  }
  return result;
}

function normalizeDynamicAlvStatement(statement, context) {
  const model = context.dynamicAlv;
  if (!model) return statement;
  const symbol = `<${model.tableSymbol}>`;
  const raw = String(statement.text ?? "").trim();
  if (new RegExp(`^ASSIGN\\s+${model.referenceMember}->\\*\\s+TO\\s+${symbol}\\.?$`, "i").test(raw)) {
    return {...statement, kind: "Comment", text: "* Dynamic ALV table reference is represented by the typed class table."};
  }
  if (new RegExp(`^UNASSIGN\\s+${symbol}\\.?$`, "i").test(raw)) {
    return {...statement, kind: "Clear", text: `CLEAR ${model.referenceMember}.`};
  }
  const tableMember = model.tableMember.toLowerCase();
  const rewritten = raw
    .replace(new RegExp(symbol, "gi"), tableMember)
    .replace(new RegExp(`\\b${tableMember}\\s+IS\\s+NOT\\s+ASSIGNED\\b`, "i"), `${model.referenceMember.toLowerCase()} IS NOT BOUND`)
    .replace(new RegExp(`\\b${tableMember}\\s+IS\\s+ASSIGNED\\b`, "i"), `${model.referenceMember.toLowerCase()} IS BOUND`);
  return rewritten === raw ? statement : {...statement, text: rewritten};
}

function referencedFieldSymbols(text) {
  const body = withoutLiteralTemplateText(text)
    .replace(/'(?:''|[^'])*'/g, " ")
    .replace(/`(?:``|[^`])*`/g, " ");
  return [...body.matchAll(/<([A-Z][A-Z0-9_]*)>/gi)].map((match) => match[1].toUpperCase());
}

export function inlineFieldSymbols(statements) {
  return (statements ?? []).flatMap((statement) =>
    [...statement.text.matchAll(/\bFIELD-SYMBOL\s*\(\s*<([A-Z][A-Z0-9_]*)>\s*\)/gi)].map((match) => match[1].toUpperCase()));
}

// A field symbol whose declaration and binding were both dropped as
// unconvertible has no declaration in the generated class, so a statement that
// still reads or writes it cannot compile. The use has to go with the binding.
function unboundFieldSymbols(statement, bound) {
  if (statement.kind === "Comment") return [];
  return [...new Set(referencedFieldSymbols(statement.text))].filter((name) => !bound.has(name));
}

function unsupportedAlvTableBoundary(statement, unbound, context) {
  if (!unbound.length) return undefined;
  const match = /^\s*(?:CALL\s+METHOD\s+)?([A-Z][A-Z0-9_]*)\s*->\s*SET_TABLE_FOR_FIRST_DISPLAY\b/i.exec(statement.text.trim());
  if (!match) return undefined;
  const receiver = replaceOutsideStrings(match[1].toLowerCase(), context.replacements ?? []);
  const omitted = `* TODO GGCONV-E515: statement omitted, field symbol${unbound.length > 1 ? "s" : ""} ${unbound.map((name) => `<${name.toLowerCase()}>`).join(" ")} ${unbound.length > 1 ? "have" : "has"} no convertible binding: ${statement.text.trim().replace(/\s+/g, " ")}`;
  return [
    omitted,
    `${receiver}->show_capability_boundary( heading = 'Dynamic ALV output unavailable' explanation = 'This report depends on generic field-symbol table bindings that the browser converter cannot safely reproduce. Its rows and row changes are not displayed.' ).`,
    "RETURN.",
  ].join("\n");
}

function isCommentOnly(lowered) {
  return lowered === undefined || lowered.split("\n").every((line) => line.trim().startsWith("*"));
}

// `*` only starts a comment in column 1, so the omitted source is flattened
// rather than kept at its original indentation.
function commentedSource(statement) {
  return statement.text.trim().split("\n")
    .map((line) => line.trim())
    .map((line) => (line.startsWith("*") ? line : `* ${line}`))
    .join("\n");
}

export function lowerStatements(statements, context) {
  const output = [];
  let pendingHidden = [];
  let lastWriteIndex = -1;
  const rangeLoops = [];
  const screenLoops = [];
  const usedScreenNames = new Set();
  const freeChains = new Map();
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
  for (let index = 0; index < statements.length; index++) {
    let statement = statements[index];
    if (statement.kind === "Hide") {
      pendingHidden.push(...uniqueHiddenFields(hiddenFieldEntries(statement.text, context), pendingHidden));
      continue;
    }
    const screenBinding = statement.kind === "LoopAtScreen" ? screenLoopBinding(statement.text, usedScreenNames) : undefined;
    const screenStateSymbol = screenBinding?.symbol ?? [...screenLoops].reverse().find((loop) => loop.kind === "screen")?.symbol;
    const screenReplacements = [...screenLoops]
      .filter((loop) => loop.kind === "screen" && loop.replacement)
      .map((loop) => loop.replacement);
    const statementContext = {
      ...context,
      freeChainControlKeys,
      replacements: [...screenReplacements, ...rangeLoops, ...(context.replacements ?? []).filter(([name]) => !rangeLoops.some(([active]) => active === name))],
      screenStateSymbol,
    };
    statement = normalizeDynamicAlvStatement(statement, statementContext);
    const freeKey = freeChainKey(statement);
    const freeMembers = freeKey ? freeChains.get(freeKey) : undefined;
    if (statement.kind === "Free" && freeMembers?.length > 1) {
      if (freeMembers[0] !== statement) continue;
      const chainText = freeMembers
        .map((member) => member.text.trim()
          .replace(/^FREE\s*:??\s*/i, "")
          .replace(/[,.]\s*$/, ""))
        .join(", ");
      statement = { ...statement, text: `FREE ${chainText}.` };
    }
    const iconAppend = statement.kind === "Move"
      ? /^([A-Z][A-Z0-9_]*)\+(\d+)\s*=\s*('(?:''|[^'])*')\.?$/i.exec(statement.text.trim())
      : undefined;
    const iconWrite = statements[index - 1]?.kind === "Write"
      ? /^WRITE\s+([A-Z][A-Z0-9_]*)\s+AS\s+ICON\s+TO\s+([A-Z][A-Z0-9_]*)\.?$/i.exec(statements[index - 1].text.trim())
      : undefined;
    if (iconAppend && iconWrite && iconAppend[1].toUpperCase() === iconWrite[2].toUpperCase()
      && output.at(-1)?.text === `${iconWrite[2].toLowerCase()} = '@ICON:${iconWrite[1].toLowerCase().replace(/^icon_/, "")}'.`) {
      output.at(-1).text = `${iconWrite[2].toLowerCase()} = '@ICON:${iconWrite[1].toLowerCase().replace(/^icon_/, "")}${iconAppend[3].slice(1, -1)}'.`;
      continue;
    }
    const lowerInput = statement.kind === "Write"
      && statements[index - 1]?.kind === "Uline"
      && /^WRITE\s*\//i.test(statement.text.trim())
      ? { ...statement, text: statement.text.replace(/^\s*WRITE\s*\/\s*/i, "WRITE ") }
      : statement;
    const unbound = bound ? unboundFieldSymbols(statement, bound) : [];
    const lowered = unbound.length
      ? unsupportedAlvTableBoundary(statement, unbound, statementContext)
      : lowerStatement(lowerInput, statementContext);
    const omitted = unbound.length
      ? `* TODO GGCONV-E515: statement omitted, field symbol${unbound.length > 1 ? "s" : ""} ${unbound.map((name) => `<${name.toLowerCase()}>`).join(" ")} ${unbound.length > 1 ? "have" : "has"} no convertible binding: ${statement.text.trim().replace(/\s+/g, " ")}`
      : `* TODO GGCONV-E501: unsupported statement omitted: ${statement.text.trim().replace(/\s+/g, " ")}`;
    const blockEnd = BLOCK_CLOSERS.has(statement.kind) && isCommentOnly(lowered)
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
      const item = { text: lowered, statement, supported: !lowered.includes("TODO GGCONV") };
      if (pendingHidden.length && statement.kind !== "Write" && lastWriteIndex >= 0) {
        output[lastWriteIndex].text = appendHiddenFields(output[lastWriteIndex].text, pendingHidden);
        pendingHidden = [];
      }
      if (statement.kind === "Write" && pendingHidden.length) {
        item.text = appendHiddenFields(item.text, pendingHidden);
        pendingHidden = [];
      }
      if (statement.kind === "EndLoop" && screenLoops.at(-1)?.guarded) item.text = `${item.text}\nENDIF.`;
      output.push(item);
      if (statement.kind === "Write") lastWriteIndex = output.length - 1;
      if (statement.kind === "Loop") {
        const name = /^LOOP\s+AT\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text.trim())?.[1]?.toUpperCase();
        if (context.selections?.some((selection) => selection.name === name && selection.ranges)) {
          rangeLoops.push([name, `ls_${name.toLowerCase()}_range`]);
        }
      }
      if (statement.kind === "EndLoop") rangeLoops.pop();
      if (statement.kind === "LoopAtScreen") screenLoops.push({ kind: "screen", ...screenBinding, guarded: Boolean(screenStates(statementContext).guard) });
      if (statement.kind === "Loop") screenLoops.push({ kind: "other" });
      if (statement.kind === "EndLoop") screenLoops.pop();
    } else output.push({ text: omitted, statement, supported: false });
  }
  if (pendingHidden.length) output.push({
    text: `* TODO GGCONV-E501: HIDE values had no following WRITE statement.`,
    statement: statements.at(-1),
    supported: false,
  });
  return output;
}

export function selectionType(additions) {
  const match = /\bTYPE\s+([A-Z0-9_\/]+)(?:\s+LENGTH\s+(\d+))?(?:\s+DECIMALS\s+(\d+))?/i.exec(additions ?? "");
  const type = TYPE_CODES.get((match?.[1] ?? "STRING").toUpperCase()) ?? (match?.[1] ?? "STRING").toUpperCase();
  const parts = [`typ = '${type}'`];
  if (match?.[2]) parts.push(`length = ${match[2]}`);
  if (match?.[3]) parts.push(`decimals = ${match[3]}`);
  return `VALUE #( ${parts.join(" ")} )`;
}

export function selectionExpression(value) {
  if (!value) return undefined;
  return /^'.*'$/.test(value) ? value : quote(value);
}
