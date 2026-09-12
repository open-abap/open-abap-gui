const TYPE_CODES = new Map([
  ["C", "C"], ["N", "N"], ["D", "D"], ["T", "T"], ["I", "I"], ["INT4", "I"],
  ["P", "P"], ["F", "F"], ["X", "X"], ["STRING", "STRING"],
]);

const MESSAGE_TYPES = {
  A: "message_type_abort", E: "message_type_error", I: "message_type_info", S: "message_type_success",
  W: "message_type_warning", X: "message_type_exit",
};

// The capability scanner consumes this registry before emission. Keeping the
// rule inventory next to the lowering visitor makes a newly parsed statement
// visible as an explicit capability gap instead of silently falling through.
export const LOWERING_RULES = new Map([
  ["Write", { kind: "list-write" }], ["Skip", { kind: "list-skip" }], ["Uline", { kind: "list-uline" }],
  ["NewLine", { kind: "list-new-line" }], ["Format", { kind: "list-format" }], ["SetBlank", { kind: "list-blank-lines" }],
  ["Reserve", { kind: "list-reserve" }], ["NewPage", { kind: "list-new-page" }], ["Stop", { kind: "terminal-stop" }],
  ["Message", { kind: "session-message" }], ["SetPFStatus", { kind: "session-status" }], ["SetTitlebar", { kind: "session-title" }],
  ["CallSelectionScreen", { kind: "dialog-call-selection-screen" }], ["CallScreen", { kind: "dialog-call-screen" }],
  ["Submit", { kind: "navigation-submit" }], ["CallTransaction", { kind: "navigation-call-transaction" }],
  ["Append", { kind: "internal-table-append" }], ["Collect", { kind: "internal-table-collect" }],
  ["InsertInternal", { kind: "internal-table-insert" }], ["DeleteInternal", { kind: "internal-table-delete" }],
  ["ModifyInternal", { kind: "internal-table-modify" }], ["ReadTable", { kind: "internal-table-read" }],
  ["Select", { kind: "open-sql-select" }], ["SelectLoop", { kind: "open-sql-select-loop" }], ["EndSelect", { kind: "open-sql-end-select" }],
  ["InsertDatabase", { kind: "open-sql-insert" }], ["UpdateDatabase", { kind: "open-sql-update" }],
  ["DeleteDatabase", { kind: "open-sql-delete" }], ["ModifyDatabase", { kind: "open-sql-modify" }],
  ["Clear", { kind: "statement" }], ["Add", { kind: "statement" }], ["Subtract", { kind: "statement" }],
  ["Multiply", { kind: "statement" }], ["Divide", { kind: "statement" }], ["Compute", { kind: "statement" }],
  ["Leave", { kind: "navigation-leave" }], ["SetScreen", { kind: "dialog-set-screen" }], ["LeaveScreen", { kind: "dialog-leave-screen" }],
  ["LeaveToScreen", { kind: "dialog-leave-to-screen" }], ["GetCursor", { kind: "list-cursor" }], ["ReadLine", { kind: "list-read-line" }],
  ["ModifyLine", { kind: "list-modify-line" }], ["Hide", { kind: "list-hide" }], ["Perform", { kind: "routine-call" }],
  ["Return", { kind: "control-return" }], ["Translate", { kind: "statement" }], ["LoopAtScreen", { kind: "selection-screen-state-loop" }],
  ["ModifyScreen", { kind: "selection-screen-state-mutation" }], ["Move", { kind: "assignment" }], ["If", { kind: "control-if" }],
  ["Else", { kind: "control-else" }], ["ElseIf", { kind: "control-elseif" }], ["EndIf", { kind: "control-end-if" }], ["Do", { kind: "control-do" }],
  ["EndDo", { kind: "control-end-do" }], ["Case", { kind: "control-case" }], ["When", { kind: "control-when" }],
  ["WhenOthers", { kind: "control-when-others" }], ["EndCase", { kind: "control-end-case" }], ["Loop", { kind: "control-loop" }],
  ["EndLoop", { kind: "control-end-loop" }], ["Try", { kind: "control-try" }], ["Catch", { kind: "control-catch" }],
  ["Cleanup", { kind: "control-cleanup" }], ["EndTry", { kind: "control-end-try" }], ["Data", { kind: "declaration" }], ["TypeBegin", { kind: "declaration" }], ["TypeEnd", { kind: "declaration" }], ["Constant", { kind: "declaration" }],
  ["Static", { kind: "declaration" }], ["Assign", { kind: "field-symbol-assign" }], ["FieldSymbol", { kind: "field-symbol-declaration" }], ["Comment", { kind: "comment" }], ["Empty", { kind: "empty" }],
]);

