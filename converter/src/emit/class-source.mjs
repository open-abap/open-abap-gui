import { CONVERTER_VERSION, MANIFEST_SCHEMA_VERSION } from "../options.mjs";
import { controlObjectTypes, lowerStatements, selectionExpression, selectionType } from "../passes/lower-statements.mjs";
import { dynproStatesSetter, routineScreenStates, screenStateMembers, screenStatePlan, selectionStatesSetter, storedScreenStates } from "../passes/screen-states.mjs";
import { scaffoldIR } from "../ir/scaffold-ir.mjs";

const REPORT_METHODS = [
  "load_of_program", "get_logical_database", "get_list_processing", "build_screen", "initialization",
  "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of",
  "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_value_req",
  "at_selection_screen_help_req", "at_selection_screen_on_exit", "start_of_selection", "at_get", "at_get_late",
  "end_of_selection",
];
const LIST_METHODS = ["get_settings", "top_of_page", "end_of_page", "top_of_page_during_line_sel", "at_line_selection", "at_user_command", "at_pf"];

function indent(text, spaces = 2) {
  let level = 0;
  const cases = [];
  let selectDepth = 0;
  const lines = [];
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

function literal(value) {
  return `'${String(value ?? "").replaceAll("'", "''")}'`;
}

function renameIdentifiers(text, renames = {}) {
  let result = "";
  let segment = "";
  let quotedString = false;
  const flush = () => {
    let value = segment;
    for (const [from, to] of Object.entries(renames)) value = value.replace(new RegExp(`\\b${from}\\b`, "gi"), to.toLowerCase());
    result += value;
    segment = "";
  };
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (char === "'" && quotedString && text[index + 1] === "'") {
      result += "''";
      index++;
    } else if (char === "'") {
      flush();
      result += char;
      quotedString = !quotedString;
    } else if (quotedString) result += char;
    else segment += char;
  }
  flush();
  return result;
}

function allRenames(ir) {
  return { ...(ir.statePlan?.renames ?? {}), ...(ir.localClassRenames ?? {}), ...continuationRenames(ir) };
}

function globalMemberNames(ir) {
  const routineStatements = new Set((ir.routines ?? []).flatMap((routine) => routine.statements ?? []));
  const dynproModuleStatements = new Set((ir.modules ?? []).flatMap((module) => module.statements ?? []));
  const global = (item) => !routineStatements.has(item.statement)
    && !dynproModuleStatements.has(item.statement)
    && item.statement?.scope !== "local"
    && !item.statement?.localClassName;
  const result = {};
  for (const declaration of ir.declarations ?? []) {
    if (!global(declaration) || !["data", "static", "tables", "ranges"].includes(declaration.kind)) continue;
    for (const name of declaration.names ?? []) {
      result[name] = ir.statePlan?.renames?.[name] ?? name.toLowerCase();
    }
  }
  return result;
}

