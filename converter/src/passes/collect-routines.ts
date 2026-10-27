import { Expressions, Nodes } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import type { StatementAst } from "../abap/ast.js";
import type { ReportIR, RoutineParameter } from "../types.js";

const SECTIONS: [Parameters<StatementAst["findDirect"]>[0], RoutineParameter["section"]][] = [
  [Expressions.FormTables, "TABLES"],
  [Expressions.FormUsing, "USING"],
  [Expressions.FormChanging, "CHANGING"],
];

// An untyped FORM parameter is generic: any for USING and CHANGING, a
// standard table for TABLES. TABLES ... STRUCTURE names only the line type,
// which a method parameter cannot spell, so it is a generic standard table too.
function parameterType(section: RoutineParameter["section"], typing: string): string {
  if (section === "TABLES" && (!typing || /^STRUCTURE\b/i.test(typing))) return "standard table";
  if (!typing) return "any";
  // The typing without its leading TYPE, LIKE or STRUCTURE.
  return typing.slice(typing.indexOf(" ") + 1).toLowerCase();
}

// The type a FORM parameter has in its method signature. System fields are
// typed by their meaning, as the generated class has no sy structure of its own.
export function methodParameterType(parameter: RoutineParameter): string {
  const type = String(parameter.type ?? "").toUpperCase();
  if (type === "SY-UCOMM") return "zif_gg_session_types_v1=>ty_ucomm";
  if (type === "SY" || type === "SY-SUBRC") return "i";
  return parameter.type;
}

// Generic types cannot declare a variable, so a temporary of such a parameter
// takes its type from the value instead.
export function isGenericParameterType(type: string | undefined): boolean {
  return /^(?:any|data|simple|clike|csequence|xsequence|numeric|decfloat|c|n|x|p)$|\btable$/i.test(String(type ?? "").trim());
}

// The FORM parameters of a section. A method parameter cannot be typed
// STANDARD TABLE OF x, so such a parameter carries its line type.
function sectionParameters(ast: StatementAst, section: Nodes.ExpressionNode): { node: Nodes.ExpressionNode; lineType?: Nodes.ExpressionNode }[] {
  return section.findDirectExpressions(Expressions.FormParam).map((node) => {
    const type = node.findDirectExpression(Expressions.FormParamType);
    const tableOf = type && ast.skeleton(type) === "TYPE STANDARD TABLE OF _" ? type.getChildren().at(-1) as Nodes.ExpressionNode : undefined;
    return { node, ...(tableOf ? { lineType: tableOf } : {}) };
  });
}

function formParameter(ast: StatementAst, section: RoutineParameter["section"], { node, lineType }: ReturnType<typeof sectionParameters>[number]): RoutineParameter {
  const byValue = node.findDirectExpression(Expressions.PassByValue);
  const name = (byValue ?? node).findDirectExpression(Expressions.FormParamName)!;
  // Everything after the name: TYPE i, LIKE x, STRUCTURE s, TYPE REF TO c.
  const typing = ast.text.slice(ast.end(byValue ?? name), ast.end(node)).trim();
  // The table type of TABLE OF x gets a name of its own in collectRoutines.
  const structure = ast.has("STRUCTURE", node) ? ast.after("STRUCTURE", node) : undefined;
  return {
    name: ast.source(name).toLowerCase(),
    section,
    direction: section === "USING" ? "IMPORTING" : "CHANGING",
    byValue: Boolean(byValue),
    type: parameterType(section, typing),
    typing,
    ...(structure ? { structure: ast.source(structure) } : {}),
    ...(lineType ? { lineType: ast.source(lineType).toLowerCase() } : {}),
  };
}

function parseParameters(header: string): RoutineParameter[] {
  const ast = statementAst(header);
  if (!ast) return [];
  return SECTIONS.flatMap(([type, section]) => {
    const node = ast.findDirect(type);
    return node ? sectionParameters(ast, node).map((parameter) => formParameter(ast, section, parameter)) : [];
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
    routine.parameters = parseParameters(routine.statement.text);
    for (const parameter of routine.parameters) {
      if (parameter.lineType) parameter.type = uniqueName(`ty_${parameter.name}`, usedTypeNames);
    }
  }
  return ir;
}
