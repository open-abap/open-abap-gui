import { BasicTypes, Expressions, Nodes } from "@abaplint/core";
import type { TypedIdentifier } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import type { StatementAst } from "../abap/ast.js";
import { declarationInfo } from "./collect-declarations.js";
import type { ProgramScopeGetter } from "./program-scope.js";
import type { Declaration, Span, Statement } from "../types.js";

// An inline DATA( ) outside a FORM, method or module declares a program global,
// just like a classic DATA statement. The generated class has no program scope,
// so the variable is lifted to a class attribute: its type comes from the
// abaplint syntax check, and the statement is rewritten to use the attribute.

const REFERENCE_CONSTRUCTORS = new Set(["NEW", "REF", "CAST"]);
const TYPED_CONSTRUCTORS = new Set(["VALUE", "CONV", "CORRESPONDING", "EXACT", "REDUCE", "FILTER", "COND", "SWITCH", ...REFERENCE_CONSTRUCTORS]);

function programVariables(programScope: ProgramScopeGetter): { name: string; variable: TypedIdentifier }[] {
  const program = programScope();
  if (!program) return [];
  return Object.entries(program.scope.getData().vars)
    .filter(([, variable]) => variable.getMeta().includes("inline" as never))
    .map(([name, variable]) => ({ name, variable }));
}

// The DATA( ) of the statement declaring name inline.
function inlineData(ast: StatementAst, name: string): Nodes.ExpressionNode[] {
  return ast.findAll(Expressions.InlineData)
    .filter((node) => ast.source(node.findDirectExpression(Expressions.TargetField)!).toUpperCase() === name.toUpperCase());
}

// The explicit type of the constructor expression assigned to the inline
// declaration, e.g. VALUE ty_rows( ) or NEW zcl_worker( ).
function constructorType(text: string, name: string): string | undefined {
  const ast = statementAst(text);
  const target = ast?.findDirect(Expressions.Target);
  if (!ast || !target || !inlineData(ast, name).some((node) => target.getChildren().includes(node))) return undefined;
  // NEW starts a method call chain; the other constructors are expressions.
  const source = ast.findDirect(Expressions.Source);
  const constructorNode = source?.findDirectExpression(Expressions.MethodCallChain)?.findDirectExpression(Expressions.NewObject) ?? source;
  const [keyword, type] = constructorNode?.getChildren() ?? [];
  const constructor = keyword instanceof Nodes.TokenNode ? keyword.getFirstToken().getUpperStr() : "";
  const typeName = type?.get() instanceof Expressions.TypeNameOrInfer ? (type as Nodes.ExpressionNode).findDirectExpression(Expressions.TypeName) : undefined;
  if (!typeName || !TYPED_CONSTRUCTORS.has(constructor)) return undefined;
  const written = ast.source(typeName).toLowerCase();
  return REFERENCE_CONSTRUCTORS.has(constructor) ? `REF TO ${written}` : written;
}

// The type as ABAP source, or undefined when it cannot be written down safely.
function typeSource(variable: TypedIdentifier, text: string, name: string): string | undefined {
  const type = variable.getType();
  if (type instanceof BasicTypes.VoidType) return constructorType(text, name);
  if (type instanceof BasicTypes.UnknownType || type instanceof BasicTypes.AnyType || type instanceof BasicTypes.GenericObjectReferenceType) return undefined;
  // abaplint qualifies TYPE REF TO lcl by the class alone; toABAP keeps REF TO.
  const qualified = type instanceof BasicTypes.ObjectReferenceType ? undefined : type.getQualifiedName?.();
  if (qualified && /^[A-Z_/][A-Z0-9_/=>-]*$/i.test(qualified)) return qualified.toLowerCase();
  const abap = type.toABAP?.();
  if (!abap || /todo/i.test(abap)) return undefined;
  return abap;
}

function contains(span: Span, row: number, column: number): boolean {
  const afterStart = row > span.start.line || (row === span.start.line && column >= span.start.column);
  const beforeEnd = row < span.end.line || (row === span.end.line && column <= span.end.column);
  return afterStart && beforeEnd;
}

// Replaces DATA(name) with name.
function useAttribute(text: string, name: string): string {
  const ast = statementAst(text);
  if (!ast) return text;
  let output = text;
  for (const node of inlineData(ast, name).reverse()) {
    output = `${output.slice(0, ast.start(node))}${ast.source(node.findDirectExpression(Expressions.TargetField)!)}${output.slice(ast.end(node))}`;
  }
  return output;
}

export function liftInlineDeclarations(programScope: ProgramScopeGetter, globalStatements: Statement[]): Declaration[] {
  const candidates = globalStatements.filter((statement) => statementAst(statement.text)?.find(Expressions.InlineData));
  if (!candidates.length) return [];
  let variables;
  try {
    variables = programVariables(programScope);
  } catch {
    return [];
  }
  const declarations: Declaration[] = [];
  for (const { name, variable } of variables) {
    const row = variable.getStart().getRow();
    const column = variable.getStart().getCol();
    const statement = candidates.find((item) => item.filename === variable.getFilename() && contains(item.span, row, column));
    if (!statement) continue;
    const type = typeSource(variable, statement.text, name);
    if (!type) continue;
    statement.text = useAttribute(statement.text, name);
    const raw = `DATA ${name.toLowerCase()} TYPE ${type}.`;
    declarations.push({ ...declarationInfo({ kind: "Data", text: raw }), statement, inline: true });
  }
  return declarations;
}
