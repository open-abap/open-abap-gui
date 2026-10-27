import { Expressions, Nodes, Statements } from "@abaplint/core";
import { expressionAst, isKeyword, leadingWords, lexedAst, statementAst } from "./ast.js";
import type { SourceAst, StatementAst } from "./ast.js";
import { isReference } from "../passes/replace-identifiers.js";
import type { Statement } from "../types.js";

// Facts about a statement that several passes need. A FORM header abaplint
// cannot classify, say for a syntax its release does not have, still starts a
// FORM, so these also read the words of an Unknown statement.

export function isFormStart(statement: Statement): boolean {
  return statement.kind === "Form" || leadingWords(statement.text).startsWith("FORM ");
}

export function isFormEnd(statement: Statement): boolean {
  return statement.kind === "EndForm" || /^ENDFORM(?: |$)/.test(leadingWords(statement.text));
}

const FIELD_SYMBOL = /^<[A-Z][A-Z0-9_]*>$/i;

/** The field symbols a text names, upper case without the angle brackets, in order. */
export function fieldSymbolsIn(text: string): string[] {
  return (lexedAst(text)?.tokens() ?? [])
    .map((entry) => entry.token.getStr())
    .filter((token) => FIELD_SYMBOL.test(token))
    .map((token) => token.slice(1, -1).toUpperCase());
}

/**
 * The field symbols a FORM's or method's own FIELD-SYMBOLS statements among the
 * statements declare; they hide a program global of the same name.
 */
export function declaredFieldSymbols(statements: Statement[]): string[] {
  return statements
    .filter((statement) => statement.kind === "FieldSymbol" && statement.scope === "local")
    .flatMap((statement) => fieldSymbolsIn(statement.text).slice(0, 1));
}

/** The field symbols a text declares inline, FIELD-SYMBOL(<fs>). */
export function inlineFieldSymbolsIn(text: string): string[] {
  const tokens = (lexedAst(text)?.tokens() ?? []).map((entry) => entry.token.getUpperStr());
  return tokens
    .filter((token, index) => FIELD_SYMBOL.test(token) && tokens.slice(index - 4, index).join(" ") === "FIELD - SYMBOL (")
    .map((token) => token.slice(1, -1));
}

// A keyword of the statement, wherever it stands, outside its operands' names.
function hasKeyword(ast: StatementAst, words: string[]): boolean {
  return ast.tokens().some((entry) => !(entry.node instanceof Nodes.TokenNodeRegex) && words.includes(entry.token.getUpperStr()));
}

// ASSIGN is an ordinary statement in a class method, whatever its source
// operand: a data object, a dereference, a table expression or a component of
// one. Only a name resolved at runtime - `(name)`, `->(attr)`, `=>(attr)`,
// TABLE FIELD - loses its meaning, because the program's data was renamed and
// moved into the class. The additions here are obsolete forms classes reject.
export function isStaticAssign(text: string): boolean {
  const ast = statementAst(String(text ?? ""));
  if (!ast?.is(Statements.Assign) || hasKeyword(ast, ["CASTING", "INCREMENTING", "DECIMALS", "RANGE", "ELSEWHERE"])
      || /^ASSIGN LOCAL COPY /.test(ast.words())) return false;
  return !ast.findDirect(Expressions.AssignSource)?.findDirectExpression(Expressions.Dynamic);
}

// The field symbol an ASSIGN binds, declared inline or not.
export function assignTarget(text: string): string | undefined {
  const ast = statementAst(String(text ?? ""));
  const target = ast?.is(Statements.Assign) ? ast.findDirect(Expressions.FSTarget)?.findFirstExpression(Expressions.FieldSymbol) : undefined;
  return target && ast ? ast.source(target).slice(1, -1).toUpperCase() : undefined;
}

