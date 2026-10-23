import { maskedCode, nameOffsets } from "./replace-identifiers.mjs";

// A class has no header lines. A report's table with one - DATA ... WITH
// HEADER LINE, DATA BEGIN OF ... OCCURS, RANGES, SELECT-OPTIONS, and a FORM's
// TABLES parameter -
// becomes a table of the same name without one, plus a work area for the
// header line. Every statement that used the header line, implicitly as in
// LOOP AT itab. and APPEND itab., or by naming the table where a work area
// goes, uses the work area instead.

const SUFFIX = "_header";

function workAreaName(name, used) {
  const base = name.toLowerCase().slice(0, 30 - SUFFIX.length);
  let candidate = `${base}${SUFFIX}`;
  for (let index = 2; used.has(candidate.toUpperCase()); index++) {
    const marker = `${SUFFIX}${index}`;
    candidate = `${base.slice(0, 30 - marker.length)}${marker}`;
  }
  used.add(candidate.toUpperCase());
  return candidate;
}

export function hasHeaderLine(declaration) {
  const raw = declaration.raw ?? "";
  if (declaration.kind === "ranges" || declaration.kind === "select-option") return true;
  if (declaration.kind === "databegin") return /\bBEGIN\s+OF\s+[A-Z][A-Z0-9_]*\s+OCCURS\b/i.test(raw);
  return declaration.kind === "data" && /\bWITH\s+HEADER\s+LINE\b/i.test(raw);
}

// The work area a TABLES parameter's header line needs: the parameter's line
// type, if the FORM names one.
function parameterWorkArea(parameter, ir) {
  const typing = String(parameter.typing ?? "");
  const structure = /^STRUCTURE\s+([A-Z][A-Z0-9_\/]*(?:-[A-Z][A-Z0-9_]*)*)$/i.exec(typing)?.[1];
  if (structure) {
    const base = structure.split("-")[0].toUpperCase();
    const table = (ir.headerLines?.global ?? {})[base];
    if (table) return `LIKE LINE OF ${structure.toLowerCase()}`;
    const data = (ir.declarations ?? []).some((item) => ["data", "static", "tables", "databegin"].includes(item.kind)
      && (item.names ?? [/BEGIN\s+OF\s+([A-Z][A-Z0-9_]*)/i.exec(item.raw ?? "")?.[1]]).some((name) => String(name ?? "").toUpperCase() === base));
    return `${data ? "LIKE" : "TYPE"} ${structure.toLowerCase()}`;
  }
  // TYPE and LIKE name a table type or a table, whose line the work area is.
  if (/^(?:TYPE|LIKE)\s+/i.test(typing)) return `LIKE LINE OF ${parameter.name}`;
  return undefined;
}

// Header-line tables by scope: the program's own, and per FORM its local ones
// and TABLES parameters, each mapped to the name of its work area.
export function collectHeaderLines(ir) {
  const used = new Set((ir.declarations ?? []).flatMap((item) => item.names ?? (item.name ? [item.name] : [])).map((name) => String(name).toUpperCase()));
  const routineOf = (statement) => (ir.routines ?? []).find((routine) => routine.statements?.includes(statement));
  const result = { global: {}, routines: {}, parameters: {} };
  for (const declaration of ir.declarations ?? []) {
    if (!hasHeaderLine(declaration) || declaration.statement?.localClassName) continue;
    const name = declaration.kind === "databegin"
      ? /\bBEGIN\s+OF\s+([A-Z][A-Z0-9_]*)/i.exec(declaration.raw)?.[1]?.toUpperCase()
      : (declaration.names?.[0] ?? declaration.name)?.toUpperCase();
    if (!name) continue;
    const routine = declaration.statement?.scope === "local" ? routineOf(declaration.statement) : undefined;
    if (declaration.statement?.scope === "local" && !routine) continue;
    // A select-option's table is its member; the work area only exists when
    // some statement reads or writes the header line.
    if (declaration.kind === "select-option" && !(ir.statements ?? []).some((statement) => statement.kind !== "SelectOption"
      && /\bggconv_header_probe\b/.test(withoutHeaderLines(statement.text ?? "", { [name]: "ggconv_header_probe" })))) continue;
    const scope = routine ? (result.routines[routine.name] ??= {}) : result.global;
    scope[name] ??= workAreaName(name, used);
  }
  ir.headerLines = result;
  for (const routine of ir.routines ?? []) {
    for (const parameter of routine.parameters ?? []) {
      if (parameter.section !== "TABLES") continue;
      const typing = parameterWorkArea(parameter, ir);
      if (!typing) continue;
      const header = workAreaName(parameter.name.toUpperCase(), used);
      (result.routines[routine.name] ??= {})[parameter.name.toUpperCase()] = header;
      (result.parameters[routine.name] ??= []).push(`DATA ${header} ${typing}.`);
    }
  }
  return result;
}