// Ordinary statements are preserved only through this allow-list. Classic
// event-only syntax must get a diagnostic instead of being copied into a
// generated method by a catch-all emitter.
export const METHOD_SAFE_STATEMENTS = new Set([
  "Append", "Collect", "InsertInternal", "DeleteInternal", "ModifyInternal", "ReadTable",
  "Clear", "Add", "Subtract", "Multiply", "Divide", "Compute",
  "Select", "SelectLoop", "EndSelect", "InsertDatabase", "UpdateDatabase", "DeleteDatabase", "ModifyDatabase",
]);

export const OPEN_SQL_STATEMENTS = new Set([
  "Select", "SelectLoop", "EndSelect", "InsertDatabase", "UpdateDatabase", "DeleteDatabase", "ModifyDatabase",
]);

export function isStaticOpenSql(statement) {
  if (!OPEN_SQL_STATEMENTS.has(statement.kind)) return true;
  const body = statement.text.replace(/'(?:''|[^'])*'/g, "");
  return !/\b(?:FROM|INTO|UPDATE|DELETE|MODIFY|INSERT)\s*\(/i.test(body)
    && !/\b(?:SELECT|INSERT|UPDATE|DELETE|MODIFY)\s+\(/i.test(body)
    && !/\bEXEC\s+SQL\b/i.test(body);
}

export function isMethodSafeLoop(statement) {
  if (statement.kind !== "Loop") return false;
  const body = statement.text.replace(/'(?:''|[^'])*'/g, "");
  return /^\s*LOOP\s+AT\s+[A-Z][A-Z0-9_]*(?:\s+ASSIGNING\s+<[^>]+>|\s+INTO\s+(?:DATA\s*\([^)]*\)|[A-Z][A-Z0-9_-]*))\b/i.test(body)
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

export function isDynamicWriteOperand(statement) {
  return Boolean(dynamicWriteOperand(statement));
}