/** The field symbol a statement binds through ASSIGNING <fs>, not declared inline. */
export function assigningTarget(text: string): string | undefined {
  const tokens = statementAst(String(text ?? ""))?.tokens() ?? [];
  const index = tokens.findIndex((entry, at) => entry.token.getUpperStr() === "ASSIGNING"
    && !(entry.node instanceof Nodes.TokenNodeRegex) && FIELD_SYMBOL.test(tokens[at + 1]?.token.getStr() ?? ""));
  return index < 0 ? undefined : tokens[index + 1].token.getStr().slice(1, -1).toUpperCase();
}

// `LOOP AT itab ASSIGNING <fs>` and `READ TABLE itab ... ASSIGNING <fs>` bind
// the field symbol to a row of a statically named table, which is exactly as
// determined as an ASSIGN with a static source; so do APPEND, INSERT and
// COLLECT ... ASSIGNING, to the row they just added. All are lowered and
// emitted, so all have to count as bindings or the emitted use loses its
// declaration.
export function bindsStatically(text: string, name: string): boolean {
  const ast = statementAst(String(text ?? ""));
  if (!ast) return false;
  if (ast.is(Statements.Assign)) return isStaticAssign(text) && assignTarget(text) === name;
  if (hasKeyword(ast, ["CASTING", "INCREMENTING", "DECIMALS", "RANGE", "ELSEWHERE"])) return false;
  const table = ast.is(Statements.Loop) ? ast.findDirect(Expressions.LoopSource)
    : ast.is(Statements.ReadTable) ? ast.findDirect(Expressions.SimpleSource2) : undefined;
  // The table is named, by a name or a field symbol, not computed.
  const named = table && /^(?:[A-Z]|<)/i.test(ast.source(table));
  if (!named && !ast.is(Statements.Append) && !ast.is(Statements.InsertInternal) && !ast.is(Statements.Collect)) return false;
  return assigningTarget(text) === name;
}

/**
 * The FORM of this program a PERFORM calls, upper case; undefined for a
 * dynamic PERFORM (name) and a FORM of another program.
 */
export function performedForm(text: string): string | undefined {
  const ast = statementAst(text);
  const form = ast?.is(Statements.Perform) ? ast.findDirect(Expressions.FormName) : undefined;
  if (!ast || !form || ast.findDirect(Expressions.IncludeName) || / IN PROGRAM(?: |$)/.test(ast.words())) return undefined;
  return ast.source(form).toUpperCase();
}

/**
 * The data objects a statement refers to, upper case, a structure component
 * as struct-comp, optionally only within a part of the statement.
 */
export function referencedNames(text: string, part?: (ast: StatementAst) => Nodes.ExpressionNode | undefined): string[] {
  const ast = statementAst(text);
  if (!ast) return [];
  const node = part?.(ast);
  if (part && !node) return [];
  const [from, to] = node ? [ast.start(node), ast.end(node)] : [0, text.length];
  const tokens = ast.tokens();
  const names: string[] = [];
  for (const [index, entry] of tokens.entries()) {
    if (entry.start < from || entry.end > to || !isReference(entry)) continue;
    const dash = tokens[index + 1];
    const component = dash?.token.getStr() === "-" && dash.start === entry.end && tokens[index + 2]?.start === dash.end ? tokens[index + 2] : undefined;
    names.push(`${entry.token.getUpperStr()}${component ? `-${component.token.getUpperStr()}` : ""}`);
  }
  return names;
}

export type PerformSection = "TABLES" | "USING" | "CHANGING";

/** The arguments of a PERFORM by section, each as written. */
export function performArguments(text: string): Record<PerformSection, string[]> {
  const ast = statementAst(text);
  const section = (type: Parameters<StatementAst["findDirect"]>[0]) => {
    const node = ast?.findDirect(type);
    return node && ast ? node.getChildren().filter((child) => child instanceof Nodes.ExpressionNode).map((child) => ast.source(child)) : [];
  };
  return {
    TABLES: section(Expressions.PerformTables),
    USING: section(Expressions.PerformUsing),
    CHANGING: section(Expressions.PerformChanging),
  };
}