// The header-line tables a statement of the given routine sees.
export function headerLinesIn(ir, routineName) {
  return { ...(ir.headerLines?.global ?? {}), ...(routineName ? ir.headerLines?.routines?.[routineName] ?? {} : {}) };
}

export function headerLinesOf(ir, statement) {
  const routine = (ir.routines ?? []).find((item) => item.statements?.includes(statement));
  return headerLinesIn(ir, routine?.name);
}

// `TYPE x OCCURS n` and `LIKE x OCCURS n` are standard tables of x; OCCURS and
// WITH HEADER LINE do not exist in a class.
function tableTyping(definition, isDataObject) {
  const occurs = /^(TYPE|LIKE)\s+(\S+)\s+OCCURS\s+\S+(?:\s+WITH\s+HEADER\s+LINE)?\s*$/i.exec(definition);
  if (occurs) {
    const keyword = occurs[1].toUpperCase() === "LIKE" && isDataObject(occurs[2]) ? "LIKE" : "TYPE";
    return `${keyword} STANDARD TABLE OF ${occurs[2]} WITH DEFAULT KEY`;
  }
  return definition.replace(/\s+WITH\s+HEADER\s+LINE\s*$/i, "");
}

// The declarations replacing one DATA statement of a header-line table.
export function headerLineDeclarations(raw, header, isDataObject = () => true) {
  const text = raw.trim().replace(/[.,]\s*$/, "");
  const match = /^DATA\s*:?\s*([A-Z][A-Z0-9_]*)\s+([\s\S]+)$/i.exec(text);
  if (!match) return [raw];
  const name = match[1].toLowerCase();
  return [`DATA ${name} ${tableTyping(match[2].trim(), isDataObject)}.`, `DATA ${header} LIKE LINE OF ${name}.`];
}

// DATA BEGIN OF itab OCCURS n declares the header line; the table is declared
// after END OF, of that line.
export function headerLineBegin(raw, header) {
  return raw.replace(/\bBEGIN\s+OF\s+[A-Z][A-Z0-9_]*\s+OCCURS\s+\S+?(?=\s*[,.]?\s*$)/i, `BEGIN OF ${header}`);
}

export function headerLineEnd(raw, name, header) {
  return [
    raw.replace(/\bEND\s+OF\s+[A-Z][A-Z0-9_]*/i, `END OF ${header}`).replace(/,\s*$/, "."),
    `DATA ${name.toLowerCase()} LIKE STANDARD TABLE OF ${header} WITH DEFAULT KEY.`,
  ];
}

const RESULT = /\b(?:INTO|ASSIGNING|REFERENCE\s+INTO|TRANSPORTING\s+NO\s+FIELDS)\b/i;

// The short forms that use the header line without naming it, written with
// the work area.
function explicitShortForm(text, code, name, header) {
  const table = `(${name})\\b`;
  const statement = (pattern) => new RegExp(`^(\\s*${pattern})`, "i").exec(code);
  const insertAt = (offset, addition) => `${text.slice(0, offset)}${addition}${text.slice(offset)}`;
  const end = /\s*[.,]?\s*$/.exec(code).index;
  let match = statement(`LOOP\\s+AT\\s+${table}`);
  if (match && !RESULT.test(code)) return insertAt(match[1].length, ` INTO ${header}`);
  match = statement(`READ\\s+TABLE\\s+${table}`);
  if (match && !RESULT.test(code)) {
    const rest = code.slice(match[1].length, end);
    // Without a key, the header line's key fields are the key.
    if (!rest.trim() || /^\s*BINARY\s+SEARCH\s*$/i.test(rest)) return insertAt(match[1].length, ` FROM ${header} INTO ${header}`);
    const before = /\s(?:TRANSPORTING|COMPARING)\b/i.exec(rest);
    return insertAt(before ? match[1].length + before.index : end, ` INTO ${header}`);
  }
  match = statement(`APPEND\\s+${table}`);
  if (match && !/\bTO\b/i.test(code.slice(match[1].length))) {
    return `${text.slice(0, match[1].length - match[2].length)}${header} TO ${match[2]}${text.slice(match[1].length)}`;
  }
  match = statement(`(?:COLLECT|INSERT)\\s+(?:TABLE\\s+)?${table}`);
  if (match && !/\bINTO\b/i.test(code.slice(match[1].length))) {
    const keyword = /^\s*(COLLECT|INSERT)/i.exec(code)[1];
    const tableKeyword = /^\s*INSERT\s+TABLE\b/i.test(code) ? "TABLE " : "";
    return `${keyword} ${header} INTO ${tableKeyword}${match[2]}${text.slice(match[1].length)}`;
  }
  match = statement(`MODIFY\\s+(?:TABLE\\s+)?${table}`);
  if (match && !/\bFROM\b/i.test(code.slice(match[1].length))) return insertAt(match[1].length, ` FROM ${header}`);
  match = statement(`DELETE\\s+TABLE\\s+${table}`);
  if (match && !/\b(?:FROM|WITH)\b/i.test(code.slice(match[1].length))) return insertAt(match[1].length, ` FROM ${header}`);
  return text;
}