function lowerDynamicWriteFallback(dynamic, context) {
  const dynamicName = "lv_ggconv_dynamic_name";
  const dynamicValue = "<ggconv_dynamic_value>";
  const rewritten = dynamic.rewrite(dynamicValue);
  const unsupportedFormatting = /\b(COLOR|CURRENCY|UNIT|EXPONENT|EDIT\s+MASK|NO-GROUPING|SIGN\s+AS\s+POSTFIX)\b/i.test(rewritten);
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

function splitMessageOperands(text) {
  const parts = [];
  let current = "";
  let quotedString = false;
  let depth = 0;
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (char === "'" && quotedString && text[index + 1] === "'") {
      current += "''";
      index++;
    } else if (char === "'") {
      quotedString = !quotedString;
      current += char;
    } else if (!quotedString && char === "(") {
      depth++;
      current += char;
    } else if (!quotedString && char === ")") {
      depth = Math.max(0, depth - 1);
      current += char;
    } else if (!quotedString && depth === 0 && /[\s,]/.test(char)) {
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

function replaceOutsideStrings(text, replacements) {
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
      if (!quotedString) result += applyReplacements(current, replacements);
      result += char;
      current = "";
      quotedString = !quotedString;
      continue;
    }
    if (quotedString) result += char;
    else current += char;
  }
  return result + (quotedString ? current : applyReplacements(current, replacements));
}

function applyReplacements(text, replacements) {
  let output = text;
  for (const [name, replacement] of replacements) {
    output = output.replace(new RegExp(`\\b${name}\\b`, "gi"), replacement);
  }
  return output;
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
  value = value.replace(/\bsy-ucomm\b/gi, context.ucomm ?? "iv_ucomm");
  value = value.replace(/\bsscrfields-ucomm\b/gi, context.ucomm ?? "iv_ucomm");
  value = value.replace(/\bsy-batch\b/gi, "io_session->get_context( )-program-batch");
  value = value.replace(/\bsy-subrc\b/gi, context.subrc ?? "sy-subrc");
  value = value.replace(/\bsy-index\b/gi, "sy-index");
  value = value.replace(/\bsy-lsind\b/gi, "io_session->get_list( )->get_context( )-level");
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
  }
  const kind = /\s+AS\s+(CHECKBOX|ICON|SYMBOL)\b/i.exec(rest)?.[1]?.toUpperCase();
  if (kind) rest = rest.replace(new RegExp(`\\s+AS\\s+${kind}\\b`, "i"), "");
  const additions = {
    noGap: /\bNO-GAP\b/i.test(rest),
    decimals: /\bDECIMALS\s+(\d+)/i.exec(rest)?.[1],
    round: /\bROUND\s+(\d+)/i.exec(rest)?.[1],
    noZero: /\bNO-ZERO\b/i.test(rest),
    noSign: /\bNO-SIGN\b/i.test(rest),
    justification: /\b(LEFT-JUSTIFIED|CENTERED|RIGHT-JUSTIFIED)\b/i.exec(rest)?.[1],
  };
  rest = rest
    .replace(/\bNO-GAP\b|\bNO-ZERO\b|\bNO-SIGN\b/gi, "")
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
  if (additions.round) format.push(`round = ${additions.round}`);
  if (additions.noZero) format.push("no_zero = abap_true");
  if (additions.noSign) format.push("no_sign = abap_true");
  if (additions.justification) {
    const name = additions.justification === "LEFT-JUSTIFIED" ? "left" : additions.justification === "CENTERED" ? "center" : "right";
    format.push(`justification = zif_gg_list_processing_types_v1=>justify_${name}`);
  }
  const fields = [`text = ${expressionText(rest, context)}`];
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

function parseFormat(raw) {
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
  if (colorNumber) fields.push(`color = ${colorNumber}`);
  if (colorName && colorNames[colorName]) fields.push(`color = zif_gg_list_processing_types_v1=>${colorNames[colorName]}`);
  for (const [keyword, field] of [["INTENSIFIED", "intensified"], ["INVERSE", "inverse"], ["HOTSPOT", "hotspot"], ["INPUT", "input"]]) {
    const match = new RegExp(`${keyword}\\s+(ON|OFF)`).exec(text);
    if (match) fields.push(`${field} = abap_${match[1] === "ON" ? "true" : "false"}`);
  }
  return `lo_writer->set_format( VALUE #( ${fields.join(" ")} ) ).`;
}

function parseMessage(raw, context) {
  const body = stripPeriod(raw).replace(/^MESSAGE\s+/i, "");
  const type = /TYPE\s+'?([AEISWX])'?/i.exec(body)?.[1]?.toUpperCase() ?? "I";
  const typeExpr = `zif_gg_session_types_v1=>${MESSAGE_TYPES[type]}`;
  const text = /^('(?:''|[^'])*')\s+TYPE/i.exec(body)?.[1];
  if (text) {
    const displayLike = /DISPLAY\s+LIKE\s+'?([AEISWX])'?/i.exec(body)?.[1]?.toUpperCase();
    return `io_session->message( VALUE #( type = ${typeExpr} text = ${text}${displayLike ? ` display_like = zif_gg_session_types_v1=>${MESSAGE_TYPES[displayLike]}` : ""} ) ).`;
  }
  const messageReference = /^([AEISWX])(\d{3})\(([A-Z0-9_]+)\)/i.exec(body);
  if (messageReference) {
    const withPart = /\bWITH\s+(.+)$/i.exec(body)?.[1] ?? "";
    const operands = splitMessageOperands(withPart);
    const fields = [
      "type = zif_gg_session_types_v1=>" + MESSAGE_TYPES[messageReference[1].toUpperCase()],
      "id = '" + messageReference[3].toUpperCase() + "'",
      "number = '" + messageReference[2] + "'",
    ];
    operands.slice(0, 4).forEach((operand, index) => fields.push("v" + (index + 1) + " = " + valueExpression(operand, context)));
    return "io_session->message( VALUE #( " + fields.join(" ") + " ) ).";
  }
  const reference = /^([A-Z0-9_]+)\((\d+)\)/i.exec(body);
  if (reference) {
    const withPart = /\bWITH\s+(.+)$/i.exec(body)?.[1] ?? "";
    const operands = splitMessageOperands(withPart);
    const fields = [
      "type = " + typeExpr,
      "id = '" + reference[1].toUpperCase() + "'",
      "number = '" + reference[2].padStart(3, "0") + "'",
    ];
    operands.slice(0, 4).forEach((operand, index) => fields.push("v" + (index + 1) + " = " + valueExpression(operand, context)));
    return "io_session->message( VALUE #( " + fields.join(" ") + " ) ).";
  }
  if (reference) return `io_session->message( VALUE #( type = ${typeExpr} id = '${reference[1].toUpperCase()}' number = '${reference[2].padStart(3, "0")}' ) ).`;
  return `io_session->message( VALUE #( type = ${typeExpr} text = ${expressionText(body.replace(/\s+TYPE\s+['"]?[AEISWX]['"]?$/i, ""), context)} ) ).`;
}