// PERFORM passes data objects only, so an argument is a literal, a text
// symbol, a constant or a variable, possibly with offset and length: a name
// or field symbol, then components and attributes, the table body [] and a
// numeric offset and length.
export function isWritableArgument(argument: string, constants?: Set<string>): boolean {
  const ast = expressionAst(argument);
  const source = ast?.findDirect(Expressions.Source);
  const chain = source?.getChildren().length === 1 ? source.findDirectExpression(Expressions.FieldChain) : undefined;
  if (!ast || !chain) return false;
  const [head, ...rest] = chain.getChildren();
  if (head.get() instanceof Expressions.SourceField) {
    if (constants?.has(ast.source(head).toUpperCase())) return false;
  } else if (!(head.get() instanceof Expressions.SourceFieldSymbol) && !(head.get() instanceof Expressions.ClassName)) {
    return false;
  }
  const digits = (node: Nodes.ExpressionNode | Nodes.TokenNode) => node.getChildren().every((child) => !(child instanceof Nodes.TokenNodeRegex) || /^\d+$/.test(child.getFirstToken().getStr()));
  for (let index = 0; index < rest.length; index++) {
    const node = rest[index];
    const type = node.get();
    if (node instanceof Nodes.TokenNode && ["-", "->", "=>"].includes(node.getFirstToken().getStr())
        && (rest[index + 1]?.get() instanceof Expressions.ComponentName || rest[index + 1]?.get() instanceof Expressions.AttributeName)) {
      index++;
    } else if (!(type instanceof Expressions.TableBody) && !((type instanceof Expressions.FieldOffset || type instanceof Expressions.FieldLength) && digits(node))) {
      return false;
    }
  }
  return true;
}

/**
 * The name a declaration declares, as written: DATA x, BEGIN OF x, END OF x,
 * TYPES ty, CONTROLS tc.
 */
export function declaredName(text: string | undefined): string | undefined {
  const ast = statementAst(String(text ?? "").trim());
  const name = ast?.find(Expressions.DefinitionName) ?? ast?.find(Expressions.NamespaceSimpleName);
  return name ? ast!.source(name) : undefined;
}

/**
 * A declaration without its keyword, if it starts with it, and without its
 * terminator: the component `a TYPE i` of `DATA a TYPE i,` in a BEGIN OF chain.
 */
export function declarationBody(text: string, keyword: string): string {
  const tokens = lexedAst(text)?.tokens() ?? [];
  if (!tokens.length) return text.trimEnd();
  const start = tokens[0].token.getUpperStr() === keyword.toUpperCase() && tokens.length > 1 ? tokens[1].start : 0;
  const last = tokens.at(-1)!;
  return text.slice(start, /^[.,]$/.test(last.token.getStr()) ? last.start : text.length).trimEnd();
}

/**
 * The data objects declarations declare outside structures: DATA x, and with
 * `structures` also DATA BEGIN OF x. Upper case.
 */
export function declaredDataNames(text: string, structures = false): string[] {
  const ast = lexedAst(text);
  const names: string[] = [];
  let depth = 0;
  for (const statement of ast?.statements ?? []) {
    const type = statement.get();
    const name = statement.findFirstExpression(Expressions.DefinitionName);
    if (type instanceof Statements.DataBegin) {
      if (depth++ === 0 && structures && name) names.push(ast!.source(name).toUpperCase());
    } else if (type instanceof Statements.DataEnd) depth--;
    else if (type instanceof Statements.Data && depth === 0 && name) names.push(ast!.source(name).toUpperCase());
  }
  return names;
}

/** Whether a token of the text is the name, in any case: also inside a component path. */
export function mentions(text: string | undefined, name: string): boolean {
  const upper = name.toUpperCase();
  return (lexedAst(String(text ?? ""))?.tokens() ?? []).some((entry) => entry.token.getUpperStr() === upper);
}

export interface MethodDefinition {
  name: string;
  /** CLASS-METHODS. */
  isStatic: boolean;
  /** FOR EVENT ... OF. */
  isEventHandler: boolean;
  /** The IMPORTING parameters, in order. */
  importing: string[];
}

