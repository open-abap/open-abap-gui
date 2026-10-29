import { Expressions, Nodes } from "@abaplint/core";
import { isKeyword, statementAst } from "../abap/ast.js";
import type { StatementAst } from "../abap/ast.js";
import type { ReportIR, RoutineParameter } from "../types.js";
import { globalDataDeclaration, hasHeaderLine } from "./header-lines.js";

const SECTIONS: [Parameters<StatementAst["findDirect"]>[0], RoutineParameter["section"]][] = [
  [Expressions.FormTables, "TABLES"],
  [Expressions.FormUsing, "USING"],
  [Expressions.FormChanging, "CHANGING"],
];

// The type a FORM parameter has in its method signature. System fields are
// typed by their meaning, as the generated class has no sy structure of its own.
export function methodParameterType(parameter: RoutineParameter): string {
  const type = String(parameter.type ?? "").toUpperCase();
  if (type === "SY-UCOMM") return "zif_gg_session_types_v1=>ty_ucomm";
  if (type === "SY" || type === "SY-SUBRC") return "i";
  return parameter.type;
}

// The typing of a FORM parameter in its method signature, TYPE type or, for
// a type taken from a data object of the class, LIKE type; `rename` maps the
// type to the names of the class.
export function methodParameterTyping(parameter: RoutineParameter, rename = (type: string) => type): string {
  const type = methodParameterType(parameter);
  return `${parameter.like && type === parameter.type ? "LIKE" : "TYPE"} ${rename(type)}`;
}

// Generic types cannot declare a variable, so a temporary of such a parameter
// takes its type from the value instead.
export function isGenericParameterType(type: string | undefined): boolean {
  return /^(?:any|data|simple|clike|csequence|xsequence|numeric|decfloat|c|n|x|p)$|\btable$/i.test(String(type ?? "").trim());
}

// The words of a typing as the generated class writes them: keywords in
// upper case, names in lower case.
function typingWords(ast: StatementAst, nodes: readonly (Nodes.ExpressionNode | Nodes.TokenNode)[]): string {
  return nodes.map((node) => node instanceof Nodes.TokenNode && isKeyword(node)
    ? node.getFirstToken().getUpperStr()
    : ast.source(node).toLowerCase()).join(" ");
}

// The type STRUCTURE s gives a parameter: the program's data object s, the
// line of s if it is a table with header line, or else the type s, e.g. a
// dictionary structure.
function structureTyping(ir: ReportIR, structure: string): { like: boolean; type: string } {
  const name = structure.toLowerCase();
  const declaration = globalDataDeclaration(ir, name.split("-")[0]);
  if (!declaration) return { like: false, type: name };
  return { like: true, type: !name.includes("-") && hasHeaderLine(declaration) ? `LINE OF ${name}` : name };
}

// The method typing of a FORM parameter. A FORM types its parameters with
// the program's global types and data objects, which are the class's, so
// TYPE and LIKE carry over. What a method signature cannot spell gets a
// named type: a table type with its line type, TYPE STANDARD TABLE OF x and
// TABLES ... STRUCTURE s, and LIKE REF TO x. An untyped parameter is generic:
// any for USING and CHANGING, a standard table for TABLES.
function parameterTyping(ir: ReportIR, ast: StatementAst, section: RoutineParameter["section"], name: string, node: Nodes.ExpressionNode, newType: (base: string) => string): Pick<RoutineParameter, "type" | "like" | "types"> {
  const named = (typing: string) => {
    const type = newType(`ty_${name}`);
    return { type, types: [`TYPES ${type} ${typing}.`] };
  };
  const structure = ast.after("STRUCTURE", node);
  if (structure) {
    const line = structureTyping(ir, ast.source(structure));
    if (section !== "TABLES") return line;
    if (!line.type.startsWith("LINE OF ")) return named(`${line.like ? "LIKE" : "TYPE"} STANDARD TABLE OF ${line.type} WITH DEFAULT KEY`);
    const lineType = newType(`ty_${name}_line`);
    const table = named(`TYPE STANDARD TABLE OF ${lineType} WITH DEFAULT KEY`);
    return { type: table.type, types: [`TYPES ${lineType} LIKE ${line.type}.`, ...table.types] };
  }
  const typing = node.findDirectExpression(Expressions.FormParamType);
  if (!typing) return { type: section === "TABLES" ? "STANDARD TABLE" : "any" };
  // The typing without its leading TYPE or LIKE.
  const type = typingWords(ast, typing.getChildren().slice(1));
  const skeleton = ast.skeleton(typing);
  // A standard table type has the default key; a sorted or hashed one keeps
  // its key generic, as no key fits every table the FORM accepts.
  if (skeleton === "TYPE STANDARD TABLE OF _") return named(`TYPE ${type} WITH DEFAULT KEY`);
  if (/^TYPE (?:SORTED|HASHED|INDEX|ANY) TABLE OF _$/.test(skeleton) || skeleton === "LIKE REF TO _") return named(`${skeleton.split(" ")[0]} ${type}`);
  return { type, ...(skeleton.startsWith("LIKE ") ? { like: true } : {}) };
}

