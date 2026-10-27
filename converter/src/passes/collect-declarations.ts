import { Expressions } from "@abaplint/core";
import { lexedAst, statementAst } from "../abap/ast.js";
import type { StatementAst } from "../abap/ast.js";
import type { Declaration, Statement } from "../types.js";

const DECLARATION_KINDS = new Set([
  "Data", "DataBegin", "DataEnd", "Parameter", "SelectOption", "SelectionScreen", "Tables", "Ranges", "Type", "TypeBegin", "TypeEnd", "IncludeType", "Constant", "ConstantBegin", "ConstantEnd", "Static", "FieldSymbol",
]);

type DeclarationInfo = Omit<Declaration, "statement">;

// What follows a node to the end of the statement, without its period. A
// chain element keeps its comma, which the emitters remove where they need to.
function after(raw: string, ast: StatementAst, node: Parameters<StatementAst["end"]>[0]): string {
  return raw.replace(/\.$/, "").slice(ast.end(node)).trim();
}

export function declarationInfo(statement: Pick<Statement, "kind" | "text">): DeclarationInfo {
  const raw = statement.text.replace(/\s+/g, " ").trim();
  const ast = statementAst(raw);
  const upper = (node: Parameters<StatementAst["source"]>[0] | undefined) => node && ast ? ast.source(node).toUpperCase() : undefined;
  if (["Data", "Constant", "Static"].includes(statement.kind)) {
    const definition = ast?.find(Expressions.DefinitionName);
    const name = upper(definition);
    const entries = name && ast && definition ? [{ name, definition: after(raw, ast, definition).replace(/,$/, "").trim() }] : [];
    const words = ast?.words() ?? "";
    return {
      kind: statement.kind === "Data" ? "data" : statement.kind === "Constant" ? "constant" : "static",
      names: entries.map((entry) => entry.name),
      entries,
      raw,
      complex: statement.kind === "Data" && /\b(?:BEGIN|END) OF\b/.test(words),
    };
  }
  if (statement.kind === "FieldSymbol") {
    const name = ast?.findDirect(Expressions.FieldSymbol);
    return { kind: "field-symbol", names: name && ast ? [ast.source(name).slice(1, -1).toUpperCase()] : [], raw };
  }
  if (statement.kind === "Parameter" || statement.kind === "SelectOption") {
    const name = ast?.findDirect(Expressions.FieldSub);
    return {
      kind: statement.kind === "Parameter" ? "parameter" : "select-option",
      name: upper(name),
      raw,
      additions: name && ast ? after(raw, ast, name) : "",
    };
  }
  if (statement.kind === "Tables") {
    const name = upper(ast?.findDirect(Expressions.Field));
    if (!name) return { kind: "tables", names: [], raw };
    // TABLES *dbtab is a second work area of dbtab, see renameStarWorkAreas.
    const table = name.replace(/^\*/, "");
    return { kind: "tables", names: [name.startsWith("*") ? starWorkArea(table).toUpperCase() : table], table, raw };
  }
  if (statement.kind === "Ranges") {
    const name = upper(ast?.findDirect(Expressions.DefinitionName));
    const target = ast?.findDirect(Expressions.SimpleFieldChain2);
    return { kind: "ranges", names: name ? [name] : [], target: target && ast ? raw.replace(/\.$/, "").slice(ast.start(target)).trim().toUpperCase() : undefined, raw };
  }
  if (statement.kind === "Type") {
    const name = ast?.findDirect(Expressions.NamespaceSimpleName);
    return { kind: "type", names: name ? [upper(name)!] : [], typeExpression: name && ast ? after(raw, ast, name) : undefined, raw };
  }
  if (statement.kind === "TypeBegin" || statement.kind === "TypeEnd") {
    const name = upper(ast?.findDirect(Expressions.NamespaceSimpleName));
    return { kind: statement.kind.toLowerCase(), names: name ? [name] : [], raw, complex: true };
  }
  // INCLUDE TYPE / INCLUDE STRUCTURE only occurs as a component of a BEGIN OF
  // structure, so it is emitted as part of that structure, never on its own.
  if (statement.kind === "IncludeType") return { kind: "includetype", names: [], raw, complex: true };
  return { kind: statement.kind.toLowerCase(), raw };
}

function starWorkArea(table: string): string {
  return `star_${table.toLowerCase()}`.slice(0, 30);
}

// TABLES *dbtab declares a second work area of dbtab, named *dbtab, which is
// no name in a class. It is named star_dbtab, in every statement that uses it;
// SELECT ... FROM *dbtab reads dbtab into it, see tablesWorkAreaSelect.
export function renameStarWorkAreas(statements: Statement[]): void {
  const tables = new Set(statements
    .filter((statement) => statement.kind === "Tables")
    .map((statement) => statementAst(statement.text)?.sourceOf(Expressions.Field)?.toUpperCase())
    .filter((name): name is string => Boolean(name?.startsWith("*"))));
  if (!tables.size) return;
  for (const statement of statements) {
    if (statement.kind === "Tables" || statement.kind === "Comment") continue;
    const occurrences = (lexedAst(statement.text)?.tokens() ?? [])
      .filter((entry) => tables.has(entry.token.getUpperStr()))
      .reverse();
    for (const { start, end, token } of occurrences) {
      statement.text = `${statement.text.slice(0, start)}${starWorkArea(token.getStr().slice(1))}${statement.text.slice(end)}`;
    }
  }
}

// DATA: BEGIN OF s, f TYPE i, END OF s. declares s, not f: a component is part
// of its structure's declaration and has no name of its own in the program, so
// two structures can share component names. Its names are kept as
// componentNames, out of the names and entries every symbol consumer reads.
// The parts of a COMMON PART are data objects in their own right.
function isCommonPart(statement: Statement): boolean {
  return /^DATA (?:BEGIN|END) OF COMMON PART(?: |$)/.test(statementAst(statement.text)?.words() ?? "");
}

export function collectDeclarations(statements: Statement[]): Declaration[] {
  let depth = 0;
  return statements.filter((statement) => DECLARATION_KINDS.has(statement.kind)).map((statement) => {
    const info = declarationInfo(statement);
    if (statement.kind === "DataEnd" && !isCommonPart(statement)) depth = Math.max(0, depth - 1);
    const component = depth > 0 && statement.kind === "Data";
    if (statement.kind === "DataBegin" && !isCommonPart(statement)) depth++;
    if (!component) return { ...info, statement };
    const { names, entries, ...rest } = info;
    return { ...rest, names: [], entries: [], componentNames: names, component: true, statement };
  });
}