// Keywords after which a table operand stands for the table, not its header line.
const TABLE_KEYWORD = /(?:\bTABLE|\bLINES?\s+OF|\bIN|\bLOOP\s+AT|\blines\(|\bSORT|\bREFRESH|\bFREE|\bDELETE(?:\s+ADJACENT\s+DUPLICATES\s+FROM)?|\bMODIFY)\s*$/i;

function denotesTable(code, start, end, statementKeyword, tablesSection) {
  if (/^\[/.test(code.slice(end))) return true;
  // An escaped Open SQL host variable, as in IN @itab, is the same operand.
  const before = code.slice(0, start).replace(/@$/, "");
  if (TABLE_KEYWORD.test(before)) {
    // DELETE, MODIFY, SORT, REFRESH and FREE name the table right after the keyword.
    if (/\b(?:DELETE|MODIFY|SORT|REFRESH|FREE)\s*$/i.test(before)) return /^\s*(?:DELETE|MODIFY|SORT|REFRESH|FREE)\s*$/i.test(before) || /\bDUPLICATES\s+FROM\s*$/i.test(before);
    return true;
  }
  if (statementKeyword === "APPEND" && /\bTO\s*$/i.test(before)) return true;
  if ((statementKeyword === "INSERT" || statementKeyword === "COLLECT") && /\bINTO\s*$/i.test(before)) return true;
  return tablesSection(start);
}

// Whether the operand at an offset is passed in a TABLES section of a PERFORM
// or CALL FUNCTION.
function tablesSections(code) {
  const sections = [...code.matchAll(/\b(TABLES|USING|CHANGING|EXPORTING|IMPORTING|EXCEPTIONS)\b/gi)];
  return (offset) => sections.filter((match) => match.index < offset).at(-1)?.[1]?.toUpperCase() === "TABLES";
}

// The statement written without header lines, for the header-line tables in
// scope, NAME -> work area.
export function withoutHeaderLines(text, headerLines) {
  const names = Object.keys(headerLines ?? {});
  if (!names.length) return text;
  let output = text;
  for (const name of names) {
    if (!new RegExp(`\\b${name}\\b`, "i").test(maskedCode(output))) continue;
    const header = headerLines[name];
    output = explicitShortForm(output, maskedCode(output), name, header);
    const code = maskedCode(output);
    const statementKeyword = /^\s*([A-Z]+)/i.exec(code)?.[1]?.toUpperCase();
    const tablesSection = /^\s*(?:PERFORM|CALL\s+FUNCTION)\b/i.test(code) ? tablesSections(code) : () => false;
    // In SELECT ... FOR ALL ENTRIES IN itab, itab-comp is a column of the table.
    const allEntries = new RegExp(`\\bFOR\\s+ALL\\s+ENTRIES\\s+IN\\s+${name}\\b`, "i").test(code);
    const offsets = nameOffsets(code);
    let result = "";
    let last = 0;
    for (const match of code.matchAll(new RegExp(`\\b${name}\\b`, "gi"))) {
      const start = match.index;
      const end = start + match[0].length;
      if (offsets.has(start) || (allEntries && code[end] === "-")) continue;
      if (/^\[\s*\]/.test(code.slice(end))) {
        // itab[] is the table.
        result += output.slice(last, end);
        last = end + /^\[\s*\]/.exec(code.slice(end))[0].length;
      } else if (!denotesTable(code, start, end, statementKeyword, tablesSection)) {
        result += output.slice(last, start) + header;
        last = end;
      }
    }
    output = result + output.slice(last);
  }
  return output;
}