function formParameter(ir: ReportIR, ast: StatementAst, section: RoutineParameter["section"], node: Nodes.ExpressionNode, newType: (base: string) => string): RoutineParameter {
  const byValue = node.findDirectExpression(Expressions.PassByValue);
  const nameNode = (byValue ?? node).findDirectExpression(Expressions.FormParamName)!;
  const name = ast.source(nameNode).toLowerCase();
  const structure = ast.after("STRUCTURE", node);
  return {
    name,
    section,
    direction: section === "USING" ? "IMPORTING" : "CHANGING",
    byValue: Boolean(byValue),
    ...parameterTyping(ir, ast, section, name, node, newType),
    // Everything after the name: TYPE i, LIKE x, STRUCTURE s, TYPE REF TO c.
    typing: ast.text.slice(ast.end(byValue ?? nameNode), ast.end(node)).trim(),
    ...(structure ? { structure: ast.source(structure) } : {}),
  };
}

function parseParameters(ir: ReportIR, header: string, newType: (base: string) => string): RoutineParameter[] {
  const ast = statementAst(header);
  if (!ast) return [];
  return SECTIONS.flatMap(([type, section]) => {
    const node = ast.findDirect(type);
    return node ? node.findDirectExpressions(Expressions.FormParam).map((parameter) => formParameter(ir, ast, section, parameter, newType)) : [];
  });
}

// base, or within the 30 characters of an ABAP name a variant of it not used yet.
export function uniqueName(base: string, used: Set<string>): string {
  let name = base.slice(0, 30);
  for (let suffix = 2; used.has(name); suffix++) {
    const marker = `_${suffix}`;
    name = `${base.slice(0, 30 - marker.length)}${marker}`;
  }
  used.add(name);
  return name;
}

// PERFORM form IN PROGRAM prog and PERFORM form(prog) call a FORM of another
// program, which is not converted.
export function isExternalPerform(text: string): boolean {
  const ast = statementAst(text);
  return Boolean(ast?.findDirect(Expressions.IncludeName)) || / IN PROGRAM(?: |$)/.test(ast?.words() ?? "");
}

// The short form PERFORM form(prog) is not allowed in classes; it is written
// PERFORM form IN PROGRAM prog.
export function inProgramPerform(text: string): string {
  const ast = statementAst(text);
  const form = ast?.findDirect(Expressions.FormName);
  const program = ast?.findDirect(Expressions.IncludeName);
  if (!ast || !form || !program) return text;
  const children = ast.node.getChildren();
  const open = children[children.indexOf(program) - 1];
  const close = children[children.indexOf(program) + 1];
  if (open?.getFirstToken().getStr() !== "(" || close?.getFirstToken().getStr() !== ")") return text;
  return `${text.slice(0, ast.end(form))} IN PROGRAM ${ast.source(program)}${text.slice(ast.end(close))}`;
}

export function collectRoutines(ir: ReportIR): ReportIR {
  const usedMethodNames = new Set<string>();
  const usedTypeNames = new Set((ir.statements ?? [])
    .filter((statement) => statement.kind === "Type" || statement.kind === "TypeBegin")
    .map((statement) => statementAst(statement.text)?.sourceOf(Expressions.NamespaceSimpleName)?.toLowerCase())
    .filter((name): name is string => Boolean(name)));
  for (const routine of ir.routines) {
    const baseName = `form_${routine.name.toLowerCase()}`;
    let methodName = baseName.slice(0, 30);
    let suffix = 2;
    while (usedMethodNames.has(methodName)) {
      const marker = `_${suffix++}`;
      methodName = `${baseName.slice(0, 30 - marker.length)}${marker}`;
    }
    usedMethodNames.add(methodName);
    routine.methodName = methodName;
    routine.parameters = parseParameters(ir, routine.statement.text, (base) => uniqueName(base, usedTypeNames));
  }
  return ir;
}