function continuationLocalNames(ir) {
  const routineStatements = new Set((ir.routines ?? []).flatMap((routine) => routine.statements ?? []));
  const dynproModuleStatements = new Set((ir.modules ?? []).flatMap((module) => module.statements ?? []));
  const global = (item) => !routineStatements.has(item.statement)
    && !dynproModuleStatements.has(item.statement)
    && item.statement?.scope !== 'local'
    && !item.statement?.localClassName;
  const localDeclarations = (ir.declarations ?? [])
    .filter((item) => !global(item)
      && !item.statement?.localClassName
      && ['data', 'static'].includes(item.kind));
  const declaredBefore = (declaration, continuation) => {
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
  return new Set((ir.continuations ?? [])
    .filter((continuation) => continuation.liveVariables?.length)
    .flatMap((continuation) => (continuation.liveVariables ?? [])
      .filter((name) => localNames.has(name.toUpperCase()))
      .filter((name) => localDeclarations.some((declaration) =>
        (declaration.names ?? []).some((declaredName) => declaredName.toUpperCase() === name.toUpperCase())
          && declaredBefore(declaration, continuation))))
    .map((name) => name.toUpperCase())
  );
}

function continuationRenames(ir) {
  return Object.fromEntries([...continuationLocalNames(ir)].sort().map((name) => [name, `mv_ggconv_${name.toLowerCase()}`]));
}

export function prepareLocalClassNames(ir, options = {}) {
  const target = String(ir.targetClassName ?? "ZCL_CONVERTED").toUpperCase().replace(/[^A-Z0-9_]/g, "_");
  const used = new Set([
    target,
    ...(options.existingClassNames ?? options.existingClasses ?? []).map((name) => String(name).toUpperCase()),
  ]);
  const stem = target.slice(0, 24);
  const renames = {};
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

function method(name, body, comment) {
  const entry = { name, body: body.length ? [...body] : ["RETURN."] };
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

function addWriterDeclaration(body) {
  const declaration = "DATA(lo_writer) = io_session->get_list( )->get_writer( ).";
  const fieldSymbols = [];
  const generatedData = [];
  const rest = [];
  const flatBody = body.flatMap((line) => String(line).split("\n"));
  for (const line of flatBody) {
    if (/^\s*FIELD-SYMBOLS\b/i.test(line)) fieldSymbols.push(line);
    else if (/^\s*DATA\s+lv_ggconv_dynamic_name\s+TYPE\s+string\.\s*$/i.test(line)) generatedData.push(line);
    else if (line.trim() !== declaration) rest.push(line);
  }
  const unique = (items) => [...new Set(items)];
  const fields = unique(fieldSymbols);
  const data = unique(generatedData);
  if (!fields.length && !data.length) return body.some((line) => line.trim() === declaration) ? body : [declaration, ...body];
  return [...fields, ...data, declaration, ...rest];
}

// The program in the transaction metadata lets SUBMIT find the class through
// the transaction registry, whatever the class is called.
function programField(ir) {
  return ir.programName ? ` program = '${ir.programName}'` : "";
}

function interfaceOrder(ir) {
  const order = ["zif_gg_report_v1", "zif_gg_screen_provider_v1", "zif_gg_dynpro_v1", "zif_gg_context_menu_v1", "zif_gg_transaction_v1", "zif_gg_list_processing_v1", "zif_gg_resumable_v1"];
  return order.filter((name) => ir.interfaces.includes(name));
}

function contextMenuRoutine(ir) {
  return (ir.routines ?? []).find((routine) => /^ON_CTMENU(?:_|$)/i.test(String(routine.name ?? "")));
}

function header({ className, ir, options }) {
  return [
    `* Generated by open-abap-gui converter ${options.converterVersion ?? CONVERTER_VERSION}.`,
    `* Source object: ${ir.programName ?? "UNKNOWN"}`,
    `* Source file: ${ir.source.filename}`,
    `* Source SHA-256: ${ir.source.sourceHash}`,
    `* Target class: ${className}`,
    `* Manifest schema: ${MANIFEST_SCHEMA_VERSION}`,
    "* This file is generated migration output; it is safe to edit after review.",
    "",
  ].join("\n");
}

function implicitSelectionLayoutMembers(ir) {
  const names = new Set();
  for (const screen of ir.selections ?? []) {
    for (const match of String(screen.additions ?? "").matchAll(/\bTITLE\s+([A-Z][A-Z0-9_]*)/gi)) {
      names.add(match[1].toUpperCase());
    }
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
function reportMember(ir, base) {
  const tables = (ir.declarations ?? []).find((item) => item.kind === "tables" && item.names?.includes(base));
  if (tables && !tables.resolved) return undefined;
  return ir.statePlan?.selectionState?.[base]?.member
    ?? ir.statePlan?.renames?.[base]?.toLowerCase()
    ?? (ir.statePlan?.globals?.includes(base)
      || (ir.declarations ?? []).some((item) => item.kind === "constant" && item.statement?.scope !== "local" && item.names?.includes(base))
      ? base.toLowerCase() : undefined);
}

const SHARED_RANGES = "zif_gg_selection_screen_types=>ty_ranges";

// SELECT-OPTIONS and RANGES ... FOR target get a range table of the target's
// type, so LOW and HIGH compare, convert and pass to typed parameters as in the
// report. A dynamic FOR (name) has no static type and keeps the shared ranges.
function rangeType(ir, target, member = (base) => reportMember(ir, base)) {
  const match = /^([A-Z][A-Z0-9_\/]*)((?:-[A-Z][A-Z0-9_]*)*)$/i.exec(String(target ?? "").trim());
  if (!match) return `TYPE ${SHARED_RANGES}`;
  const resolved = member(match[1].toUpperCase());
  return resolved
    ? `LIKE RANGE OF ${resolved}${match[2].toLowerCase()}`
    : `TYPE RANGE OF ${`${match[1]}${match[2]}`.toLowerCase()}`;
}

function selectOptionTarget(additions) {
  return /^\s*FOR\s+([^\s]+)/i.exec(String(additions ?? ""))?.[1];
}

function selectionStateType(ir, state) {
  if (state.ranges) return rangeType(ir, selectOptionTarget(state.additions));
  const additions = String(state.additions ?? "").replace(/'(?:''|[^'])*'|`(?:``|[^`])*`/g, "''").replace(/,\s*$/, "");
  const oldLength = /^\(\s*(\d+)\s*\)/.exec(additions)?.[1];
  const type = /\bTYPE\s+([A-Z][A-Z0-9_\/]*(?:-[A-Z][A-Z0-9_]*)*)(?:\s+LENGTH\s+(\d+))?(?:\s+DECIMALS\s+(\d+))?/i.exec(additions);
  if (type) {
    const name = type[1].toLowerCase();
    if (!LENGTH_TYPES.has(name)) return `TYPE ${name}`;
    const length = type[2] ?? oldLength;
    return `TYPE ${name}${length ? ` LENGTH ${length}` : ""}${type[3] ? ` DECIMALS ${type[3]}` : ""}`;
  }
  const like = /\bLIKE\s+([A-Z][A-Z0-9_\/]*)((?:-[A-Z][A-Z0-9_]*)*)/i.exec(additions);
  if (like) {
    const member = reportMember(ir, like[1].toUpperCase());
    return member ? `LIKE ${member}${like[2].toLowerCase()}` : `TYPE ${`${like[1]}${like[2]}`.toLowerCase()}`;
  }
  // PARAMETERS without a type is c of length 8; a checkbox or radio button is c of length 1.
  if (/\b(?:AS\s+CHECKBOX|RADIOBUTTON\s+GROUP)\b/i.test(additions)) return "TYPE c LENGTH 1";
  return `TYPE c LENGTH ${oldLength ?? 8}`;
}

// Re-emits a BEGIN OF ... END OF structure as one chain. INCLUDE TYPE and
// INCLUDE STRUCTURE are statements of their own, so they break the chain.
function structuredDeclaration(keyword, beginName, components, endName) {
  const statements = [];
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

function dataMembers(ir) {
  const typeMembers = [];
  const constantMembers = [];
  const dataMembers = [];
  const declarations = ir.declarations ?? [];
  const routineStatements = new Set(ir.routines.flatMap((routine) => routine.statements));
  const dynproModuleStatements = new Set((ir.modules ?? []).flatMap((module) => module.statements ?? []));
  const consumed = new Set();
  const global = (item) => !routineStatements.has(item.statement)
    && !dynproModuleStatements.has(item.statement)
    && item.statement?.scope !== "local"
    && !item.statement?.localClassName;
  const rename = (text) => renameIdentifiers(text, allRenames(ir));
  const addStructured = (index, begin, end, keyword, target) => {
    const components = [];
    for (let cursor = index + 1; cursor < declarations.length; cursor++) {
      consumed.add(cursor);
      if (declarations[cursor].kind === begin || declarations[cursor].kind === "includetype") {
        // A component ends in "," inside a chain and in "." where the chain was
        // broken, e.g. before INCLUDE TYPE; the structure is re-emitted as one
        // chain, so the terminator is replaced by a comma.
        const component = declarations[cursor].raw.replace(new RegExp(`^${keyword}\\s+`, "i"), "").replace(/\s*[,.]\s*$/, "");
        if (component) components.push(rename(component));
      }
      if (declarations[cursor].kind === end) {
        const endName = /END OF\s+([A-Z0-9_]+)/i.exec(declarations[cursor].raw)?.[1] ?? target;
        const declaration = structuredDeclaration(keyword, target, components, endName);
        (keyword === "TYPES" ? typeMembers : dataMembers).push(rename(declaration));
        break;
      }
    }
    consumed.add(index);
  };
  const rangeMember = (item) => {
    const name = item.names?.[0]?.toLowerCase();
    if (!name) return undefined;
    // RANGES creates a four-column selection range table of the FOR target.
    return `DATA ${name} ${rangeType(ir, item.target)}.`;
  };
  for (let index = 0; index < declarations.length; index++) {
    const item = declarations[index];
    if (!global(item) || consumed.has(index)) continue;
    if (item.kind === "databegin" || item.kind === "typebegin") {
      const begin = /BEGIN OF\s+([A-Z0-9_]+)/i.exec(item.raw)?.[1];
      const keyword = item.kind === "typebegin" ? "TYPES" : "DATA";
      addStructured(index, item.kind === "typebegin" ? "type" : "data", item.kind === "typebegin" ? "typeend" : "dataend", keyword, begin);
    } else if (item.kind === "type" && !item.complex) {
      typeMembers.push(rename(item.raw.replace(/,\s*$/, ".")));
    } else if (item.kind === "constant" && !item.complex) {
      constantMembers.push(rename(item.raw.replace(/,\s*$/, ".")));
    } else if ((item.kind === "data" || item.kind === "static") && !item.complex) {
      const declarationRaw = item.raw.replace(/,\s*$/, ".");
      const declaration = item.kind === "static"
        ? declarationRaw.replace(/^STATICS\b/i, "DATA")
        : declarationRaw;
      dataMembers.push(rename(declaration));
    } else if (item.kind === "tables" && item.resolved && !item.complex) {
      dataMembers.push(rename(`DATA ${item.names?.[0]?.toLowerCase()} TYPE ${item.type}.`));
    } else if (item.kind === "ranges") {
      const declaration = rangeMember(item);
      if (declaration) dataMembers.push(rename(declaration));
    }
  }
  const eventReferences = new Map();
  for (const [event, statements] of Object.entries(ir.events ?? {})) {
    for (const declaration of declarations) {
      if (!global(declaration)) continue;
      const name = declaration.names?.[0]?.toUpperCase();
      if (!name || !["data", "static"].includes(declaration.kind)) continue;
      if (statements.some((statement) => statement === declaration.statement || new RegExp(`\\b${name}\\b`, "i").test(statement.text ?? ""))) {
        const events = eventReferences.get(name) ?? new Set();
        events.add(event);
        eventReferences.set(name, events);
      }
    }
  }
  const emittedNames = new Set(dataMembers.flatMap((member) => [...member.matchAll(/^DATA\s+([A-Z][A-Z0-9_]*)/gim)].map((match) => match[1].toUpperCase())));
  for (const declaration of declarations) {
    const name = declaration.names?.[0]?.toUpperCase();
    if (!name || emittedNames.has(name) || !["data", "static"].includes(declaration.kind) || (eventReferences.get(name)?.size ?? 0) < 2) continue;
    dataMembers.push(rename(declaration.raw.replace(/,\s*$/, ".")));
    emittedNames.add(name);
  }
  for (const name of continuationLocalNames(ir)) {
    const declaration = declarations.find((item) => ['data', 'static'].includes(item.kind)
      && (item.names ?? []).some((itemName) => itemName.toUpperCase() === name));
    if (!declaration || declaration.complex) continue;
    const raw = declaration.kind === 'static'
      ? declaration.raw.replace(/^STATICS\b/i, 'DATA')
      : declaration.raw;
    dataMembers.push(rename(raw.replace(/,\s*$/, '.')));
  }
  const declaredNames = new Set((declarations ?? []).flatMap((item) => item.names ?? []).map((name) => name.toUpperCase()));
  for (const name of implicitSelectionLayoutMembers(ir)) {
    if (!declaredNames.has(name)) dataMembers.push(`DATA ${name.toLowerCase()} TYPE string.`);
  }
  if ((ir.selections ?? []).some((screen) => screen.elements?.some((item) => item.layout === "begin_tabbed_block"))) {
    dataMembers.push("DATA mv_active_tab TYPE string.");
  }
  const dynamicTypes = ir.dynamicAlv
    ? [
      `TYPES: BEGIN OF ${ir.dynamicAlv.rowType},`,
      ...ir.dynamicAlv.typeFields.map((field) => `         ${field.name.toLowerCase()} TYPE ${field.type},`),
      `       END OF ${ir.dynamicAlv.rowType}.`,
      `TYPES ${ir.dynamicAlv.tableType} TYPE STANDARD TABLE OF ${ir.dynamicAlv.rowType} WITH EMPTY KEY.`,
    ]
    : [];
  const members = [...typeMembers, ...dynamicTypes, ...constantMembers, ...dataMembers, ...screenStateMembers(ir)];
  if (ir.dynamicAlv) members.push(`DATA ${ir.dynamicAlv.tableMember.toLowerCase()} TYPE ${ir.dynamicAlv.tableType}.`);
  for (const statement of ir.statements ?? []) {
    if (statement.kind !== "Controls") continue;
    const controls = /^CONTROLS\s+([A-Z][A-Z0-9_]*)\s+TYPE\s+(TABLEVIEW|TABSTRIP)\b/i.exec(statement.text ?? "");
    if (!controls) continue;
    const type = controls[2].toUpperCase() === "TABSTRIP" ? "ty_tabstrip_runtime" : "ty_table_runtime";
    members.push(`DATA ${controls[1].toLowerCase()} TYPE zif_gg_dynpro_types_v1=>${type}.`);
  }
  // `LIKE` can only name an attribute declared earlier, so a parameter declared
  // LIKE another parameter comes after it.
  const selectionState = ir.statePlan?.selectionState ?? {};
  const emitted = new Set();
  const emitSelection = (name) => {
    if (emitted.has(name)) return;
    emitted.add(name);
    const state = selectionState[name];
    const like = /\b(?:LIKE|FOR)\s+([A-Z][A-Z0-9_\/]*)/i.exec(String(state.additions ?? ""))?.[1]?.toUpperCase();
    if (like && selectionState[like]) emitSelection(like);
    members.push(`DATA ${state.member} ${selectionStateType(ir, state)}.`);
  };
  Object.keys(selectionState).forEach(emitSelection);
  for (const routine of ir.routines) {
    const parameters = routine.parameters ?? [];
    const parameterType = (parameter) => {
      if (/^SY-UCOMM$/i.test(String(parameter.type ?? ""))) return "zif_gg_session_types_v1=>ty_ucomm";
      if (/^SY(?:-SUBRC)?$/i.test(String(parameter.type ?? ""))) return "i";
      return parameter.type;
    };
    const lines = [`METHODS ${routine.methodName}`];
    const importing = parameters.filter((parameter) => parameter.direction === "IMPORTING");
    const width = Math.max("io_session".length, ...parameters.map((parameter) => parameter.name.length));
    lines.push("  IMPORTING", `    io_session${" ".repeat(width - "io_session".length)} TYPE REF TO zif_gg_session_v1`);
    lines.push(...importing.map((parameter) => `    ${parameter.name}${" ".repeat(width - parameter.name.length)} TYPE ${parameterType(parameter)}`));
    for (const direction of ["CHANGING"]) {
      const items = parameters.filter((parameter) => parameter.direction === direction);
      if (!items.length) continue;
      lines.push(`  ${direction}`, ...items.map((parameter) => `    ${parameter.name}${" ".repeat(width - parameter.name.length)} TYPE ${parameterType(parameter)}`));
    }
    lines[lines.length - 1] = `${lines.at(-1)}.`;
    members.push(lines.join("\n"));
  }
  return members;
}

function selectionDataType(item) {
  if (!item.dataType?.typ) return selectionType(item.additions);
  const fields = [];
  if (item.dataType.rollname) fields.push(`rollname = '${item.dataType.rollname}'`);
  fields.push(`typ = '${item.dataType.typ}'`);
  if (item.dataType.length !== undefined) fields.push(`length = ${item.dataType.length}`);
  if (item.dataType.decimals !== undefined) fields.push(`decimals = ${item.dataType.decimals}`);
  return `VALUE #( ${fields.join(" ")} )`;
}

function selectionDefault(item) {
  const value = item.default;
  if (!value) return undefined;
  if (/^'(?:''|[^'])*'$|^\|[^|]*\|$/s.test(value)) return value;
  return `CONV string( ${value} )`;
}

function decodeAbapLiteral(value) {
  return String(value ?? "").replace(/^'/, "").replace(/'$/, "").replaceAll("''", "'");
}

function staticSelectionText(ir, token) {
  const key = String(token ?? "").trim().toUpperCase();
  if (!key || /^'.*'$/.test(key) || key.startsWith("@ICON:")) return token;
  const values = new Map();
  for (const statement of ir.events?.initialization ?? []) {
    const write = /^WRITE\s+([A-Z][A-Z0-9_]*)\s+AS\s+ICON\s+TO\s+([A-Z][A-Z0-9_]*)\.?$/i.exec(statement.text?.trim() ?? "");
    if (write) {
      values.set(write[2].toUpperCase(), `@ICON:${write[1].toLowerCase().replace(/^icon_/, "")}`);
      continue;
    }
    const move = /^([A-Z][A-Z0-9_]*)(?:\+(\d+))?\s*=\s*('(?:''|[^'])*')\.?$/i.exec(statement.text?.trim() ?? "");
    if (!move) continue;
    const name = move[1].toUpperCase();
    const value = decodeAbapLiteral(move[3]);
    if (move[2] === undefined) {
      values.set(name, value);
      continue;
    }
    const offset = Number(move[2]);
    const previous = values.get(name) ?? "";
    if (previous.startsWith("@ICON:")) values.set(name, `${previous}${value}`);
    else values.set(name, `${previous.slice(0, offset).padEnd(offset, " ")}${value}`);
  }
  return values.get(key) ?? token;
}

function hasSelectionValueRequest(ir, name) {
  const target = String(name ?? "").toUpperCase();
  if (!target) return false;
  const qualifiers = [
    ir.eventQualifiers?.at_selection_screen_value_req,
    ...(ir.eventBlocks ?? [])
      .filter((block) => block.event === "at_selection_screen_value_req")
      .map((block) => block.qualifier),
  ];
  return qualifiers.some((qualifier) => new RegExp(`AT\\s+SELECTION-SCREEN\\s+ON\\s+VALUE-REQUEST\\s+FOR\\s+${target}\\b`, "i").test(String(qualifier ?? "")));
}

function selectionBuilder(ir) {
  const lines = [];
  for (const screen of ir.selections) {
    if (screen.number !== "0100" || screen.asWindow || screen.asSubscreen) {
      lines.push(`io_builder->begin_screen( VALUE #( number = '${screen.number}'${screen.asWindow ? " as_window = abap_true" : ""}${screen.asSubscreen ? " as_subscreen = abap_true" : ""} ) ).`);
    }
    for (const item of screen.elements) {
      if (item.kind === "layout") {
        if (item.layout === "comment") {
          const fields = [`name = '${item.name}'`, `text = ${literal(staticSelectionText(ir, item.text))}`];
          if (item.position !== undefined) fields.push(`position = ${item.position}`);
          if (item.length !== undefined) fields.push(`visible_length = ${item.length}`);
          lines.push(`io_builder->add_comment( VALUE #( ${fields.join(" ")} ) ).`);
        } else if (item.layout === "skip") lines.push(`io_builder->add_skip( ${item.lines} ).`);
        else if (item.layout === "uline") lines.push(`io_builder->add_uline( VALUE #( ${item.position !== undefined ? `position = ${item.position}` : ""}${item.length !== undefined ? ` length = ${item.length}` : ""} ) ).`);
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
      if (item.kind === "parameter") {
        const additions = item.additions ?? "";
        const type = `data_type = ${selectionDataType(item)}`;
        if (/AS\s+CHECKBOX/i.test(additions)) {
          const ucomm = /USER-COMMAND\s+(\w+)/i.exec(additions)?.[1];
          const modif = /MODIF\s+ID\s+(\w+)/i.exec(additions)?.[1];
          const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`];
          if (/DEFAULT\s+(?:['"]?X|ABAP_TRUE)\b/i.test(additions)) fields.push("default = abap_true");
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          if (ucomm) fields.push(`ucomm = '${ucomm.toUpperCase()}'`);
          lines.push(`io_builder->add_checkbox( VALUE #( ${fields.join(" ")} ) ).`);
        } else if (/RADIOBUTTON\s+GROUP\s+(\w+)/i.test(additions)) {
          const group = /RADIOBUTTON\s+GROUP\s+(\w+)/i.exec(additions)[1].toUpperCase();
          const ucomm = /USER-COMMAND\s+(\w+)/i.exec(additions)?.[1];
          const defaultValue = /DEFAULT\s+(?:['"]?X|ABAP_TRUE)\b/i.test(additions) ? " default = abap_true" : "";
          lines.push(`io_builder->add_radiobutton( VALUE #( name = '${item.name}' text = ${literal(item.text ?? item.name)} radio_group = '${group}'${defaultValue}${ucomm ? ` ucomm = '${ucomm.toUpperCase()}'` : ""} ) ).`);
        } else if (/AS\s+LISTBOX/i.test(additions)) {
          const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`, type];
          const visibleLength = /VISIBLE\s+LENGTH\s+(\d+)/i.exec(additions)?.[1];
          if (visibleLength) fields[2] = type.replace(/\s\)$/, ` visible_length = ${visibleLength} )`);
          const defaultValue = selectionDefault(item);
          if (defaultValue) fields.push(`default = ${defaultValue}`);
          const ucomm = /USER-COMMAND\s+(\w+)/i.exec(additions)?.[1];
          if (ucomm) fields.push(`ucomm = '${ucomm.toUpperCase()}'`);
          if (item.fixedValues?.length) fields.push(`fixed_values = VALUE #( ${item.fixedValues.map((fixed) => `( key = ${literal(fixed.key ?? fixed.value ?? "")} text = ${literal(fixed.text ?? fixed.label ?? fixed.key ?? "")} )`).join(" ")} )`);
          lines.push(`io_builder->add_listbox( VALUE #( ${fields.join(" ")} ) ).`);
        } else {
          const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`, type];
          const defaultValue = selectionDefault(item);
          if (defaultValue) fields.push(`default = ${defaultValue}`);
          const modif = /MODIF\s+ID\s+(\w+)/i.exec(additions)?.[1];
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          const memoryId = /MEMORY\s+ID\s+(\w+)/i.exec(additions)?.[1];
          if (memoryId) fields.push(`memory_id = '${memoryId.toUpperCase()}'`);
          const searchHelp = /MATCHCODE\s+OBJECT\s+(\w+)/i.exec(additions)?.[1];
          if (searchHelp) fields.push(`search_help = '${searchHelp.toUpperCase()}'`);
          if (searchHelp || hasSelectionValueRequest(ir, item.name)) fields.push("value_help = abap_true");
          if (/OBLIGATORY/i.test(additions)) fields.push("obligatory = abap_true");
          if (/LOWER\s+CASE/i.test(additions)) fields.push("lower_case = abap_true");
          if (/NO-DISPLAY/i.test(additions)) fields.push("no_display = abap_true");
          lines.push(`io_builder->add_parameter( VALUE #( ${fields.join(" ")} ) ).`);
        }
      } else if (item.kind === "select-option") {
        const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`, `data_type = ${selectionDataType(item)}`];
        if (/NO[\s-]+EXTENSION/i.test(item.additions)) fields.push("no_extension = abap_true");
        if (/NO[\s-]+INTERVALS/i.test(item.additions)) fields.push("no_intervals = abap_true");
        if (hasSelectionValueRequest(ir, item.name)) fields.push("value_help = abap_true");
        if (/OBLIGATORY/i.test(item.additions)) fields.push("obligatory = abap_true");
        const defaultMatch = /DEFAULT\s+([^\s,]+)(?:\s+TO\s+([^\s,]+))?/i.exec(item.additions);
        if (defaultMatch) fields.push(`default = VALUE #( sign = 'I' option = '${defaultMatch[2] ? "BT" : "EQ"}' low = ${selectionExpression(defaultMatch[1])}${defaultMatch[2] ? ` high = ${selectionExpression(defaultMatch[2])}` : ""} )`);
        lines.push(`io_builder->add_select_option( VALUE #( ${fields.join(" ")} ) ).`);
      }
    }
    if (screen.number !== "0100" || screen.asWindow || screen.asSubscreen) lines.push("io_builder->end_screen( ).");
  }
  return lines;
}

function methodContext(ir, event, qualifierOverride, {parameters = [], statements = ir.statements ?? []} = {}) {
  const mutable = ["initialization", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_output"].includes(event);
  const values = ir.selections
    .flatMap((screen) => screen.elements.map((item) => ({ ...item, screen: screen.number })))
    .filter((item) => item.name && ["parameter", "select-option"].includes(item.kind))
    .map((item) => ({ name: item.name, ranges: item.kind === "select-option", screen: item.screen }));
  const dynamicWriteTargets = [];
  const dynamicTargetNames = new Set();
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
  const activeCommands = (ir.events?.at_user_command ?? []).flatMap((statement) => [...statement.text.matchAll(/(?:WHEN|=)\s*'([^']+)'/gi)].map((match) => match[1].toUpperCase()));
  const activePFKeys = (ir.eventBlocks ?? [])
    .filter((block) => block.event === "at_pf")
    .map((block) => /AT\s+PF\s*0*(\d+)/i.exec(block.qualifier ?? "")?.[1])
    .filter(Boolean)
    .map(Number);
  const valueReference = (item) => ir.statePlan?.selectionState?.[item.name]?.member ?? `${mutable ? "ct_values" : "it_values"}[ name = '${item.name}' ]-${item.ranges ? "ranges" : "value"}`;
  const valueReplacements = values.flatMap((item) => {
    const reference = valueReference(item);
    const fields = item.ranges
      ? [[`${item.name}-low`, `${reference}[ 1 ]-low`], [`${item.name}-high`, `${reference}[ 1 ]-high`]]
      : [];
    return [...fields, [item.name, reference]];
  });
  return {
    event,
    selections: values,
    mutableValues: mutable,
    ucomm: event.startsWith("at_selection_screen") || event === "at_user_command" ? "iv_ucomm" : undefined,
    replacements: [
      ...Object.entries(ir.statePlan?.renames ?? {}),
      ...Object.entries(ir.localClassRenames ?? {}).map(([name, value]) => [name, String(value).toLowerCase()]),
      ...Object.entries(continuationRenames(ir)),
      ...valueReplacements,
      ...(event === "at_line_selection" || event === "at_user_command" || event === "at_pf"
        ? (ir.hiddenNames ?? []).map((name) => [name, `is_line-fields[ name = '${name}' ]-value`])
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
        .filter((statement) => /^\s*CLASS-METHODS\b/i.test(statement.text ?? "") && !isStaticEventHandler(statement.text))
        .map((statement) => /^\s*CLASS-METHODS\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text)?.[1]?.toUpperCase())
        .filter(Boolean)),
    ])),
    localClassStaticEventHandlers: Object.fromEntries((ir.localClasses ?? []).map((localClass) => [
      String(localClass.name ?? "").toUpperCase(),
      staticEventHandlerNames(localClass),
    ])),
    localClassStaticParameters: Object.fromEntries((ir.localClasses ?? []).map((localClass) => [
      String(localClass.name ?? "").toUpperCase(),
      Object.fromEntries((localClass.definition ?? [])
        .filter((statement) => !isStaticEventHandler(statement.text))
        .map((statement) => {
          const match = /^\s*CLASS-METHODS\s+([A-Z][A-Z0-9_]*)\b([\s\S]*)$/i.exec(statement.text ?? "");
          if (!match) return undefined;
          const parameter = /\bIMPORTING\s+([A-Z][A-Z0-9_]*)\b/i.exec(match[2])?.[1]?.toUpperCase();
          return parameter ? [match[1].toUpperCase(), parameter] : undefined;
        })
        .filter(Boolean)),
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
    dynamicAlv: ir.dynamicAlv,
    rangeDeclarations: Object.fromEntries((ir.declarations ?? [])
      .filter((declaration) => declaration.kind === "ranges")
      .flatMap((declaration) => (declaration.names ?? []).map((name) => [name.toUpperCase(), rangeType(ir, declaration.target, (base) => {
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

function globalFieldSymbolDeclarations(ir, statements) {
  const source = statements ?? [];
  return (ir.declarations ?? [])
    .filter((declaration) => declaration.kind === "field-symbol"
      && declaration.statement?.scope !== "local"
      && (!ir.dynamicAlv || !declaration.names?.some((name) => String(name).toUpperCase() === ir.dynamicAlv.tableSymbol))
      && (declaration.names ?? []).some((name) => ir.safeFieldSymbols?.includes(name.toUpperCase()))
      && (declaration.names ?? []).some((name) => source.some((statement) => new RegExp(`<${name}>`, "i").test(statement.text))))
    .map((declaration) => {
      if (!ir.dynamicAlv) return declaration.raw;
      const model = ir.dynamicAlv;
      const names = new Set((declaration.names ?? []).map((name) => String(name).toUpperCase()));
      if (!names.has(model.tableSymbol)) return declaration.raw;
      return declaration.raw.replace(/\bTYPE\s+(?:STANDARD\s+)?TABLE\b/i, `TYPE ${model.tableType}`);
    });
}

function selectionStateTransport(ir, event) {
  const state = ir.statePlan?.selectionState ?? {};
  const values = ["initialization", "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_on_exit", "start_of_selection", "end_of_selection"].includes(event);
  if (!values) return { hydrate: [], flush: [] };
  const source = ["initialization", "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio"].includes(event) ? "ct_values" : "it_values";
  const hydrate = [];
  const flush = [];
  for (const [name, item] of Object.entries(state)) {
    const field = `${source}[ name = '${name}' ]-${item.ranges ? "ranges" : "value"}`;
    // A select-option member is a range table of its own type; the screen
    // transports LOW and HIGH as strings, CORRESPONDING converts each row.
    hydrate.push(item.ranges ? `${item.member} = CORRESPONDING #( ${field} ).` : `${item.member} = ${field}.`);
    if (source !== "ct_values") continue;
    if (item.ranges) {
      // As for parameters below, an untouched empty LOW of type i must not
      // come back as "0", so the screen rows are only replaced on a change.
      const screen = `lt_ggconv_${name.toLowerCase()}`;
      flush.push([
        `DATA(${screen}) = ${item.member}.`,
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
  return { hydrate, flush };
}

function nestedSelectionCaptures(ir) {
  const fields = ir.selections
    .filter((screen) => screen.number !== "0100")
    .flatMap((screen) => screen.elements
      .filter((item) => item.kind === "parameter" || item.kind === "select-option")
      .map((item) => ({ screen: screen.number, ...item })));
  if (!fields.length) return [];
  const lines = [];
  let current;
  for (const field of fields) {
    if (field.screen !== current) {
      if (current) lines.push("ENDIF.");
      current = field.screen;
      lines.push(`IF iv_screen = '${current}'.`);
    }
    const ranges = ir.statePlan?.selectionState?.[field.name]?.ranges ?? field.ranges;
    lines.push(ranges
      ? `mv_${field.name.toLowerCase()} = CORRESPONDING #( ct_values[ name = '${field.name}' ]-ranges ).`
      : `mv_${field.name.toLowerCase()} = ct_values[ name = '${field.name}' ]-value.`);
  }
  if (current) lines.push("ENDIF.");
  return lines;
}

const CONTROL_CLOSERS = new Map([
  ["If", "ENDIF."],
  ["Do", "ENDDO."],
  ["Loop", "ENDLOOP."],
  ["Case", "ENDCASE."],
  ["Try", "ENDTRY."],
  ["While", "ENDWHILE."],
]);

function isSuspendingStatement(statement) {
  if (["CallScreen", "CallSelectionScreen", "CallTransaction"].includes(statement.kind)) return true;
  return statement.kind === "Submit" && /\bAND\s+RETURN\b/i.test(statement.text);
}

function continuationFor(ir, statement) {
  return ir.continuations?.find((item) => item.filename === statement.filename
    && item.span.start.line === statement.span.start.line
    && item.span.start.column === statement.span.start.column);
}

function removePromotedDeclarations(ir, lines) {
  const promoted = new Set([...continuationLocalNames(ir)].map((name) => continuationRenames(ir)[name].toLowerCase()));
  if (!promoted.size) return lines;
  return lines.flatMap((line) => String(line).split('\n'))
    .filter((line) => ![...promoted].some((name) => new RegExp(`^\\s*DATA\\s+${name}\\b`, 'i').test(line)));
}

function continuationClosers(continuation) {
  return [...(continuation?.controlStack ?? [])]
    .reverse()
    .map((item) => CONTROL_CLOSERS.get(item.kind))
    .filter(Boolean);
}

function isBranchStatement(statement) {
  return ["Else", "ElseIf", "When", "WhenOthers", "Catch", "Cleanup"].includes(statement.kind);
}

function openerForCloser(kind) {
  for (const [opener, closer] of [["If", "EndIf"], ["Do", "EndDo"], ["Loop", "EndLoop"], ["Case", "EndCase"], ["Try", "EndTry"], ["While", "EndWhile"]]) {
    if (closer === kind) return opener;
  }
  return undefined;
}

// A continuation resumes after the host has unwound the original ABAP call
// stack. Conditional blocks therefore need a small amount of structural
// normalization: close tokens belonging to the pre-suspension path are
// removed, and sibling ELSE/WHEN branches are skipped. New control-flow that
// starts after the suspension remains ordinary ABAP and is preserved.
function resumeTail(statements, index, continuation) {
  const runtimeStack = (continuation?.controlStack ?? []).map((item) => ({ ...item, original: true }));
  const output = [];
  let skipped;
  let skippedDepth = 0;
  for (let cursor = index + 1; cursor < statements.length; cursor++) {
    const statement = statements[cursor];
    const kind = statement.kind;
    if (skipped) {
      if (runtimeStack.length && ["If", "Do", "Loop", "Case", "Try", "While"].includes(kind)) skippedDepth++;
      const closer = openerForCloser(kind);
      if (closer) {
        if (skippedDepth > 0) skippedDepth--;
        else if (closer === skipped.kind) {
          runtimeStack.pop();
          skipped = undefined;
        }
      }
      continue;
    }

    if (isBranchStatement(statement) && runtimeStack.at(-1)?.original) {
      skipped = runtimeStack.at(-1);
      skippedDepth = 0;
      continue;
    }
    const closer = openerForCloser(kind);
    if (closer && runtimeStack.at(-1)?.original && runtimeStack.at(-1).kind === closer) {
      runtimeStack.pop();
      continue;
    }
    if (["If", "Do", "Loop", "Case", "Try", "While"].includes(kind)) {
      runtimeStack.push({ kind, original: false });
      output.push(statement);
      continue;
    }
    if (closer && runtimeStack.at(-1)?.original === false && runtimeStack.at(-1).kind === closer) {
      runtimeStack.pop();
      output.push(statement);
      continue;
    }
    output.push(statement);
  }
  return output;
}

function suspensionIndex(statements) {
  return statements.findIndex((statement) => isSuspendingStatement(statement));
}

function terminalIndex(statements) {
  let depth = 0;
  for (let index = 0; index < statements.length; index++) {
    const statement = statements[index];
    if (["If", "Do", "Loop", "Case", "Try", "While"].includes(statement.kind)) depth++;
    if (["EndIf", "EndDo", "EndLoop", "EndCase", "EndTry", "EndWhile"].includes(statement.kind)) depth = Math.max(0, depth - 1);
    if (isTerminal(statement) && depth === 0) return index;
  }
  return -1;
}

function isTerminal(statement) {
  return statement.kind === "Stop" || statement.kind === "Submit" && !/\bAND\s+RETURN\b/i.test(statement.text)
    || statement.kind === "Leave" && /\b(LEAVE\s+PROGRAM|LEAVE\s+TO\s+TRANSACTION|LEAVE\s+LIST-PROCESSING)\b/i.test(statement.text);
}

function truncateTerminalPaths(statements) {
  const output = [];
  let depth = 0;
  let skipping = false;
  let branchDepth = 0;
  for (const statement of statements) {
    const opens = ["If", "Do", "Loop", "Case", "Try", "While"].includes(statement.kind);
    const closes = ["EndIf", "EndDo", "EndLoop", "EndCase", "EndTry", "EndWhile"].includes(statement.kind);
    const branch = ["Else", "When", "WhenOthers"].includes(statement.kind);
    if (skipping) {
      if (opens) depth++;
      if (closes) {
        depth--;
        if (depth === branchDepth) skipping = false;
        output.push(statement);
      } else if (branch && depth === branchDepth) {
        skipping = false;
        output.push(statement);
      }
      continue;
    }
    output.push(statement);
    if (opens) depth++;
    if (closes) depth = Math.max(0, depth - 1);
    if (isTerminal(statement)) {
      if (depth === 0) return output;
      skipping = true;
      branchDepth = depth;
    }
  }
  return output;
}

function eventBody(ir, event, sourceStatements = ir.events[event] ?? [], qualifierOverride) {
  const statements = truncateTerminalPaths(sourceStatements);
  const context = methodContext(ir, event, qualifierOverride, {statements: sourceStatements});
  context.screenStates = event === "at_selection_screen_output"
    ? { kind: "selection", table: "ct_states" }
    : storedScreenStates(screenStatePlan(ir).defaultKind);
  if (event === "at_selection_screen_value_req") {
    const f4Call = statements.find((statement) => statement.kind === "CallFunction" && /F4IF_INT_TABLE_VALUE_REQUEST/i.test(statement.text));
    if (f4Call) {
      const literalValues = statements
        .flatMap((statement) => [...String(statement.text ?? "").matchAll(/\bcity\s*=\s*('(?:''|[^'])*')/gi)].map((match) => match[1]))
        .filter((value, index, values) => values.indexOf(value) === index);
      if (literalValues.length) {
        return {
          body: [`rt_values = VALUE #( ${literalValues.map((value) => `( sign = zif_gg_selection_screen_types=>sign_include option = zif_gg_selection_screen_types=>option_eq low = ${value} )`).join(" ")} ).`],
          lowered: [],
        };
      }
    }
    const assignment = statements.find((statement) => statement.kind === "Move");
    const match = assignment && /^([A-Z][A-Z0-9_]*)\s*=\s*(.+)\.$/i.exec(assignment.text.trim());
    if (match) {
      const value = match[2].trim();
      return { body: [`rt_values = VALUE #( ( sign = zif_gg_selection_screen_types=>sign_include option = zif_gg_selection_screen_types=>option_eq low = ${value} ) ).`], lowered: [] };
    }
  }
  if (event === "at_selection_screen_help_req") {
    const write = statements.find((statement) => statement.kind === "Write");
    const match = write && /^WRITE\s+('(?:''|[^'])*')/i.exec(write.text.trim());
    if (match) return { body: [`rv_text = ${match[1]}.`], lowered: [] };
  }
  const index = suspensionIndex(statements);
  const terminal = terminalIndex(statements);
  const end = index >= 0 ? index + 1 : terminal >= 0 ? terminal + 1 : statements.length;
  const activeStatements = statements.slice(0, end);
  const lowered = lowerStatements(activeStatements, context);
  const transport = selectionStateTransport(ir, event);
  const fieldSymbols = globalFieldSymbolDeclarations(ir, activeStatements);
  const continuation = index >= 0 ? continuationFor(ir, statements[index]) : undefined;
  let body = [
    ...fieldSymbols,
    ...transport.hydrate,
    ...removePromotedDeclarations(ir, lowered.map((item) => item.text)),
    ...continuationClosers(continuation),
    ...transport.flush,
  ];
  const hasWriter = body.some((line) => line.includes("lo_writer->"));
  if (hasWriter) body = addWriterDeclaration(body);
  if (event === "start_of_selection" && context.activePFKeys?.length && !statements.some((statement) => statement.kind === "SetPFStatus")) {
    body.unshift(`io_session->get_list( )->set_status( VALUE #( status = 'LIST' active_pf_keys = VALUE #( ${context.activePFKeys.map((key) => `( ${key} )`).join(" ")} ) ) ).`);
  }
  if (event === "start_of_selection" && body.length) body.unshift(`io_session->get_list( )->set_title( ${literal(ir.reportTitle ?? ir.targetClassName)} ).`);
  if (hasWriter) body = addWriterDeclaration(body);
  return { body, lowered, suspension: index >= 0 ? { statement: statements[index], tail: statements.slice(index + 1) } : undefined };
}

function qualifierGuard(ir, event, body, qualifierOverride) {
  const qualifier = qualifierOverride ?? ir.eventQualifiers?.[event];
  if (!qualifier || !body.length) return body;
  const upper = qualifier.toUpperCase();
  let condition;
  const field = /ON\s+VALUE-REQUEST\s+FOR\s+(\w+)/i.exec(qualifier)?.[1] ?? /ON\s+HELP-REQUEST\s+FOR\s+(\w+)/i.exec(qualifier)?.[1] ?? /ON\s+(\w+)\s*\./i.exec(qualifier)?.[1];
  if (field && (event.includes("field") || event.includes("value_req") || event.includes("help_req"))) condition = `iv_name = '${field.toUpperCase()}'`;
  const block = /ON\s+BLOCK\s+(\w+)/i.exec(upper)?.[1];
  if (block) condition = `iv_block = '${block}'`;
  const group = /RADIOBUTTON\s+GROUP\s+(\w+)/i.exec(upper)?.[1];
  if (group) condition = `iv_group = '${group}'`;
  const pf = /AT\s+PF\s*0*(\d+)/i.exec(upper)?.[1];
  if (event === "at_pf" && pf) condition = `iv_key = ${Number(pf)}`;
  if (!condition) return body;
  const definitions = body.filter((line) => /^(?:DATA\(|FIELD-SYMBOLS\b|TYPES\b|CONSTANTS\b)/i.test(line.trim()));
  const executable = body.filter((line) => !definitions.includes(line));
  let guarded;
  if (executable.length >= 2 && /^IF\s+.+\.$/i.test(executable[0]) && executable.at(-1).toUpperCase() === "ENDIF.") {
    const inner = executable[0].replace(/^IF\s+/i, "").replace(/\.$/, "");
    guarded = [`IF ${condition} AND ${inner}.`, ...executable.slice(1, -1), "ENDIF."];
  } else {
    guarded = [`IF ${condition}.`, ...executable, "ENDIF."];
  }
  return [...definitions, ...guarded];
}

function reportMethods(ir) {
  const methods = [];
  const bodiesFor = (event) => {
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
      if (event === "load_of_program" && ir.reportTitle) {
        body.unshift(`io_session->get_list( )->set_title( ${literal(ir.reportTitle ?? ir.targetClassName)} ).`);
      }
      if (event === "at_selection_screen" && ir.continuations?.length) body.push(...nestedSelectionCaptures(ir));
      if (event === "at_selection_screen_output") body.unshift(...selectionStatesSetter(ir));
      methods.push(method(`zif_gg_report_v1~${event}`, body));
    }
  }
  return methods;
}

function listMethods(ir) {
  const methods = [];
  const bodiesFor = (event) => {
    const blocks = ir.eventBlocks?.filter((block) => block.event === event) ?? [];
    if (!blocks.length) return eventBody(ir, event).body;
    return blocks.flatMap((block) => qualifierGuard(ir, event, eventBody(ir, event, block.statements, block.qualifier).body, block.qualifier));
  };
  for (const name of LIST_METHODS) {
    if (name === "get_settings") {
      const h = ir.header;
      const fields = [];
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

function resumeMethod(ir) {
  const cases = [];
  for (const continuation of ir.continuations ?? []) {
    const statement = ir.statements.find((item) => item.filename === continuation.filename
      && item.span.start.line === continuation.span.start.line
      && item.span.start.column === continuation.span.start.column);
    if (!statement) continue;
    const id = continuation.id;
    const owner = ir.eventBlocks?.find((block) => block.statements?.includes(statement))
      ?? ir.routines?.find((item) => item.statements?.includes(statement))
      ?? ir.modules?.find((item) => item.statements?.includes(statement));
    const ownerIsModule = ir.modules?.includes(owner) === true;
    const ownerStatements = owner?.statements ?? [];
    const tail = resumeTail(ownerStatements, ownerStatements.indexOf(statement), continuation);
    let lowered;
    if (tail.some((item) => item.kind === "CallFunction" && /LIST_FROM_MEMORY/i.test(item.text))) {
      lowered = [
        "DATA(lt_lines) = io_session->get_navigation( )->get_list_from_memory( ).",
        "LOOP AT lt_lines INTO DATA(lv_line).",
        "io_session->get_list( )->get_writer( )->write_field( VALUE #( text = lv_line placement = VALUE #( new_line = abap_true ) ) ).",
        "ENDLOOP.",
      ];
    } else {
      const context = methodContext(ir, ownerIsModule ? "dynpro" : "resume");
      context.screenStates = ownerIsModule ? storedScreenStates("dynpro")
        : ir.routines?.includes(owner) ? routineScreenStates(ir, owner)
        : storedScreenStates(screenStatePlan(ir).defaultKind);
      lowered = removePromotedDeclarations(ir, lowerStatements(tail, context).map((item) => item.text));
      lowered = [...globalFieldSymbolDeclarations(ir, tail), ...lowered];
      if (lowered.some((line) => line.includes("lo_writer->"))) lowered = addWriterDeclaration(lowered);
    }
    if (lowered.length === 0) lowered.push("RETURN.");
    cases.push(`WHEN '${id}'.`, ...lowered);
  }
  const body = ["CASE is_resume-continuation-id.", ...(cases.length ? cases : ["WHEN OTHERS.", "RETURN."]), ...(cases.length ? ["WHEN OTHERS.", "RETURN."] : []), "ENDCASE."];
  return method("zif_gg_resumable_v1~resume", body.some((line) => line.includes("lo_writer->")) ? addWriterDeclaration(body) : body, "Continuation states are explicit so unsupported suspension semantics remain visible.");
}

function dynproStateComponents(ir) {
  const components = [];
  const seen = new Set();
  const add = (name, body, mutable = true) => {
    const upper = name.toUpperCase();
    if (!mutable || seen.has(upper) || !/\bTYPE\s+(?:C|N|D|T|I|P|F|X|STRING|ABAP_BOOL|SY-UCOMM|SY-DYNNR)\b/i.test(body)) return;
    seen.add(upper);
    components.push({ name: upper, member: ir.statePlan?.renames?.[upper] ?? name.toLowerCase() });
  };
  for (const declaration of ir.declarations ?? []) {
    if (declaration.statement?.scope === "local"
        || declaration.statement?.localClassName
        || (declaration.statement?.span?.start?.column ?? 1) > 1
        || !["data", "static"].includes(declaration.kind)
        || declaration.complex) continue;
    const body = declaration.raw.replace(/^\s*(?:DATA|STATICS)\s*:??\s*/i, "").replace(/\.\s*$/, "");
    for (const part of body.split(",")) {
      const name = /^\s*([A-Z][A-Z0-9_]*)\b/i.exec(part)?.[1];
      if (name) add(name, part, declaration.kind === "data" || declaration.kind === "static");
    }
  }
  for (const statement of ir.statements ?? []) {
    if (statement.kind !== "Controls") continue;
    const controls = /^CONTROLS\s+([A-Z][A-Z0-9_]*)\s+TYPE\s+TABSTRIP\b/i.exec(statement.text ?? "");
    if (!controls) continue;
    const name = `${controls[1].toUpperCase()}-ACTIVETAB`;
    if (seen.has(name)) continue;
    seen.add(name);
    components.push({
      name,
      member: `${controls[1].toLowerCase()}-activetab`,
    });
  }
  return components;
}

function dynproStateHydrate(ir, valuesName = "ct_values") {
  return dynproStateComponents(ir).flatMap(({ name, member }) => [
    `IF line_exists( ${valuesName}[ name = '${name}' ] ).`,
    `${member} = CONV #( ${valuesName}[ name = '${name}' ]-value ).`,
    "ENDIF.",
  ]);
}

function dynproStateFlush(ir, valuesName = "ct_values") {
  return dynproStateComponents(ir).flatMap(({ name, member }) => [
    `IF line_exists( ${valuesName}[ name = '${name}' ] ).`,
    `${valuesName}[ name = '${name}' ]-value = CONV string( ${member} ).`,
    "ELSE.",
    `INSERT VALUE #( name = '${name}' value = CONV string( ${member} ) ) INTO TABLE ${valuesName}.`,
    "ENDIF.",
  ]);
}

function unsupportedDynamicTableAction(ir, routine) {
  if (ir.dynamicAlv) return undefined;
  const tableSymbols = new Set((ir.declarations ?? [])
    .filter((declaration) => declaration.kind === "field-symbol"
      && declaration.statement?.scope !== "local"
      && /\bTYPE\s+STANDARD\s+TABLE\b/i.test(declaration.raw ?? ""))
    .flatMap((declaration) => (declaration.names ?? []).map((name) => String(name).toUpperCase())));
  if (!tableSymbols.size) return undefined;
  const statements = routine.statements ?? [];
  const source = statements.map((statement) => statement.text ?? "").join("\n");
  if (/\bSET_TABLE_FOR_FIRST_DISPLAY\b/i.test(source)) return undefined;
  const usesDynamicTable = [...tableSymbols].some((name) => new RegExp(`<${name}>`, "i").test(source));
  const writesFeedback = /\bGV_(?:STATUS|DETAIL)\s*=/i.test(source);
  if (!usesDynamicTable || !writesFeedback) return undefined;
  const members = globalMemberNames(ir);
  const body = [];
  if (members.GV_STATUS) {
    body.push(`${members.GV_STATUS} = ${literal("Dynamic ALV action not applied: generic field-symbol table operations are unsupported.")}.`);
  }
  if (members.GV_DETAIL) {
    body.push(`${members.GV_DETAIL} = ${literal("No table rows or cell styles were changed.")}.`);
  }
  return body.length ? [...body, "RETURN."] : undefined;
}

function routineBody(ir, routine) {
  const dynamicTableAction = unsupportedDynamicTableAction(ir, routine);
  if (dynamicTableAction) return dynamicTableAction;
  const statements = truncateTerminalPaths(routine.statements ?? []);
  const index = suspensionIndex(statements);
  const active = index >= 0 ? statements.slice(0, index + 1) : statements;
  const context = methodContext(ir, "start_of_selection", undefined, {
    parameters: routine.parameters,
    statements: routine.statements ?? [],
  });
  context.screenStates = routineScreenStates(ir, routine);
  context.contextMenu = /^ON_CTMENU(?:_|$)/i.test(String(routine.name ?? ""));
  let lowered = removePromotedDeclarations(ir, lowerStatements(active, context).map((item) => item.text));
  lowered = [...globalFieldSymbolDeclarations(ir, active), ...lowered];
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
  if (index >= 0) lowered.push(...continuationClosers(continuationFor(ir, statements[index])));
  if (lowered.some((line) => line.includes("lo_writer->"))) lowered = addWriterDeclaration(lowered);
  return lowered;
}

function dynproDataType(element) {
  const attributes = element.attributes ?? {};
  const format = String(attributes.format ?? "CHAR").toUpperCase();
  const typ = { DATS: "D", TIMS: "T", INT4: "I", QUAN: "P", CURR: "P" }[format] ?? "C";
  const defaultLengths = { DATS: 10, TIMS: 8, INT4: 10, QUAN: 14, CURR: 12, UNIT: 3, CUKY: 5 };
  const length = Number(element.length ?? defaultLengths[format] ?? 1);
  const fields = [
    "typ = '" + typ + "'",
    "length = " + (Number.isFinite(length) && length > 0 ? length : 1),
  ];
  const decimals = { QUAN: 3, CURR: 2 }[format];
  if (decimals !== undefined) fields.push("decimals = " + decimals);
  return "VALUE #( " + fields.join(" ") + " )";
}

function dynproPosition(element) {
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

function dynproControl(element) {
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

function dynproTabDefinitions(screen, flowLogic) {
  const screenNumber = String(screen.number ?? "").padStart(4, "0");
  const flows = (flowLogic ?? []).filter((flow) => String(flow.screen ?? "").padStart(4, "0") === screenNumber);
  const flowFor = (area) => flows
    .flatMap((flow) => flow.steps ?? [])
    .find((step) => step.kind === "subscreen" && step.phase === "pbo"
      && String(step.area ?? "").toUpperCase() === String(area ?? "").toUpperCase()
      && (step.screen || step.screenField));
  const targetFor = (area) => flowFor(area)?.screen;
  const fieldFor = (area) => flowFor(area)?.screenField;
  const containers = screen.containers ?? [];
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
        .filter((element) => String(element.attributes?.contName ?? "").toUpperCase() === name
          && (element.kind === "input-output" || element.kind === "pushbutton")
          && element.ucomm)
        .sort((left, right) => Number(left.line ?? 0) - Number(right.line ?? 0)
          || Number(left.column ?? 0) - Number(right.column ?? 0))
        .map((element) => {
          const areaName = element.attributes?.refField;
          const area = areas.find((item) => item.name === String(areaName ?? "").toUpperCase());
          return {
            name: String(element.name ?? "").toUpperCase(),
            line: element.line,
            column: element.column,
            control: dynproControl(element),
            text: element.name,
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

function dynproSubscreenAreas(screen, flowLogic) {
  const screenNumber = String(screen.number ?? "").padStart(4, "0");
  const flows = (flowLogic ?? []).filter((flow) => String(flow.screen ?? "").padStart(4, "0") === screenNumber);
  const flowFor = (area) => flows
    .flatMap((flow) => flow.steps ?? [])
    .find((step) => step.kind === "subscreen" && step.phase === "pbo"
      && String(step.area ?? "").toUpperCase() === String(area ?? "").toUpperCase()
      && (step.screen || step.screenField));
  return (screen.containers ?? [])
    .filter((container) => String(container.type ?? container.kind ?? "").toUpperCase() === "SUBSCREEN")
    .map((area) => ({
      name: String(area.name ?? "").toUpperCase(),
      line: area.line,
      column: area.column,
      control: dynproControl(area),
      subscreen: flowFor(area.name)?.screen,
      screenField: flowFor(area.name)?.screenField,
    }))
    .filter((area) => area.name);
}

function dynproTableDefinitions(screen) {
  const elements = screen.elements ?? [];
  const containers = (screen.containers ?? []).filter((container) =>
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
      tableVariable: `GT_${name.replace(/^TC_/, "")}`,
      control: dynproControl(container),
      visibleRows: Math.max(1, Number(container.height ?? container.position?.height ?? 1) - 1),
      selectionMode: String(attributes.tcSelLns ?? attributes.tcSelCls ?? "NONE").toUpperCase(),
      withHscroll: String(attributes.cScrollH ?? "").toUpperCase() === "X",
      withVscroll: String(attributes.cScrollV ?? "").toUpperCase() === "X",
      columns,
    };
  }).filter((table) => table.name && table.columns.length);
}

function dynproTableBindings(metadata) {
  return (metadata?.screens ?? []).flatMap((screen) => dynproTableDefinitions(screen));
}

function dynproTableRuntimeMembers(ir) {
  return (ir.statements ?? []).flatMap((statement) => {
    if (statement.kind !== "Controls") return [];
    const name = /^CONTROLS\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text)?.[1];
    return name ? [`DATA ${name.toLowerCase()} TYPE zif_gg_dynpro_types_v1=>ty_table_runtime.`] : [];
  });
}

function dynproTableHydrate(bindings) {
  const lines = [];
  for (const [tableIndex, table] of bindings.entries()) {
    const rowSymbol = `<ls_${table.name.toLowerCase()}_hydrate_row>`;
    const rowIndex = `lv_${table.name.toLowerCase()}_hydrate_row_index_${tableIndex + 1}`;
    lines.push(`LOOP AT ${table.tableVariable} ASSIGNING FIELD-SYMBOL(${rowSymbol}).`);
    lines.push(`  DATA(${rowIndex}) = sy-tabix.`);
    for (const column of table.columns) {
      lines.push(`  IF line_exists( ct_values[ container = '${table.name}' name = '${column.name}' row = ${rowIndex} ] ).`);
      lines.push(`    ${rowSymbol}-${column.name.toLowerCase()} = CONV #( ct_values[ container = '${table.name}' name = '${column.name}' row = ${rowIndex} ]-value ).`);
      lines.push("  ENDIF.");
    }
    lines.push("ENDLOOP.");
    lines.push(`IF is_context-table_control = '${table.name}' AND is_context-row > 0.`);
    lines.push(`  READ TABLE ${table.tableVariable} INTO ${table.rowPrefix.toLowerCase()} INDEX is_context-row.`);
    lines.push("ELSEIF is_context-row = 0.");
    lines.push(`  CLEAR ${table.rowPrefix.toLowerCase()}.`);
    lines.push("ENDIF.");
  }
  return lines;
}

function dynproTableFlush(bindings) {
  const lines = [];
  for (const [tableIndex, table] of bindings.entries()) {
    const rowSymbol = `<ls_${table.name.toLowerCase()}_flush_row>`;
    const rowIndex = `lv_${table.name.toLowerCase()}_flush_row_index_${tableIndex + 1}`;
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

function dynproMethods(ir, metadata = ir.dynproMetadata, interfaceName = "zif_gg_dynpro_v1", {presentationOnly = false} = {}) {
  const interfaceMethod = (name) => `${interfaceName}~${name}`;
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
  const screenNumber = (value) => String(value ?? "").padStart(4, "0");
  const screens = Array.isArray(metadata.screens) ? metadata.screens : [];
  const tableBindings = dynproTableBindings(metadata);
  const initial = screenNumber(metadata.initialScreen ?? screens[0]?.number ?? "0100");
  const screenFields = (screen) => {
    const fields = [`number = '${screenNumber(screen.number)}'`];
    if (screen.title) fields.push(`title = ${literal(screen.title)}`);
    if (screen.nextScreen !== undefined) fields.push(`next_screen = '${screenNumber(screen.nextScreen)}'`);
    if (screen.modal) fields.push("modal = abap_true");
    if (screen.width !== undefined) fields.push(`width = ${screen.width * 10}`);
    if (screen.height !== undefined) fields.push(`height = ${screen.height * 26 + 20}`);
    return fields.join(" ");
  };
  const flowLogic = Array.isArray(metadata.flowLogic) ? metadata.flowLogic : [];
  const hasDynproValueRequest = (name) => flowLogic.some((screen) =>
    (screen.steps ?? []).some((step) => step.phase === "pov"
      && (!step.field || String(step.field).toUpperCase() === String(name).toUpperCase())));
  const buildScreens = [];
  const radioGroups = new Map();
  let radioGroupIndex = 0;
  const radioGroup = (element) => {
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
      .filter((element) => String(element.attributes?.contName ?? "").toUpperCase() === table.name)
      .map((element) => element.name)));
    const tabChildren = new Set(tabstrips.flatMap((strip) => strip.tabs.map((tab) => tab.name)));
    const tabSubscreenAreas = new Set(tabstrips.flatMap((strip) => strip.areas.map((area) => area.name)));
    const subscreenAreas = new Set([
      ...tabSubscreenAreas,
      ...genericSubscreenAreas.map((area) => area.name),
    ]);
    const items = [
      ...(screen.elements ?? []).filter((element) => element.name
        && !tableChildren.has(element.name)
        && !tabChildren.has(element.name)
        && !subscreenAreas.has(element.name)),
      ...tables.map((table) => ({
        kind: "table-control",
        name: table.name,
        line: screen.containers?.find((container) => String(container.name).toUpperCase() === table.name)?.line ?? 1,
        column: screen.containers?.find((container) => String(container.name).toUpperCase() === table.name)?.column ?? 1,
        table,
      })),
      ...tabstrips.map((strip) => ({
        kind: "tabstrip",
        name: strip.name,
        line: strip.line,
        column: strip.column,
        tabstrip: strip,
      })),
      ...tabstrips.flatMap((strip) => strip.areas.map((area) => ({
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
        .filter((container) => String(container.type ?? container.kind ?? "").toUpperCase() === "CUST_CTRL")
        .map((container) => ({
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
        buildScreens.push(`io_builder->add_custom_control( VALUE #( control = ${dynproControl(element.customControl)} ) ).`);
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
        buildScreens.push("io_builder->add_checkbox( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + " ) ).");
      } else if (element.kind === "radio") {
        buildScreens.push("io_builder->add_radiobutton( VALUE #( control = " + control + " text = " + literal(element.text ?? "") + " group = '" + radioGroup(element) + "' ) ).");
      }
    }
    buildScreens.push("io_builder->end_screen( ).");
  }
  const buildFlow = [];
  for (const screen of flowLogic) {
    buildFlow.push(`io_builder->begin_screen( '${screenNumber(screen.screen)}' ).`);
    const fallbackSteps = [];
    const addFallbackPhase = (phase, entries) => {
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
      fallbackSteps.push(...screen.pov.modules.map((entry) => ({ kind: "module", phase: "pov", ...entry })));
    }
    if (screen.poh?.modules?.length) {
      fallbackSteps.push({ kind: "process", phase: "poh", field: screen.poh.field });
      fallbackSteps.push(...screen.poh.modules.map((entry) => ({ kind: "module", phase: "poh", ...entry })));
    }
    const steps = screen.steps?.length ? screen.steps : fallbackSteps;
    let openPhase;
    const addModule = (phase, item) => {
      const module = typeof item === "string" ? { name: item } : item;
      const flags = [];
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
        const begin = { pbo: "begin_pbo", pai: "begin_pai", pov: "begin_value_request", poh: "begin_help_request" }[openPhase];
        if (begin === "begin_value_request" || begin === "begin_help_request") {
          buildFlow.push(`io_builder->${begin}( '${String(step.field ?? "").toUpperCase()}' ).`);
        } else if (begin) buildFlow.push(`io_builder->${begin}( ).`);
      } else if (step.kind === "module" || step.kind === "field-module") {
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
  const dispatch = (direction) => {
    const modules = ir.modules.filter((item) => item.direction === direction);
    if (!modules.length) return ["RETURN."];
    const lines = ["CASE is_context-module."];
    for (const module of modules) {
      const context = {
        ...methodContext(ir, "dynpro"),
        ucomm: "is_context-ucomm",
        ...(direction === "OUTPUT" ? {} : { screenStates: storedScreenStates("dynpro", { row: "is_context-row" }) }),
      };
      const body = [
        ...globalFieldSymbolDeclarations(ir, module.statements),
        ...removePromotedDeclarations(ir, lowerStatements(module.statements, context).map((item) => item.text)),
      ];
      lines.push(`WHEN '${module.name}'.`, ...body);
    }
    if (lines.some((line) => line.includes("lo_writer->"))) lines.splice(0, 0, "DATA(lo_writer) = io_session->get_list( )->get_writer( ).");
    lines.push("WHEN OTHERS.", "RETURN.", "ENDCASE.");
    return lines;
  };
  const statusByScreen = metadata.statuses ?? metadata.statusByScreen ?? metadata.guiStatuses ?? {};
  const statusLines = [];
  for (const [screen, value] of Object.entries(statusByScreen)) {
    if (!value || typeof value !== "object") continue;
    const fields = [`status = ${literal(value.status ?? value.name ?? "")}`];
    const active = value.activeUcomm ?? value.active_ucomm ?? [];
    const excluded = value.excludedUcomm ?? value.excluded_ucomm ?? [];
    if (active.length) fields.push(`active_ucomm = VALUE #( ${active.map((item) => `( '${String(item).toUpperCase()}' )`).join(" ")} )`);
    if (excluded.length) fields.push(`excluded_ucomm = VALUE #( ${excluded.map((item) => `( '${String(item).toUpperCase()}' )`).join(" ")} )`);
    const guiStatus = ir.guiStatusMetadata?.[String(value.status ?? value.name ?? "").toUpperCase()]
      ?? ir.guiStatusMetadata?.[value.status ?? value.name];
    if (guiStatus?.activePFKeys?.length || guiStatus?.active_pf_keys?.length) {
      const keys = guiStatus.activePFKeys ?? guiStatus.active_pf_keys;
      fields.push(`active_pf_keys = VALUE #( ${[...new Set(keys)].map((key) => `( ${Number(key)} )`).join(" ")} )`);
    }
    if (guiStatus?.pfActions?.length || guiStatus?.pf_actions?.length) {
      const actions = guiStatus.pfActions ?? guiStatus.pf_actions;
      fields.push(`pf_actions = VALUE #( ${actions.map((item) => `( number = ${Number(item.number ?? item.functionKey)} ucomm = '${String(item.ucomm ?? item.functionCode ?? "").toUpperCase()}' )`).join(" ")} )`);
    }
    if (guiStatus?.iconBar?.length || guiStatus?.icon_bar?.length) {
      const icons = guiStatus.iconBar ?? guiStatus.icon_bar;
      fields.push(`icon_bar = VALUE #( ${icons.map((item) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' label = ${literal(String(item.label ?? ""))} icon = ${literal(String(item.icon ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} )`);
    }
    if (guiStatus?.menus?.length) {
      fields.push(`menus = VALUE #( ${guiStatus.menus.map((menu) => `( code = ${literal(String(menu.code ?? ""))} text = ${literal(String(menu.text ?? ""))} path = ${literal(String(menu.path ?? ""))} items = VALUE #( ${(
        menu.items ?? []
      ).map((item) => `( ucomm = '${String(item.ucomm ?? "").toUpperCase()}' text = ${literal(String(item.text ?? ""))}${item.separator ? " separator = abap_true" : ""} )`).join(" ")} ) )`).join(" ")} )`);
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
  const tableHydrate = dynproTableHydrate(tableBindings);
  const tableFlush = dynproTableFlush(tableBindings);
  const tableContext = tableBindings.length ? [
    "IF is_context-row > 0.",
    ...tableBindings.map((table) => [
      `  IF is_context-table_control = '${table.name}'.`,
      `    ${table.name.toLowerCase()}-current_line = is_context-row.`,
      "  ENDIF.",
    ]).flat(),
    "ENDIF.",
  ] : [];
  const requestDispatch = (phase) => {
    const requestModules = flowLogic
      .flatMap((screen) => screen.steps ?? [])
      .filter((step) => step.phase === phase && (step.kind === "module" || step.kind === "field-module"))
      .map((step) => String(step.name ?? "").toUpperCase())
      .filter(Boolean);
    const modules = ir.modules.filter((item) => requestModules.includes(String(item.name ?? "").toUpperCase()));
    const lines = [
      "DATA ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.",
      "ct_values = it_values.",
    ];
    if (!modules.length) return lines;
    lines.push(
      ...dynproStateHydrate(ir),
      ...dynproTableHydrate(tableBindings),
      ...tableContext,
      "CASE is_context-module.",
    );
    for (const module of modules) {
      const context = {
        ...methodContext(ir, "dynpro"),
        ucomm: "is_context-ucomm",
        screenStates: storedScreenStates("dynpro", { row: "is_context-row" }),
      };
      const body = [
        ...globalFieldSymbolDeclarations(ir, module.statements),
        ...removePromotedDeclarations(ir, lowerStatements(module.statements, context).map((item) => item.text)),
      ];
      lines.push(`WHEN '${module.name}'.`, ...body);
    }
    lines.push(
      "WHEN OTHERS.",
      "RETURN.",
      "ENDCASE.",
      ...dynproStateFlush(ir),
      ...dynproTableFlush(tableBindings),
    );
    return lines;
  };
  const valueRequest = [
    ...requestDispatch("pov"),
    "rt_values = io_session->get_compatibility( )->get_value_help_values( ).",
  ];
  const helpRequest = [
    ...requestDispatch("poh"),
    "IF line_exists( ct_values[ name = 'GV_RESULT' ] ).",
    "rv_text = ct_values[ name = 'GV_RESULT' ]-value.",
    "ENDIF.",
  ];
  const methods = [
    method(interfaceMethod("get_initial_screen"), [`rv_screen = '${initial}'.`]),
    method(interfaceMethod("build_screens"), buildScreens),
    method(interfaceMethod("build_flow_logic"), buildFlow),
    method(interfaceMethod("initialization"), [...stateFlush, ...tableFlush]),
    method(interfaceMethod("process_output_module"), [...dynproStatesSetter(ir), ...stateHydrate, ...tableHydrate, ...tableContext, ...statusLines, ...cursorLines, ...dispatch("OUTPUT"), ...stateFlush, ...tableFlush]),
    method(interfaceMethod("process_input_module"), [...stateHydrate, ...tableHydrate, ...tableContext, ...dispatch("INPUT"), ...stateFlush, ...tableFlush]),
    method(interfaceMethod("process_on_value_request"), valueRequest),
    method(interfaceMethod("process_on_help_request"), helpRequest),
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

function contextMenuMethod(ir) {
  const routine = contextMenuRoutine(ir);
  if (!routine) return undefined;
  const screenField = (ir.screenMetadata?.screens ?? ir.dynproMetadata?.screens ?? [])
    .flatMap((screen) => screen.elements ?? [])
    .find((element) => String(element.attributes?.cxtMenon ?? "").toUpperCase() === "INPUT")?.name;
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

function helperDefinitionHeader(localClass, generatedName, ir) {
  const raw = localClass.definitionHeader ?? `CLASS ${localClass.name} DEFINITION.`;
  let rest = raw
    .replace(new RegExp(`^CLASS\\s+${localClass.name}\\s+DEFINITION\\b`, "i"), "")
    .replace(/\.\s*$/, "")
    .trim()
    .replace(/^PUBLIC\b\s*/i, "");
  if (!/\bCREATE\b/i.test(rest)) rest = `${rest}${rest ? " " : ""}CREATE PUBLIC`;
  return `CLASS ${generatedName.toLowerCase()} DEFINITION PUBLIC${rest ? ` ${renameIdentifiers(rest, allRenames(ir))}` : ""}.`;
}

// A static event handler is called by the event, which passes only the event's
// parameters, so it cannot take io_owner and io_session like other static
// methods. It reads them from static attributes that SET HANDLER fills instead.
function isStaticEventHandler(text) {
  return /^\s*CLASS-METHODS\b[\s\S]*\bFOR\s+EVENT\b/i.test(String(text ?? ""));
}

function staticEventHandlerNames(localClass) {
  return new Set((localClass.definition ?? [])
    .filter((statement) => isStaticEventHandler(statement.text))
    .map((statement) => /^\s*CLASS-METHODS\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text)?.[1]?.toUpperCase())
    .filter(Boolean));
}

function helperMethodContext(ir, localClass, localMethod) {
  const isStaticMethod = (localClass.definition ?? []).some((statement) => {
    const name = /^\s*CLASS-METHODS\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text ?? "")?.[1];
    return name && name.toUpperCase() === String(localMethod?.name ?? "").toUpperCase();
  });
  const isEventHandler = staticEventHandlerNames(localClass).has(String(localMethod?.name ?? "").toUpperCase());
  const context = methodContext(ir, "local_class", undefined, {
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
  const localTypeUses = new Set([
    ...String(localMethod?.definition?.text ?? "").matchAll(/\b(?:TYPE|LIKE|VALUE)\s+(?:REF\s+TO\s+)?([A-Z][A-Z0-9_]*)/gi),
    ...(localMethod?.statements ?? []).flatMap((statement) => [...String(statement.text ?? "").matchAll(/\b(?:TYPE|LIKE|VALUE)\s+(?:REF\s+TO\s+)?([A-Z][A-Z0-9_]*)/gi)]),
  ].map((match) => match[1].toUpperCase()));
  const ownerTypeReplacements = (ir.declarations ?? [])
    .filter((declaration) => ["type", "typebegin"].includes(declaration.kind))
    .flatMap((declaration) => (declaration.names ?? [])
      .filter((name) => localTypeUses.has(name.toUpperCase()))
      .map((name) => [name, `${ir.targetClassName.toLowerCase()}=>${name.toLowerCase()}`]));
  context.replacements = [
    ...Object.entries(ownerReplacements),
    ...ownerTypeReplacements,
    ...Object.entries(ir.statePlan?.renames ?? {}),
    ...(ir.selections ?? []).flatMap((screen) => (screen.elements ?? [])
      .filter((item) => item.name)
      .flatMap((item) => {
        // The member lives on the owner class, like the report globals above.
        const reference = `${context.ownerPrefix}${ir.statePlan?.selectionState?.[item.name]?.member ?? item.name.toLowerCase()}`;
        const fields = item.kind === "select-option"
          ? [[`${item.name}-low`, `${reference}[ 1 ]-low`], [`${item.name}-high`, `${reference}[ 1 ]-high`]]
          : [];
        return [...fields, [item.name, reference]];
      })),
    ...Object.entries(ir.localClassRenames ?? {}).map(([name, value]) => [name, String(value).toLowerCase()]),
  ];
  context.controlObjectTypes = controlObjectTypes(ir.declarations ?? [], ir.localClasses ?? [], {
    statements: localMethod?.statements ?? [],
  });
  context.isStaticMethod = isStaticMethod;
  return context;
}

function helperMethodBody(ir, localClass, localMethod) {
  const statements = truncateTerminalPaths(localMethod.statements ?? []);
  const context = helperMethodContext(ir, localClass, localMethod);
  let body = lowerStatements(statements, context).map((item) => item.text);
  // Lowering writes io_session; methods without that parameter hold the
  // session elsewhere. `io_session =` is a named argument and stays.
  if (context.sessionVariable !== "io_session") {
    body = body.map((line) => line.replace(/\bio_session\b/gi, (name, offset, source) =>
      /^\s*=/.test(source.slice(offset + name.length)) ? name : context.sessionVariable));
  }
  body = [...globalFieldSymbolDeclarations(ir, statements), ...body];
  if (body.some((line) => line.includes("lo_writer->")) && !/\bio_session\b/i.test(localMethod.definition?.text ?? "")) {
    body = ["* TODO GGCONV-E501: local class writer access requires an explicit session mapping."];
  }
  return body.length ? body : ["RETURN."];
}

function helperDefinitionBody(statements, rename) {
  const lines = [];
  let structured;
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
    if (statement.kind === "DataBegin" || statement.kind === "TypeBegin") {
      flushStructured();
      structured = {
        keyword: statement.kind === "DataBegin" ? "DATA" : "TYPES",
        beginName: /BEGIN OF\s+([A-Z0-9_]+)/i.exec(text)?.[1] ?? "",
        components: [],
        endName: undefined,
      };
      continue;
    }
    if (structured && (statement.kind === "DataEnd" || statement.kind === "TypeEnd")) {
      structured.endName = /END OF\s+([A-Z0-9_]+)/i.exec(text)?.[1] ?? structured.beginName;
      flushStructured();
      continue;
    }
    if (structured) {
      // Components carry their own terminator: a comma in the chained form, a
      // period in the classic `DATA BEGIN OF x. DATA fld. DATA END OF x.` form.
      // The structure is always re-emitted as one chain, so drop the terminator
      // here and let flushStructured put the commas back.
      const component = text.replace(new RegExp(`^${structured.keyword}\\s+`, "i"), "").replace(/\s*[,.]\s*$/, "");
      if (component) structured.components.push(component);
      continue;
    }
    // abaplint splits chained declarations into one statement per element,
    // repeating the keyword and keeping the comma. Each element becomes a
    // standalone member, so the comma must become a terminator.
    lines.push(...text.split("\n").map((line) => `  ${line.trim().replace(/,\s*$/, ".")}`));
  }
  flushStructured();
  return lines;
}

function helperSource(ir, options, localClass) {
  const generatedName = localClass.generatedName;
  const rename = (text) => renameIdentifiers(text, allRenames(ir));
  const originalConstructor = (localClass.methods ?? []).find((localMethod) => localMethod.name?.toUpperCase() === "CONSTRUCTOR");
  const originalConstructorDefinition = originalConstructor?.definition?.text
    ? rename(originalConstructor.definition.text).replace(/\.\s*$/, "")
    : undefined;
  const constructorSignature = originalConstructorDefinition
    ? `${originalConstructorDefinition}${/\bIMPORTING\b/i.test(originalConstructorDefinition) ? " " : " IMPORTING "}io_owner TYPE REF TO ${ir.targetClassName.toLowerCase()} io_session TYPE REF TO zif_gg_session_v1.`
    : `METHODS constructor IMPORTING io_owner TYPE REF TO ${ir.targetClassName.toLowerCase()} io_session TYPE REF TO zif_gg_session_v1.`;
  const eventHandlers = staticEventHandlerNames(localClass);
  const bridge = [
    `    ${constructorSignature}`,
    `    DATA mo_owner TYPE REF TO ${ir.targetClassName.toLowerCase()}.`,
    "    DATA mo_session TYPE REF TO zif_gg_session_v1.",
    ...(eventHandlers.size ? [
      `    CLASS-DATA go_owner TYPE REF TO ${ir.targetClassName.toLowerCase()}.`,
      "    CLASS-DATA go_session TYPE REF TO zif_gg_session_v1.",
    ] : []),
  ];
  const originalDefinition = helperDefinitionBody(
    (localClass.definition ?? []).filter((statement) => !(statement.kind === "MethodDef" && /^\s*METHODS\s+constructor\b/i.test(statement.text))),
    rename,
  );
  const staticMethods = new Set((localClass.definition ?? [])
    .filter((statement) => /^\s*CLASS-METHODS\b/i.test(statement.text ?? "") && !isStaticEventHandler(statement.text))
    .map((statement) => /^\s*CLASS-METHODS\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text)?.[1]?.toUpperCase())
    .filter(Boolean));
  const ownerSessionParameters = `io_owner TYPE REF TO ${ir.targetClassName.toLowerCase()} io_session TYPE REF TO zif_gg_session_v1`;
  const definitionWithStaticBridges = originalDefinition.map((line) => {
    const methodName = /^\s*CLASS-METHODS\s+([A-Z][A-Z0-9_]*)\b/i.exec(line)?.[1]?.toUpperCase();
    if (!methodName || !staticMethods.has(methodName) || /\bIO_OWNER\b/i.test(line)) return line;
    return `${line.replace(/\.\s*$/, "")}${/\bIMPORTING\b/i.test(line) ? " " : " IMPORTING "}${ownerSessionParameters}.`;
  });
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
  return `${header({ className: generatedName, ir, options })}${definition.join("\n")}${implementations.join("\n")}ENDCLASS.\n`.replace(/\r?\n/g, "\n");
}

export function emitHelperSources(ir, options) {
  prepareLocalClassNames(ir, options);
  return (ir.localClasses ?? []).map((localClass) => ({
    className: localClass.generatedName,
    sourceName: localClass.name,
    source: helperSource(ir, options, localClass),
  }));
}

export function emitClassSource(ir, options) {
  prepareLocalClassNames(ir, options);
  const className = ir.targetClassName.toLowerCase();
  const interfaces = interfaceOrder(ir);
  const members = dataMembers(ir);
  const friends = (ir.localClasses ?? []).map((localClass) => localClass.generatedName.toLowerCase());
  const friendAddition = friends.length ? ` FRIENDS ${friends.join(" ")}` : "";
  const definition = [`CLASS ${className} DEFINITION PUBLIC FINAL CREATE PUBLIC${friendAddition}.`, "", "  PUBLIC SECTION.", ...interfaces.map((name) => `    INTERFACES ${name}.`), ""];
  if (members.length) definition.push("  PRIVATE SECTION.", ...members.flatMap((line) => line.split("\n").map((part) => `    ${part}`)), "");
  definition.push("ENDCLASS.", "", `CLASS ${className} IMPLEMENTATION.`, "");
  const implementation = [];
  if (ir.interfaces.includes("zif_gg_transaction_v1")) {
    implementation.push(method("zif_gg_transaction_v1~get_transaction", [`rs_transaction = VALUE #( tcode = '${ir.transactionCode}' description = '${String(ir.description).replaceAll("'", "''")}'${programField(ir)} ).`]));
  }
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
    implementation.push(method(routine.methodName, routineBody(ir, routine)));
  }
  implementation.push("ENDCLASS.", "");
  return `${header({ className: ir.targetClassName, ir, options })}${definition.join("\n")}\n${implementation.join("\n")}`.replace(/\r?\n/g, "\n");
}

export function emitPartialSkeleton(ir, options, diagnostics) {
  const className = ir.targetClassName.toLowerCase();
  const diagnosticLines = diagnostics
    .filter((item) => item.severity === "error" || item.severity === "warning")
    .map((item) => `${item.code}: ${item.construct}`)
    .filter((value, index, values) => values.indexOf(value) === index);
  const startBody = [
    `io_session->get_list( )->set_title( ${literal(ir.reportTitle ?? ir.programName ?? ir.targetClassName)} ).`,
    "DATA(lo_writer) = io_session->get_list( )->get_writer( ).",
    `lo_writer->write_field( VALUE #( text = ${literal("Partial conversion preview")} placement = VALUE #( new_line = abap_true ) ) ).`,
    `lo_writer->write_field( VALUE #( text = ${literal(`Source report: ${ir.programName ?? "UNKNOWN"}`)} placement = VALUE #( new_line = abap_true ) ) ).`,
    `lo_writer->write_field( VALUE #( text = ${literal("Unsupported source remains as explicit converter diagnostics.")} placement = VALUE #( new_line = abap_true ) ) ).`,
    ...diagnosticLines.map((line) => `lo_writer->write_field( VALUE #( text = ${literal(line)} placement = VALUE #( new_line = abap_true ) ) ).`),
  ];
  const methods = REPORT_METHODS.map((name) => method(
    `zif_gg_report_v1~${name}`,
    name === "load_of_program" && ir.reportTitle
      ? [`io_session->get_list( )->set_title( ${literal(ir.reportTitle)} ).`]
      : name === "start_of_selection" ? startBody : ["RETURN."],
  ));
  const todos = diagnostics
    .filter((item) => item.severity === "error" || item.code.startsWith("GGCONV-E"))
    .map((item) => `* TODO ${item.code}: ${item.construct}`)
    .filter((value, index, values) => values.indexOf(value) === index);
  return `${header({className: ir.targetClassName, ir, options})}${todos.join("\n")}${todos.length ? "\n" : ""}` + [
    `CLASS ${className} DEFINITION PUBLIC FINAL CREATE PUBLIC.`,
    "",
    "  PUBLIC SECTION.",
    "    INTERFACES zif_gg_report_v1.",
    ...(ir.transactionCode ? ["    INTERFACES zif_gg_transaction_v1."] : []),
    "",
    "ENDCLASS.",
    "",
    `CLASS ${className} IMPLEMENTATION.`,
    "",
    ...(ir.transactionCode ? [method("zif_gg_transaction_v1~get_transaction", [
      `rs_transaction = VALUE #( tcode = ${literal(ir.transactionCode)} description = ${literal(ir.description)}${programField(ir)} ).`,
    ]).toString()] : []),
    ...methods.map((entry) => entry.toString()),
    "ENDCLASS.",
    "",
  ].join("\n");
}

export function emitPartialApplication(ir, options, diagnostics) {
  const className = ir.targetClassName.toLowerCase();
  const hasScreenProvider = ir.programKind === "report" && (ir.screenMetadata?.screens?.length ?? 0) > 0;
  const interfaceNames = (ir.programKind === "module-pool"
    ? ["zif_gg_dynpro_v1", "zif_gg_transaction_v1"]
    : ["zif_gg_report_v1", "zif_gg_transaction_v1", ...(hasScreenProvider ? ["zif_gg_screen_provider_v1"] : [])])
    .filter((name) => name !== "zif_gg_transaction_v1" || ir.transactionCode);
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
    `io_session->get_list( )->set_title( ${literal(label)} ).`,
    "DATA(lo_writer) = io_session->get_list( )->get_writer( ).",
    `lo_writer->write_field( VALUE #( text = ${literal(label)} placement = VALUE #( new_line = abap_true ) ) ).`,
    `lo_writer->write_field( VALUE #( text = ${literal("Application content is available; unsupported optional operations remain in converter diagnostics.")} placement = VALUE #( new_line = abap_true ) ) ).`,
  ];
  const screenBody = hasScreenProvider
    ? [`io_session->get_dialog( )->call_screen(
      is_call         = VALUE #( screen = '${String(ir.screenMetadata.initialScreen ?? ir.screenMetadata.screens[0]?.number ?? "0100").padStart(4, "0")}' )
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
          ? [`io_session->get_list( )->set_title( ${literal(ir.reportTitle)} ).`]
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
  return `${header({className: ir.targetClassName, ir, options})}${todos.join("\n")}${todos.length ? "\n" : ""}${[
    ...definition,
    ...(ir.transactionCode ? [transaction.toString()] : []),
    ...methods.map((entry) => entry.toString()),
    "ENDCLASS.",
    "",
  ].join("\n")}`;
}

export function lowerToScaffoldIR(ir, options, sourceMap = []) {
  const methods = [];
  if (ir.interfaces.includes("zif_gg_transaction_v1")) {
    methods.push(method("zif_gg_transaction_v1~get_transaction", [`rs_transaction = VALUE #( tcode = '${ir.transactionCode}' description = '${String(ir.description).replaceAll("'", "''")}'${programField(ir)} ).`]));
  }
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
    methods.push(method(routine.methodName, routineBody(ir, routine)));
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