export function lowerStatement(statement, context) {
  const raw = statement.text.trim();
  const normalized = raw.replace(/\s+/g, " ").toUpperCase();
  if (statement.kind === "Comment") return raw;
  if (isMethodSafeLoop(statement)) return replaceOutsideStrings(raw, context.replacements);
  if (METHOD_SAFE_STATEMENTS.has(statement.kind)) {
    return replaceOutsideStrings(raw, context.replacements);
  }
  if (statement.kind === "Write") {
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
    if (/\b(COLOR|CURRENCY|UNIT|EXPONENT|EDIT\s+MASK|NO-GROUPING|SIGN\s+AS\s+POSTFIX)\b/i.test(raw)) {
      return "* TODO GGCONV-E501: unsupported WRITE formatting addition requires manual lowering.";
    }
    return parseWrite(raw, context);
  }
  if (statement.kind === "Format") return parseFormat(raw);
  if (statement.kind === "Skip") return `lo_writer->skip( ${stripPeriod(raw).replace(/^SKIP\s*/i, "") || "1"} ).`;
  if (statement.kind === "Uline") {
    const match = /AT\s+(\d+)(?:\((\d+)\))?/i.exec(raw);
    const placement = match ? `position = ${match[1]}${match[2] ? ` length = ${match[2]}` : ""}` : "";
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
  if (statement.kind === "Stop") return "io_session->stop( ).";
  if (statement.kind === "Message") return parseMessage(raw, context);
  if (statement.kind === "FieldSymbol") {
    const name = /<([A-Z][A-Z0-9_]*)>/i.exec(raw)?.[1]?.toUpperCase();
    return name && context.safeFieldSymbols?.includes(name) ? replaceOutsideStrings(raw, context.replacements) : undefined;
  }
  if (statement.kind === "Assign") {
    const name = /\bTO\s+<([A-Z][A-Z0-9_]*)>/i.exec(raw)?.[1]?.toUpperCase();
    return name && context.safeFieldSymbols?.includes(name) ? replaceOutsideStrings(raw, context.replacements) : undefined;
  }
  if (statement.kind === "SetPFStatus") {
    const name = /SET PF-STATUS\s+['"]?([^\s.'"]+)/i.exec(raw)?.[1];
    if (!name) return "* TODO GGCONV-E501: dynamic PF-STATUS.";
    const statusMetadata = context.guiStatusMetadata?.[name.toUpperCase()] ?? context.guiStatusMetadata?.[name] ?? {};
    const excluded = [...new Set([
      ...[...raw.matchAll(/EXCLUDING\s+['"]?([A-Z0-9_%+-]+)/gi)].map((match) => match[1].toUpperCase()),
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
    return `io_session->get_list( )->set_status( VALUE #( ${fields.join(" ")} ) ).`;
  }
  if (statement.kind === "Loop") {
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
    return title ? `io_session->get_list( )->set_title( '${title.toUpperCase()}' ).` : "* TODO GGCONV-E501: dynamic titlebar.";
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
    const variant = /USING\s+SELECTION-SET\s+'([^']+)'/i.exec(body)?.[1];
    if (variant) fields.push(`variant = '${variant.toUpperCase()}'`);
    if (/EXPORTING\s+LIST\s+TO\s+MEMORY/i.test(body)) fields.push("list_to_memory = abap_true");
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
  if (statement.kind === "CallFunction") {
    const target = /TABLES\s+([A-Z][A-Z0-9_]*)\s*=/i.exec(raw)?.[1];
    if (/CALL\s+FUNCTION\s+'LIST_FROM_MEMORY'/i.test(raw) && target) {
      return `${target} = io_session->get_navigation( )->get_list_from_memory( ).`;
    }
    return undefined;
  }
  if (statement.kind === "Leave") {
    if (/LIST-PROCESSING/i.test(raw)) return /TO LIST/i.test(raw) ? "io_session->get_list( )->enter_list_processing( )." : "io_session->get_list( )->leave_list_processing( ).";
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
  if (statement.kind === "LeaveScreen") return "io_session->get_dialog( )->leave_screen( ).";
  if (statement.kind === "LeaveToScreen") {
    const screen = /LEAVE\s+TO\s+SCREEN\s+(\d+)/i.exec(raw)?.[1];
    return screen ? `io_session->get_dialog( )->leave_to_screen( '${screen.padStart(4, "0")}' ).` : undefined;
  }
  if (statement.kind === "GetCursor") {
    const match = /GET\s+CURSOR\s+FIELD\s+([A-Z][A-Z0-9_-]*)(?:\s+LINE\s+([A-Z][A-Z0-9_-]*))?/i.exec(raw);
    if (!match) return "DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).";
    const assignments = [`${match[1]} = ls_cursor-field`];
    if (match[2]) assignments.push(`${match[2]} = ls_cursor-line`);
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
  if (statement.kind === "Hide") return "";
  if (statement.kind === "Perform") {
    if (/\bPERFORM\s+\(|\bIN\s+PROGRAM\b/i.test(raw)) return "* TODO GGCONV-E401: dynamic or external PERFORM requires a manual method mapping.";
    const name = /^PERFORM\s+([^\s.]+)/i.exec(raw)?.[1];
    const routine = context.routines?.find((item) => item.name === name?.toUpperCase());
    if (!routine) return name ? `me->form_${name.toLowerCase()}( ).` : "* TODO GGCONV-E401: dynamic PERFORM.";
    const argumentsByDirection = new Map();
    for (const section of raw.replace(/^PERFORM\s+[^\s.]+\s*/i, "").matchAll(/\b(USING|CHANGING|TABLES)\s+(.+?)(?=\s+(?:USING|CHANGING|TABLES)\s+|$)/gi)) {
      const direction = section[1].toUpperCase() === "USING" ? "EXPORTING" : "CHANGING";
      argumentsByDirection.set(direction, section[2].replace(/\.$/, "").split(/[\s,]+/).filter(Boolean));
    }
    if (!(routine.parameters ?? []).length) return `${routine.methodName}( io_session = io_session ).`;
    const parameterWidth = Math.max("io_session".length, ...(routine.parameters ?? []).map((parameter) => parameter.name.length));
    const fieldsByDirection = { EXPORTING: [`${"io_session".padEnd(parameterWidth, " ")} = io_session`], CHANGING: [] };
    for (const parameter of routine.parameters ?? []) {
      const values = argumentsByDirection.get(parameter.direction === "IMPORTING" ? "EXPORTING" : "CHANGING") ?? [];
      const value = values.shift();
      if (value) fieldsByDirection[parameter.direction === "IMPORTING" ? "EXPORTING" : "CHANGING"]
        .push(`${parameter.name.padEnd(parameterWidth, " ")} = ${valueExpression(value, context)}`);
    }
    const fields = Object.entries(fieldsByDirection).filter(([, values]) => values.length);
    const lines = [`${routine.methodName}(`];
    for (let directionIndex = 0; directionIndex < fields.length; directionIndex++) {
      const [direction, values] = fields[directionIndex];
      lines.push(`  ${direction}`);
      const isLastDirection = directionIndex === fields.length - 1;
      lines.push(...values.map((value, valueIndex) => `    ${value}${isLastDirection && valueIndex === values.length - 1 ? " )." : ""}`));
    }
    return lines.join("\n");
  }
  if (statement.kind === "Return") return "RETURN.";
  if (statement.kind === "Translate") return replaceOutsideStrings(raw, context.replacements);
  if (statement.kind === "Include") return "* INCLUDE expanded by converter.";
  if (statement.kind === "LoopAtScreen") return "LOOP AT ct_states ASSIGNING FIELD-SYMBOL(<ls_state>).";
  if (statement.kind === "ModifyScreen") return "* SCREEN state is already changed through <ls_state>.";
  if (["If", "Else", "ElseIf", "EndIf", "Do", "EndDo", "Case", "When", "WhenOthers", "EndCase", "Loop", "EndLoop", "Try", "Catch", "Cleanup", "EndTry", "Move"].includes(statement.kind)) {
    let converted = replaceOutsideStrings(raw, context.replacements).replace(/\bsy-ucomm\b/gi, context.ucomm ?? "iv_ucomm");
    converted = converted.replace(/\bsy-subrc\b/gi, context.subrc ?? "sy-subrc");
    converted = converted.replace(/\bsy-lsind\b/gi, "io_session->get_list( )->get_context( )-level");
    converted = converted.replace(/\bscreen-name\b/gi, "<ls_state>-name");
    converted = converted.replace(/\bscreen-group1\b/gi, "<ls_state>-modif_id");
    converted = converted.replace(/\bscreen-group([2-4])\b/gi, "<ls_state>-group$1");
    converted = converted.replace(/\bscreen-invisible\b/gi, "<ls_state>-visible");
    converted = converted.replace(/\bscreen-active\b/gi, "<ls_state>-enabled");
    converted = converted.replace(/\bscreen-(input|output)\b/gi, "<ls_state>-$1");
    if (statement.kind === "Move") {
      converted = converted.replace(/<ls_state>-visible\s*=\s*'1'/i, "<ls_state>-visible = abap_false");
      converted = converted.replace(/<ls_state>-visible\s*=\s*'0'/i, "<ls_state>-visible = abap_true");
      converted = converted.replace(/<ls_state>-input\s*=\s*'1'/i, "<ls_state>-input = abap_true");
      converted = converted.replace(/<ls_state>-input\s*=\s*'0'/i, "<ls_state>-input = abap_false");
      const target = /^\s*([A-Z][A-Z0-9_]*)\s*=/i.exec(raw)?.[1]?.toUpperCase();
      if (target && context.selectionState?.[target]) {
        const assignment = /^(\s*[^=]+\s*=\s*)([\s\S]+)\.$/.exec(converted);
        if (assignment && !/^['|]/.test(assignment[2].trim())) converted = `${assignment[1]}|{ ${assignment[2]} }|.`;
      }
    }
    return converted;
  }
  if (["Data", "DataBegin", "DataEnd", "Type", "TypeBegin", "TypeEnd", "Constant", "Static", "Comment", "Empty"].includes(statement.kind)) {
    const declaration = statement.kind === "Static" ? raw.replace(/^STATICS\b/i, "DATA") : raw;
    return replaceOutsideStrings(declaration, context.replacements);
  }
  return `* TODO GGCONV-E501: unsupported ${statement.kind} statement requires manual lowering.`;
}

export function lowerStatements(statements, context) {
  const output = [];
  let pendingHidden = [];
  let lastWriteIndex = -1;
  const rangeLoops = [];
  for (let index = 0; index < statements.length; index++) {
    const statement = statements[index];
    if (statement.kind === "Hide") {
      pendingHidden.push(...uniqueHiddenFields(hiddenFieldEntries(statement.text, context), pendingHidden));
      continue;
    }
    const statementContext = {
      ...context,
      replacements: [...rangeLoops, ...(context.replacements ?? []).filter(([name]) => !rangeLoops.some(([active]) => active === name))],
    };
    const lowerInput = statement.kind === "Write"
      && statements[index - 1]?.kind === "Uline"
      && /^WRITE\s*\//i.test(statement.text.trim())
      ? { ...statement, text: statement.text.replace(/^\s*WRITE\s*\/\s*/i, "WRITE ") }
      : statement;
    const lowered = lowerStatement(lowerInput, statementContext);
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
      output.push(item);
      if (statement.kind === "Write") lastWriteIndex = output.length - 1;
      if (statement.kind === "Loop") {
        const name = /^LOOP\s+AT\s+([A-Z][A-Z0-9_]*)\b/i.exec(statement.text.trim())?.[1]?.toUpperCase();
        if (context.selections?.some((selection) => selection.name === name && selection.ranges)) {
          rangeLoops.push([name, `ls_${name.toLowerCase()}_range`]);
        }
      }
      if (statement.kind === "EndLoop") rangeLoops.pop();
    } else output.push({
      text: `* TODO GGCONV-E501: unsupported statement omitted: ${statement.text.trim().replace(/\s+/g, " ")}`,
      statement,
      supported: false,
    });
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
