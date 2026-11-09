import { Expressions, Nodes, Statements } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import type { StatementAst, TokenEntry } from "../abap/ast.js";
import { isReference } from "./replace-identifiers.js";
import type { Declaration, HeaderLines, ReportIR, RoutineParameter, Statement } from "../types.js";

// A class has no header lines. A report's table with one - DATA ... WITH
// HEADER LINE, DATA BEGIN OF ... OCCURS, RANGES, SELECT-OPTIONS, and a FORM's
// TABLES parameter -
// becomes a table of the same name without one, plus a work area for the
// header line. Every statement that used the header line, implicitly as in
// LOOP AT itab. and APPEND itab., or by naming the table where a work area
// goes, uses the work area instead.

const SUFFIX = "_header";

function workAreaName(name: string, used: Set<string>): string {
  const base = name.toLowerCase().slice(0, 30 - SUFFIX.length);
  let candidate = `${base}${SUFFIX}`;
  for (let index = 2; used.has(candidate.toUpperCase()); index++) {
    const marker = `${SUFFIX}${index}`;
    candidate = `${base.slice(0, 30 - marker.length)}${marker}`;
  }
  used.add(candidate.toUpperCase());
  return candidate;
}

// The name DATA BEGIN OF name declares.
function beginName(raw: string): string | undefined {
  return statementAst(raw)?.sourceOf(Expressions.DefinitionName);
}

export function hasHeaderLine(declaration: Pick<Declaration, "kind" | "raw">): boolean {
  if (declaration.kind === "ranges" || declaration.kind === "select-option") return true;
  const ast = statementAst(declaration.raw ?? "");
  if (declaration.kind === "databegin") return /^DATA BEGIN OF _ OCCURS(?: |$)/.test(ast?.words() ?? "");
  const table = ast?.find(Expressions.TypeTable);
  return declaration.kind === "data" && Boolean(ast && table && ast.has("WITH HEADER LINE", table));
}

const DATA_KINDS = new Set(["data", "constant", "static", "tables", "databegin", "parameter", "select-option", "ranges"]);

// The declaration of the program's global data object of the given name; a
// name without one is a type, e.g. a dictionary structure.
export function globalDataDeclaration(ir: ReportIR, name: string): Declaration | undefined {
  const upper = name.toUpperCase();
  return (ir.declarations ?? []).find((item) => DATA_KINDS.has(item.kind) && item.statement?.scope !== "local"
    && (item.names ?? (item.name ? [item.name] : [beginName(item.raw)])).some((declared) => String(declared ?? "").toUpperCase() === upper));
}

// The work area a TABLES parameter's header line needs: the parameter's line
// type, if the FORM names one.
function parameterWorkArea(parameter: RoutineParameter, ir: ReportIR): string | undefined {
  const structure = parameter.structure;
  if (structure) {
    const base = structure.split("-")[0].toUpperCase();
    const table = (ir.headerLines?.global ?? {})[base];
    if (table) return `LIKE LINE OF ${structure.toLowerCase()}`;
    return `${globalDataDeclaration(ir, base) ? "LIKE" : "TYPE"} ${structure.toLowerCase()}`;
  }
  // TYPE and LIKE name a table type or a table, whose line the work area is.
  if (["TYPE", "LIKE"].includes(String(parameter.typing ?? "").split(" ")[0].toUpperCase())) return `LIKE LINE OF ${parameter.name}`;
  return undefined;
}

