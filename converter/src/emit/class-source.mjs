import { CONVERTER_VERSION, MANIFEST_SCHEMA_VERSION } from "../options.mjs";
import { lowerStatements, selectionExpression, selectionType } from "../passes/lower-statements.mjs";
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

function interfaceOrder(ir) {
  const order = ["zif_gg_report_v1", "zif_gg_dynpro_v1", "zif_gg_transaction_v1", "zif_gg_list_processing_v1", "zif_gg_resumable_v1"];
  return order.filter((name) => ir.interfaces.includes(name));
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

function dataMembers(ir) {
  const members = [];
  const declarations = ir.declarations;
  const routineStatements = new Set(ir.routines.flatMap((routine) => routine.statements));
  for (let index = 0; index < declarations.length; index++) {
    const item = declarations[index];
    if (routineStatements.has(item.statement) || item.statement.scope === "local") continue;
    if (item.kind === "databegin" || item.kind === "typebegin") {
      const begin = /BEGIN OF\s+([A-Z0-9_]+)/i.exec(item.raw)?.[1];
      const keyword = item.kind === "typebegin" ? "TYPES" : "DATA";
      const components = [];
      for (let cursor = index + 1; cursor < declarations.length; cursor++) {
        if (declarations[cursor].kind === (item.kind === "typebegin" ? "type" : "data")) {
          const componentKeyword = item.kind === "typebegin" ? "TYPES" : "DATA";
          components.push(renameIdentifiers(declarations[cursor].raw.replace(new RegExp(`^${componentKeyword}\\s+`, "i"), ""), ir.statePlan?.renames));
        }
        if (declarations[cursor].kind === (item.kind === "typebegin" ? "typeend" : "dataend")) {
          const end = /END OF\s+([A-Z0-9_]+)/i.exec(declarations[cursor].raw)?.[1] ?? begin;
          members.push(`${keyword}: BEGIN OF ${begin}, ${components.join(" ")} END OF ${end}.`);
          index = cursor;
          break;
        }
      }
    } else if ((item.kind === "data" || item.kind === "type" || item.kind === "constant" || item.kind === "static" || (item.kind === "tables" && item.resolved)) && !item.complex) {
      const declarationRaw = item.raw.replace(/,\s*$/, ".");
      const declaration = item.kind === "static"
        ? declarationRaw.replace(/^STATICS\b/i, "DATA")
        : item.kind === "tables"
          ? `DATA ${item.names?.[0]?.toLowerCase()} TYPE ${item.type}.`
          : declarationRaw;
      members.push(renameIdentifiers(declaration, ir.statePlan?.renames));
    }
  }
  for (const [name, state] of Object.entries(ir.statePlan?.selectionState ?? {})) {
    const type = state.ranges ? "zif_gg_selection_screen_types=>ty_ranges" : "string";
    members.push(`DATA ${state.member} TYPE ${type}.`);
  }
  for (const routine of ir.routines) {
    const parameters = routine.parameters ?? [];
    const lines = [`METHODS ${routine.methodName}`];
    const importing = parameters.filter((parameter) => parameter.direction === "IMPORTING");
    const width = Math.max("io_session".length, ...parameters.map((parameter) => parameter.name.length));
    lines.push("  IMPORTING", `    io_session${" ".repeat(width - "io_session".length)} TYPE REF TO zif_gg_session_v1`);
    lines.push(...importing.map((parameter) => `    ${parameter.name}${" ".repeat(width - parameter.name.length)} TYPE ${parameter.type}`));
    for (const direction of ["CHANGING"]) {
      const items = parameters.filter((parameter) => parameter.direction === direction);
      if (!items.length) continue;
      lines.push(`  ${direction}`, ...items.map((parameter) => `    ${parameter.name}${" ".repeat(width - parameter.name.length)} TYPE ${parameter.type}`));
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

function selectionBuilder(ir) {
  const lines = [];
  for (const screen of ir.selections) {
    if (screen.number !== "0100" || screen.asWindow || screen.asSubscreen) {
      lines.push(`io_builder->begin_screen( VALUE #( number = '${screen.number}'${screen.asWindow ? " as_window = abap_true" : ""}${screen.asSubscreen ? " as_subscreen = abap_true" : ""} ) ).`);
    }
    for (const item of screen.elements) {
      if (item.kind === "layout") {
        if (item.layout === "comment") {
          const fields = [`name = '${item.name}'`, `text = ${literal(item.text)}`];
          if (item.position !== undefined) fields.push(`position = ${item.position}`);
          if (item.length !== undefined) fields.push(`visible_length = ${item.length}`);
          lines.push(`io_builder->add_comment( VALUE #( ${fields.join(" ")} ) ).`);
        } else if (item.layout === "skip") lines.push(`io_builder->add_skip( ${item.lines} ).`);
        else if (item.layout === "uline") lines.push(`io_builder->add_uline( VALUE #( ${item.position !== undefined ? `position = ${item.position}` : ""}${item.length !== undefined ? ` length = ${item.length}` : ""} ) ).`);
        else if (item.layout === "position") lines.push(`io_builder->set_position( ${item.position} ).`);
        else if (item.layout === "begin_line") lines.push("io_builder->begin_line( ).");
        else if (item.layout === "end_line") lines.push("io_builder->end_line( ).");
        else if (item.layout === "begin_block") lines.push(`io_builder->begin_block( VALUE #( name = '${item.name}'${item.title ? ` title = ${literal(item.title)}` : ""}${item.withFrame ? " with_frame = abap_true" : ""} ) ).`);
        else if (item.layout === "end_block") lines.push("io_builder->end_block( ).");
        else if (item.layout === "pushbutton") lines.push(`io_builder->add_pushbutton( VALUE #( name = '${item.name}' text = ${literal(item.text)}${item.position !== undefined ? ` position = ${item.position}` : ""}${item.length !== undefined ? ` length = ${item.length}` : ""} ucomm = '${item.ucomm}' ) ).`);
        else if (item.layout === "function_key") lines.push(`io_builder->add_function_key( VALUE #( number = ${item.number} text = ${literal(item.text)} ucomm = '${item.ucomm ?? `FC${String(item.number).padStart(2, "0")}`}' ) ).`);
        else if (item.layout === "begin_tabbed_block") lines.push(`io_builder->begin_tabbed_block( VALUE #( name = '${item.name}' lines = ${item.lines} ) ).`);
        else if (item.layout === "tab") lines.push(`io_builder->add_tab( VALUE #( name = '${item.name}' text = ${literal(item.text)} subscreen = '${item.subscreen}' ucomm = '${item.ucomm}' ) ).`);
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
          if (/DEFAULT\s+['"]?X/i.test(additions)) fields.push("default = abap_true");
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          if (ucomm) fields.push(`ucomm = '${ucomm.toUpperCase()}'`);
          lines.push(`io_builder->add_checkbox( VALUE #( ${fields.join(" ")} ) ).`);
        } else if (/RADIOBUTTON\s+GROUP\s+(\w+)/i.test(additions)) {
          const group = /RADIOBUTTON\s+GROUP\s+(\w+)/i.exec(additions)[1].toUpperCase();
          const ucomm = /USER-COMMAND\s+(\w+)/i.exec(additions)?.[1];
          const defaultValue = /DEFAULT\s+['"]?X/i.test(additions) ? " default = abap_true" : "";
          lines.push(`io_builder->add_radiobutton( VALUE #( name = '${item.name}' text = ${literal(item.text ?? item.name)} radio_group = '${group}'${defaultValue}${ucomm ? ` ucomm = '${ucomm.toUpperCase()}'` : ""} ) ).`);
        } else if (/AS\s+LISTBOX/i.test(additions)) {
          const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`, type];
          const visibleLength = /VISIBLE\s+LENGTH\s+(\d+)/i.exec(additions)?.[1];
          if (visibleLength) fields[2] = type.replace(/\s\)$/, ` visible_length = ${visibleLength} )`);
          if (item.default) fields.push(`default = ${item.default}`);
          if (item.fixedValues?.length) fields.push(`fixed_values = VALUE #( ${item.fixedValues.map((fixed) => `( key = ${literal(fixed.key ?? fixed.value ?? "")} text = ${literal(fixed.text ?? fixed.label ?? fixed.key ?? "")} )`).join(" ")} )`);
          lines.push(`io_builder->add_listbox( VALUE #( ${fields.join(" ")} ) ).`);
        } else {
          const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`, type];
          if (item.default) fields.push(`default = ${item.default}`);
          const modif = /MODIF\s+ID\s+(\w+)/i.exec(additions)?.[1];
          if (modif) fields.push(`modif_id = '${modif.toUpperCase()}'`);
          const memoryId = /MEMORY\s+ID\s+(\w+)/i.exec(additions)?.[1];
          if (memoryId) fields.push(`memory_id = '${memoryId.toUpperCase()}'`);
          const searchHelp = /MATCHCODE\s+OBJECT\s+(\w+)/i.exec(additions)?.[1];
          if (searchHelp) fields.push(`search_help = '${searchHelp.toUpperCase()}'`);
          if (/OBLIGATORY/i.test(additions)) fields.push("obligatory = abap_true");
          if (/LOWER\s+CASE/i.test(additions)) fields.push("lower_case = abap_true");
          if (/NO-DISPLAY/i.test(additions)) fields.push("no_display = abap_true");
          lines.push(`io_builder->add_parameter( VALUE #( ${fields.join(" ")} ) ).`);
        }
      } else if (item.kind === "select-option") {
        const fields = [`name = '${item.name}'`, `text = ${literal(item.text ?? item.name)}`, `data_type = ${selectionDataType(item)}`];
        if (/NO[\s-]+EXTENSION/i.test(item.additions)) fields.push("no_extension = abap_true");
        if (/NO[\s-]+INTERVALS/i.test(item.additions)) fields.push("no_intervals = abap_true");
        const defaultMatch = /DEFAULT\s+([^\s]+)(?:\s+TO\s+([^\s]+))?/i.exec(item.additions);
        if (defaultMatch) fields.push(`default = VALUE #( sign = 'I' option = '${defaultMatch[2] ? "BT" : "EQ"}' low = ${selectionExpression(defaultMatch[1])}${defaultMatch[2] ? ` high = ${selectionExpression(defaultMatch[2])}` : ""} )`);
        lines.push(`io_builder->add_select_option( VALUE #( ${fields.join(" ")} ) ).`);
      }
    }
    if (screen.number !== "0100" || screen.asWindow || screen.asSubscreen) lines.push("io_builder->end_screen( ).");
  }
  return lines;
}

function methodContext(ir, event, qualifierOverride) {
  const mutable = ["initialization", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_output"].includes(event);
  const values = ir.selections.flatMap((screen) => screen.elements.map((item) => ({ ...item, screen: screen.number }))).filter((item) => item.name).map((item) => ({ name: item.name, ranges: item.kind === "select-option", screen: item.screen }));
  const dynamicWriteTargets = [];
  const dynamicTargetNames = new Set();
  for (const declaration of ir.declarations ?? []) {
    if (declaration.statement?.scope === "local" || !["data", "static", "tables"].includes(declaration.kind)) continue;
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
  return {
    event,
    selections: values,
    mutableValues: mutable,
    ucomm: event.startsWith("at_selection_screen") || event === "at_user_command" ? "iv_ucomm" : undefined,
    replacements: [
      ...Object.entries(ir.statePlan?.renames ?? {}),
      ...values.map((item) => [item.name, valueReference(item)]),
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
        ?? name.toLowerCase()),
    })),
    routines: ir.routines ?? [],
    subrc: event === "resume" ? "is_resume-subrc" : undefined,
    activeCommands,
    activePFKeys,
    guiStatusMetadata: ir.guiStatusMetadata ?? {},
    selectionState: ir.statePlan?.selectionState ?? {},
    dynamicWriteTargets,
    safeFieldSymbols: ir.safeFieldSymbols ?? [],
  };
}

function selectionStateTransport(ir, event) {
  const state = ir.statePlan?.selectionState ?? {};
  const values = ["initialization", "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio", "at_selection_screen_on_exit", "start_of_selection", "end_of_selection"].includes(event);
  if (!values) return { hydrate: [], flush: [] };
  const source = ["initialization", "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field", "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio"].includes(event) ? "ct_values" : "it_values";
  const hydrate = [];
  const flush = [];
  for (const [name, item] of Object.entries(state)) {
    hydrate.push(`${item.member} = ${source}[ name = '${name}' ]-${item.ranges ? "ranges" : "value"}.`);
    if (source === "ct_values") flush.push(`${source}[ name = '${name}' ]-${item.ranges ? "ranges" : "value"} = ${item.member}.`);
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
    lines.push(`mv_${field.name.toLowerCase()} = ct_values[ name = '${field.name}' ]-value.`);
  }
  if (current) lines.push("ENDIF.");
  return lines;
}

const SUSPENDING = /\b(CALL\s+SCREEN|CALL\s+SELECTION-SCREEN|CALL\s+TRANSACTION|SUBMIT\b.*\bAND\s+RETURN)\b/i;

const CONTROL_CLOSERS = new Map([
  ["If", "ENDIF."],
  ["Do", "ENDDO."],
  ["Loop", "ENDLOOP."],
  ["Case", "ENDCASE."],
  ["Try", "ENDTRY."],
  ["While", "ENDWHILE."],
]);

function continuationFor(ir, statement) {
  return ir.continuations?.find((item) => item.filename === statement.filename
    && item.span.start.line === statement.span.start.line
    && item.span.start.column === statement.span.start.column);
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
  return statements.findIndex((statement) => SUSPENDING.test(statement.text));
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
  const context = methodContext(ir, event, qualifierOverride);
  if (event === "at_selection_screen_value_req") {
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
  const continuation = index >= 0 ? continuationFor(ir, statements[index]) : undefined;
  let body = [
    ...transport.hydrate,
    ...lowered.map((item) => item.text),
    ...continuationClosers(continuation),
    ...transport.flush,
  ];
  const hasWriter = body.some((line) => line.includes("lo_writer->"));
  if (hasWriter) body = addWriterDeclaration(body);
  if (event === "start_of_selection" && context.activePFKeys?.length && !statements.some((statement) => statement.kind === "SetPFStatus")) {
    body.unshift(`io_session->get_list( )->set_status( VALUE #( status = 'LIST' active_pf_keys = VALUE #( ${context.activePFKeys.map((key) => `( ${key} )`).join(" ")} ) ) ).`);
  }
  if (event === "start_of_selection" && body.length) body.unshift(`io_session->get_list( )->set_title( '${ir.targetClassName}' ).`);
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
      if (event === "start_of_selection" && ir.localClasses?.length) {
        body.unshift("* TODO GGCONV-E305: local class definitions require separate global classes.");
      }
      if (event === "at_selection_screen" && ir.continuations?.length) body.push(...nestedSelectionCaptures(ir));
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
      ?? ir.routines?.find((item) => item.statements?.includes(statement));
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
      const context = methodContext(ir, "resume");
      lowered = lowerStatements(tail, context).map((item) => item.text);
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
    if (!mutable || seen.has(upper) || !/\bTYPE\s+(?:C|N|D|T|I|P|F|X|STRING|ABAP_BOOL)\b/i.test(body)) return;
    seen.add(upper);
    components.push({ name: upper, member: ir.statePlan?.renames?.[upper] ?? name.toLowerCase() });
  };
  for (const declaration of ir.declarations ?? []) {
    if (!["data", "static"].includes(declaration.kind) || declaration.complex) continue;
    const body = declaration.raw.replace(/^\s*(?:DATA|STATICS)\s*:??\s*/i, "").replace(/\.\s*$/, "");
    for (const part of body.split(",")) {
      const name = /^\s*([A-Z][A-Z0-9_]*)\b/i.exec(part)?.[1];
      if (name) add(name, part, declaration.kind === "data" || declaration.kind === "static");
    }
  }
  return components;
}

function dynproStateHydrate(ir) {
  return dynproStateComponents(ir).flatMap(({ name, member }) => [
    `IF line_exists( ct_values[ name = '${name}' ] ).`,
    `${member} = CONV #( ct_values[ name = '${name}' ]-value ).`,
    "ENDIF.",
  ]);
}

function dynproStateFlush(ir) {
  return dynproStateComponents(ir).flatMap(({ name, member }) => [
    `IF line_exists( ct_values[ name = '${name}' ] ).`,
    `ct_values[ name = '${name}' ]-value = CONV string( ${member} ).`,
    "ELSE.",
    `INSERT VALUE #( name = '${name}' value = CONV string( ${member} ) ) INTO TABLE ct_values.`,
    "ENDIF.",
  ]);
}

function routineBody(ir, routine) {
  const statements = truncateTerminalPaths(routine.statements ?? []);
  const index = suspensionIndex(statements);
  const active = index >= 0 ? statements.slice(0, index + 1) : statements;
  const context = methodContext(ir, "start_of_selection");
  const lowered = lowerStatements(active, context).map((item) => item.text);
  if (index >= 0) lowered.push(...continuationClosers(continuationFor(ir, statements[index])));
  if (lowered.some((line) => line.includes("lo_writer->"))) lowered = addWriterDeclaration(lowered);
  return lowered;
}

function dynproMethods(ir) {
  const metadata = ir.dynproMetadata;
  if (!metadata) {
    const todo = ["* TODO GGCONV-E502: supply dynpro metadata before activating this class."];
    return [
      method("zif_gg_dynpro_v1~get_initial_screen", ["RETURN."]),
      method("zif_gg_dynpro_v1~build_screens", todo),
      method("zif_gg_dynpro_v1~build_flow_logic", todo),
      method("zif_gg_dynpro_v1~initialization", ["RETURN."]),
      method("zif_gg_dynpro_v1~process_output_module", todo),
      method("zif_gg_dynpro_v1~process_input_module", todo),
      method("zif_gg_dynpro_v1~process_on_value_request", ["RETURN."]),
      method("zif_gg_dynpro_v1~process_on_help_request", ["RETURN."]),
    ];
  }
  const screenNumber = (value) => String(value ?? "").padStart(4, "0");
  const screens = Array.isArray(metadata.screens) ? metadata.screens : [];
  const initial = screenNumber(metadata.initialScreen ?? screens[0]?.number ?? "0100");
  const screenFields = (screen) => {
    const fields = [`number = '${screenNumber(screen.number)}'`];
    if (screen.title) fields.push(`title = ${literal(screen.title)}`);
    if (screen.nextScreen !== undefined) fields.push(`next_screen = '${screenNumber(screen.nextScreen)}'`);
    if (screen.modal) fields.push("modal = abap_true");
    if (screen.width !== undefined) fields.push(`width = ${screen.width}`);
    if (screen.height !== undefined) fields.push(`height = ${screen.height}`);
    return fields.join(" ");
  };
  const buildScreens = [];
  for (const screen of screens) {
    buildScreens.push(`io_builder->begin_screen( VALUE #( ${screenFields(screen)} ) ).`);
    for (const element of screen.elements ?? []) {
      if (element.kind === "text") buildScreens.push(`io_builder->add_text( VALUE #( text = ${literal(element.text ?? "")} ) ).`);
      else if (element.kind === "input") buildScreens.push(`io_builder->add_input_field( VALUE #( control = VALUE #( name = '${String(element.name ?? "").toUpperCase()}' ) ) ).`);
      else if (element.kind === "output") buildScreens.push(`io_builder->add_output_field( VALUE #( control = VALUE #( name = '${String(element.name ?? "").toUpperCase()}' ) ) ).`);
      else if (element.kind === "pushbutton") buildScreens.push(`io_builder->add_pushbutton( VALUE #( control = VALUE #( name = '${String(element.name ?? "").toUpperCase()}' ) text = ${literal(element.text ?? "")} ucomm = '${String(element.ucomm ?? "").toUpperCase()}' ) ).`);
    }
    buildScreens.push("io_builder->end_screen( ).");
  }
  const flowLogic = Array.isArray(metadata.flowLogic) ? metadata.flowLogic : [];
  const buildFlow = [];
  for (const screen of flowLogic) {
    buildFlow.push(`io_builder->begin_screen( '${screenNumber(screen.screen)}' ).`);
    for (const [phase, begin] of [["pbo", "begin_pbo"], ["pai", "begin_pai"]]) {
      const modules = screen[phase] ?? [];
      if (!modules.length) continue;
      buildFlow.push(`io_builder->${begin}( ).`);
      for (const item of modules) {
        const module = typeof item === "string" ? { name: item } : item;
        const flags = phase === "pai" ? " on_input = abap_true" : "";
        buildFlow.push(`io_builder->add_module( VALUE #( name = '${String(module.name ?? "").toUpperCase()}'${flags} ) ).`);
      }
      buildFlow.push("io_builder->end_processing( ).");
    }
    for (const [phase, begin, flag] of [["pov", "begin_value_request", "on_request"], ["poh", "begin_help_request", "on_request"]]) {
      const request = screen[phase];
      const modules = Array.isArray(request) ? request : request?.modules ?? [];
      if (!modules.length) continue;
      const field = Array.isArray(request) ? screen[`${phase}Field`] : request.field;
      if (field) buildFlow.push(`io_builder->${begin}( '${String(field).toUpperCase()}' ).`);
      else buildFlow.push(`io_builder->${begin}( '' ).`);
      for (const item of modules) {
        const module = typeof item === "string" ? { name: item } : item;
        buildFlow.push(`io_builder->add_module( VALUE #( name = '${String(module.name ?? "").toUpperCase()}' ${flag} = abap_true ) ).`);
      }
      buildFlow.push("io_builder->end_processing( ).");
    }
    buildFlow.push("io_builder->end_screen( ).");
  }
  const dispatch = (direction) => {
    const modules = ir.modules.filter((item) => item.direction === direction);
    if (!modules.length) return ["RETURN."];
    const lines = ["CASE is_context-module."];
    for (const module of modules) {
      const context = { ...methodContext(ir, "dynpro"), ucomm: "is_context-ucomm" };
      const body = lowerStatements(module.statements, context).map((item) => item.text);
      lines.push(`WHEN '${module.name}'.`, ...body);
    }
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
    statusLines.push(`IF is_context-screen = '${screenNumber(screen)}'.`);
    statusLines.push(`io_session->get_dialog( )->set_status( VALUE #( ${fields.join(" ")} ) ).`);
    statusLines.push("ENDIF.");
  }
  const stateHydrate = dynproStateHydrate(ir);
  const stateFlush = dynproStateFlush(ir);
  return [
    method("zif_gg_dynpro_v1~get_initial_screen", [`rv_screen = '${initial}'.`]),
    method("zif_gg_dynpro_v1~build_screens", buildScreens),
    method("zif_gg_dynpro_v1~build_flow_logic", buildFlow),
    method("zif_gg_dynpro_v1~initialization", stateFlush),
    method("zif_gg_dynpro_v1~process_output_module", [...stateHydrate, ...statusLines, ...dispatch("OUTPUT"), ...stateFlush]),
    method("zif_gg_dynpro_v1~process_input_module", [...stateHydrate, ...dispatch("INPUT"), ...stateFlush]),
    method("zif_gg_dynpro_v1~process_on_value_request", ["RETURN."]),
    method("zif_gg_dynpro_v1~process_on_help_request", ["RETURN."]),
  ];
}

export function emitClassSource(ir, options) {
  const className = ir.targetClassName.toLowerCase();
  const interfaces = interfaceOrder(ir);
  const members = dataMembers(ir);
  const definition = [`CLASS ${className} DEFINITION PUBLIC FINAL CREATE PUBLIC.`, "", "  PUBLIC SECTION.", ...interfaces.map((name) => `    INTERFACES ${name}.`), ""];
  if (members.length) definition.push("  PRIVATE SECTION.", ...members.flatMap((line) => line.split("\n").map((part) => `    ${part}`)), "");
  definition.push("ENDCLASS.", "", `CLASS ${className} IMPLEMENTATION.`, "");
  const implementation = [];
  if (ir.interfaces.includes("zif_gg_transaction_v1")) {
    implementation.push(method("zif_gg_transaction_v1~get_transaction", [`rs_transaction = VALUE #( tcode = '${ir.transactionCode}' description = '${String(ir.description).replaceAll("'", "''")}' ).`]));
  }
  if (ir.programKind === "module-pool") implementation.push(...dynproMethods(ir));
  else implementation.push(...reportMethods(ir));
  if (ir.interfaces.includes("zif_gg_list_processing_v1")) implementation.push(...listMethods(ir));
  if (ir.interfaces.includes("zif_gg_resumable_v1")) implementation.push(resumeMethod(ir));
  for (const routine of ir.routines) {
    implementation.push(method(routine.methodName, routineBody(ir, routine)));
  }
  implementation.push("ENDCLASS.", "");
  return `${header({ className: ir.targetClassName, ir, options })}${definition.join("\n")}\n${implementation.join("\n")}`.replace(/\r?\n/g, "\n");
}

export function lowerToScaffoldIR(ir, options, sourceMap = []) {
  const methods = [];
  if (ir.interfaces.includes("zif_gg_transaction_v1")) {
    methods.push(method("zif_gg_transaction_v1~get_transaction", [`rs_transaction = VALUE #( tcode = '${ir.transactionCode}' description = '${String(ir.description).replaceAll("'", "''")}' ).`]));
  }
  if (ir.programKind === "module-pool") methods.push(...dynproMethods(ir));
  else methods.push(...reportMethods(ir));
  if (ir.interfaces.includes("zif_gg_list_processing_v1")) methods.push(...listMethods(ir));
  if (ir.interfaces.includes("zif_gg_resumable_v1")) methods.push(resumeMethod(ir));
  for (const routine of ir.routines) {
    methods.push(method(routine.methodName, routineBody(ir, routine)));
  }
  return scaffoldIR({
    className: ir.targetClassName,
    transactionCode: ir.transactionCode,
    description: options.description,
    definition: { visibility: "public", final: true, create: "public" },
    transaction: { tcode: ir.transactionCode, description: options.description },
    interfaces: interfaceOrder(ir),
    members: dataMembers(ir),
    methods: methods.map(({ name, body, comment }) => ({ name, body: [...body], ...(comment ? { comment } : {}) })),
    screenBuilder: {
      kind: ir.programKind === "module-pool" ? "dynpro" : "selection-screen",
      selections: ir.selections,
      dynproMetadata: ir.dynproMetadata,
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