/** A METHODS or CLASS-METHODS definition. */
export function methodDefinition(text: string | undefined): MethodDefinition | undefined {
  const ast = statementAst(String(text ?? "").trim());
  const name = ast?.is(Statements.MethodDef) ? ast.findDirect(Expressions.MethodName) : undefined;
  if (!ast || !name) return undefined;
  return {
    name: ast.source(name),
    isStatic: ast.tokens()[0].token.getUpperStr() === "CLASS",
    isEventHandler: Boolean(ast.findDirect(Expressions.EventHandler)),
    importing: (ast.findDirect(Expressions.MethodDefImporting)?.findAllExpressions(Expressions.MethodParamName) ?? []).map((parameter) => ast.source(parameter)),
  };
}

/** CONTROLS name TYPE TABLEVIEW or TABSTRIP: the name and the type, upper case. */
export function controlsDeclaration(text: string | undefined): { name: string; type: string } | undefined {
  const ast = statementAst(String(text ?? "").trim());
  const name = ast?.is(Statements.Controls) ? ast.findDirect(Expressions.NamespaceSimpleName) : undefined;
  const type = ast?.operand("TYPE");
  return name && type ? { name: ast!.source(name), type: type.toUpperCase() } : undefined;
}

/** The class or interface of the first REF TO in a node, upper case. */
export function refToName(ast: SourceAst, node: Nodes.StatementNode | Nodes.ExpressionNode): string | undefined {
  const start = ast.start(node);
  const end = ast.end(node);
  const tokens = ast.tokens().filter((entry) => entry.start >= start && entry.end <= end);
  const at = tokens.findIndex((entry, index) => isKeyword(entry.node) && entry.token.getUpperStr() === "REF"
    && tokens[index + 1] && isKeyword(tokens[index + 1].node) && tokens[index + 1].token.getUpperStr() === "TO");
  const name = at >= 0 ? tokens[at + 2] : undefined;
  return name?.node instanceof Nodes.TokenNodeRegex ? name.token.getUpperStr() : undefined;
}

/** The fields a HIDE stores, as written. */
export function hiddenFields(text: string): string[] {
  const ast = statementAst(text.trim());
  return ast?.is(Statements.Hide) ? ast.node.getChildren().filter((child) => child.get() instanceof Expressions.Source).map((child) => ast.source(child)) : [];
}

/**
 * The actual parameter a call passes for a formal one, as written: `value` of
 * `name = value`, in whichever section, or nested call, it stands first.
 */
export function parameterValue(text: string, name: string): string | undefined {
  const ast = statementAst(text.trim());
  const upper = name.toUpperCase();
  const entry = ast?.tokens().find((item) => item.parent.get() instanceof Expressions.ParameterName && item.token.getUpperStr() === upper);
  const parameter = entry?.ancestors.at(-2);
  const [, equals, value] = parameter?.getChildren() ?? [];
  return ast && equals?.getFirstToken().getStr() === "=" && value ? ast.source(value) : undefined;
}

/** The function module a CALL FUNCTION names as a literal, upper case. */
export function functionModule(text: string): string | undefined {
  const ast = statementAst(text);
  const name = ast?.is(Statements.CallFunction) ? ast.findDirect(Expressions.FunctionName)?.findFirstExpression(Expressions.ConstantString) : undefined;
  return name && ast ? ast.source(name).slice(1, -1).toUpperCase() : undefined;
}

/** Whether the statement calls the static method of the class, in either form. */
export function callsStatic(text: string, className: string, methods: string[]): boolean {
  const tokens = statementAst(text)?.tokens() ?? [];
  return tokens.some((entry, index) => entry.token.getUpperStr() === className
    && tokens[index + 1]?.token.getStr() === "=>" && methods.includes(tokens[index + 2]?.token.getUpperStr() ?? ""));
}

/** The name of the FORM a header starts, upper case. */
export function formName(statement: Statement): string | undefined {
  const ast = statementAst(statement.text);
  const name = ast?.find(Expressions.FormName);
  if (ast && name) return ast.source(name).toUpperCase();
  return lexedAst(statement.text)?.tokens()[1]?.token.getUpperStr();
}