// Header-line tables by scope: the program's own, and per FORM its local ones
// and TABLES parameters, each mapped to the name of its work area.
export function collectHeaderLines(ir: ReportIR): HeaderLines {
  const used = new Set((ir.declarations ?? []).flatMap((item) => item.names ?? (item.name ? [item.name] : [])).map((name) => String(name).toUpperCase()));
  const routineOf = (statement: Statement) => (ir.routines ?? []).find((routine) => routine.statements?.includes(statement));
  const result: HeaderLines = { global: {}, routines: {}, parameters: {} };
  for (const declaration of ir.declarations ?? []) {
    if (!hasHeaderLine(declaration) || declaration.statement?.localClassName) continue;
    const name = declaration.kind === "databegin"
      ? beginName(declaration.raw)?.toUpperCase()
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
export function headerLinesIn(ir: ReportIR, routineName?: string): Record<string, string> {
  return { ...(ir.headerLines?.global ?? {}), ...(routineName ? ir.headerLines?.routines?.[routineName] ?? {} : {}) };
}

export function headerLinesOf(ir: ReportIR, statement: Statement): Record<string, string> {
  const routine = (ir.routines ?? []).find((item) => item.statements?.includes(statement));
  return headerLinesIn(ir, routine?.name);
}

// `TYPE x OCCURS n` and `LIKE x OCCURS n` are standard tables of x; OCCURS and
// WITH HEADER LINE do not exist in a class. LIKE a header-line table names its
// header line, which is the work area in the class.
function tableTyping(ast: StatementAst, isDataObject: (operand: string) => boolean, headerLines: Record<string, string>): string {
  const definition = ast.find(Expressions.DataDefinition)!;
  const name = definition.findDirectExpression(Expressions.DefinitionName)!;
  const text = ast.text.slice(ast.end(name), ast.end(definition)).trim();
  const table = definition.findDirectExpression(Expressions.TypeTable);
  const words = table ? ast.skeleton(table) : "";
  if (table && /^(?:TYPE|LIKE) _ OCCURS _(?: WITH HEADER LINE)?$/.test(words)) {
    const keyword = words.split(" ")[0];
    const operand = ast.source(table.getChildren()[1]);
    const [base, ...components] = operand.split("-");
    const header = keyword === "LIKE" ? headerLines[base.toUpperCase()] : undefined;
    if (header) return `LIKE STANDARD TABLE OF ${[header, ...components].join("-")} WITH DEFAULT KEY`;
    return `${keyword === "LIKE" && isDataObject(operand) ? "LIKE" : "TYPE"} STANDARD TABLE OF ${operand} WITH DEFAULT KEY`;
  }
  // WITH HEADER LINE ends the definition; the table keeps the rest.
  const children = table?.getChildren() ?? [];
  const tail = children.slice(-3).map((child) => child.getFirstToken().getUpperStr()).join(" ");
  if (table && tail === "WITH HEADER LINE") return ast.text.slice(ast.end(name), ast.start(children.at(-3)!)).trim();
  return text;
}

// The declarations replacing one DATA statement of a header-line table.
export function headerLineDeclarations(raw: string, header: string, isDataObject: (operand: string) => boolean = () => true, headerLines: Record<string, string> = {}): string[] {
  const ast = statementAst(raw.trim());
  const name = ast?.find(Expressions.DefinitionName);
  if (!ast || !name) return [raw];
  const variable = ast.source(name).toLowerCase();
  return [`DATA ${variable} ${tableTyping(ast, isDataObject, headerLines)}.`, `DATA ${header} LIKE LINE OF ${variable}.`];
}

// DATA BEGIN OF itab OCCURS n declares the header line; the table is declared
// after END OF, of that line.
export function headerLineBegin(raw: string, header: string): string {
  const ast = statementAst(raw);
  const name = ast?.findDirect(Expressions.DefinitionName);
  const occurs = ast?.findDirect(Expressions.Integer);
  if (!ast || !name || !occurs) return raw;
  return `${raw.slice(0, ast.start(name))}${header}${raw.slice(ast.end(occurs))}`;
}

export function headerLineEnd(raw: string, name: string, header: string): string[] {
  const ast = statementAst(raw);
  const definition = ast?.findDirect(Expressions.DefinitionName);
  const end = ast && definition ? `${raw.slice(0, ast.start(definition))}${header}${raw.slice(ast.end(definition))}` : raw;
  return [
    end.replace(/,\s*$/, "."),
    `DATA ${name.toLowerCase()} LIKE STANDARD TABLE OF ${header} WITH DEFAULT KEY.`,
  ];
}

// The result of LOOP AT and READ TABLE: INTO, ASSIGNING, REFERENCE INTO or
// TRANSPORTING NO FIELDS. Without one they use the header line.
function hasResult(ast: StatementAst): boolean {
  return Boolean(ast.findDirect(Expressions.LoopTarget) ?? ast.findDirect(Expressions.ReadTableTarget));
}

// The short forms that use the header line without naming it, written with
// the work area.
function explicitShortForm(text: string, ast: StatementAst, name: string, header: string): string {
  const children = ast.node.getChildren();
  const operand = children.find((child) => child instanceof Nodes.ExpressionNode);
  const named = operand && ast.source(operand).toUpperCase() === name;
  if (!operand || !named) return text;
  const insertAt = (offset: number, addition: string) => `${text.slice(0, offset)}${addition}${text.slice(offset)}`;
  const operandEnd = ast.end(operand);
  if (ast.is(Statements.Loop) && !hasResult(ast)) return insertAt(operandEnd, ` INTO ${header}`);
  if (ast.is(Statements.ReadTable) && !hasResult(ast)) {
    const rest = ast.words().replace(/^READ TABLE _/, "").trim();
    // Without a key, the header line's key fields are the key.
    if (!rest || rest === "BINARY SEARCH") return insertAt(operandEnd, ` FROM ${header} INTO ${header}`);
    const before = children.find((child) => child instanceof Nodes.TokenNode && ["TRANSPORTING", "COMPARING"].includes(child.getFirstToken().getUpperStr()));
    return insertAt(before ? ast.start(before) - 1 : ast.end(children.at(-2)!), ` INTO ${header}`);
  }
  if (ast.is(Statements.Append) && !ast.hasPhrase("TO") && !ast.hasPhrase("LINES OF")) {
    return `${text.slice(0, ast.start(operand))}${header} TO ${text.slice(ast.start(operand))}`;
  }
  if ((ast.is(Statements.Collect) || ast.is(Statements.InsertInternal)) && !ast.hasPhrase("INTO")) {
    const keyword = text.slice(ast.start(children[0]), ast.end(children[0]));
    const tableKeyword = ast.is(Statements.InsertInternal) && ast.hasPhrase("TABLE") ? "TABLE " : "";
    return `${keyword} ${header} INTO ${tableKeyword}${text.slice(ast.start(operand))}`;
  }
  if (ast.is(Statements.ModifyInternal) && !ast.hasPhrase("FROM")) return insertAt(operandEnd, ` FROM ${header}`);
  if (ast.is(Statements.DeleteInternal) && /^DELETE TABLE _/.test(ast.words()) && !ast.hasPhrase("FROM") && !ast.hasPhrase("WITH")) {
    return insertAt(operandEnd, ` FROM ${header}`);
  }
  return text;
}

// Whether an occurrence of the table names the table itself rather than its
// header line: after TABLE, LINES OF, IN, LOOP AT, lines( ), as the table of
// SORT, REFRESH, FREE, DELETE and MODIFY, as the table APPEND ... TO, INSERT
// ... INTO and COLLECT ... INTO add to, and in a TABLES section of a PERFORM
// or CALL FUNCTION.
function denotesTable(ast: StatementAst, entry: TokenEntry): boolean {
  const tokens = ast.tokens().filter((item) => item.statement === entry.statement && item.start < entry.start);
  // An escaped Open SQL host variable, as in IN @itab, is the same operand.
  if (tokens.at(-1)?.token.getStr() === "@") tokens.pop();
  const words = tokens.map((item) => item.token.getUpperStr());
  const last = words.at(-1);
  const pair = words.slice(-2).join(" ");
  if (["SORT", "REFRESH", "FREE", "DELETE", "MODIFY"].includes(last ?? "")) return words.length === 1;
  if (last === "TABLE" || last === "IN" || pair === "LINES OF" || pair === "LINE OF" || pair === "LOOP AT"
      || pair === "LINES (" || pair === "DUPLICATES FROM") return true;
  const statement = words[0];
  if (statement === "APPEND" && last === "TO") return true;
  if ((statement === "INSERT" || statement === "COLLECT") && last === "INTO") return true;
  return entry.ancestors.some((node) => node.get() instanceof Expressions.PerformTables || node.get() instanceof Expressions.ParameterListT);
}

// The statement written without header lines, for the header-line tables in
// scope, NAME -> work area.
export function withoutHeaderLines(text: string, headerLines: Record<string, string> | undefined): string {
  const names = Object.keys(headerLines ?? {});
  if (!names.length) return text;
  let output = text;
  for (const name of names) {
    const first = statementAst(output);
    if (!first?.tokens().some((entry) => entry.token.getUpperStr() === name && isReference(entry))) continue;
    const header = headerLines![name];
    output = explicitShortForm(output, first, name, header);
    const ast = statementAst(output);
    if (!ast) continue;
    // In SELECT ... FOR ALL ENTRIES IN itab, itab-comp is a column of the table.
    const allEntries = ast.find(Expressions.SQLForAllEntries);
    const allEntriesTable = allEntries ? ast.source(allEntries).split(/\s+/).at(-1)?.toUpperCase() : undefined;
    const tokens = ast.tokens();
    let result = "";
    let last = 0;
    for (const [index, entry] of tokens.entries()) {
      if (entry.token.getUpperStr() !== name || !isReference(entry)) continue;
      const next = tokens[index + 1];
      if (allEntriesTable === name && next?.token.getStr() === "-" && next.start === entry.end) continue;
      const body = next?.parent.get() instanceof Expressions.TableBody ? next.parent : undefined;
      if (body) {
        // itab[] is the table.
        result += output.slice(last, entry.end);
        last = ast.end(body);
      } else if (!(next?.token.getStr() === "[" && next.start === entry.end) && !denotesTable(ast, entry)) {
        result += output.slice(last, entry.start) + header;
        last = entry.end;
      }
    }
    output = result + output.slice(last);
  }
  return output;
}
