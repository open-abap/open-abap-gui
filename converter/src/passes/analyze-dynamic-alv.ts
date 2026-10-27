import { Expressions, Nodes, Statements } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import type { StatementAst } from "../abap/ast.js";
import { callsStatic } from "../abap/statements.js";
import type { DynamicAlv, DynamicAlvField, ReportIR, Statement } from "../types.js";

// Detect the deliberately finite dynamic-ALV pattern supported by the
// converter.  The runtime cannot manufacture an anonymous ABAP structure in
// a generated class, but a field catalog made entirely from literals gives us
// enough information to emit the same row shape safely.

// The statements of a kind, each with its syntax tree.
function statementsOf(statements: Statement[], type: new () => object): StatementAst[] {
  return statements.map((statement) => statementAst(statement.text))
    .filter((ast): ast is StatementAst => Boolean(ast?.is(type)));
}

function fieldSymbols(statements: Statement[]): { name: string; type: string }[] {
  return statementsOf(statements, Statements.FieldSymbol).flatMap((ast) => {
    const name = ast.sourceOf(Expressions.FieldSymbol);
    const typing = ast.findDirect(Expressions.Type) ?? ast.findDirect(Expressions.TypeTable);
    const words = typing ? ast.source(typing) : "";
    if (!name || !/^TYPE\s/i.test(words)) return [];
    return [{ name: name.slice(1, -1).toUpperCase(), type: words.replace(/^TYPE\s+/i, "").toUpperCase() }];
  });
}

// The rows of gt_fieldcat = VALUE #( ( fieldname = '...' ... ) ... ), by
// component.
function catalogRows(statements: Statement[]): Record<string, string>[] {
  const assignment = statementsOf(statements, Statements.Move)
    .find((ast) => ast.sourceOf(Expressions.Target)?.toUpperCase() === "GT_FIELDCAT" && ast.find(Expressions.ValueBody));
  if (!assignment) return [];
  return assignment.findAll(Expressions.ValueBodyLine).map((row) => Object.fromEntries(row.findDirectExpressions(Expressions.FieldAssignment)
    .map((field) => [assignment.source(field.findDirectExpression(Expressions.FieldSub)!).toUpperCase(), assignment.source(field.findDirectExpression(Expressions.Source)!)])));
}

function literal(value: string | undefined): string | undefined {
  return value && /^'.*'$/.test(value) ? value.slice(1, -1) : undefined;
}

function catalogEntries(statements: Statement[]): DynamicAlvField[] {
  return catalogRows(statements).filter((row) => literal(row.FIELDNAME)).map((row) => {
    const name = literal(row.FIELDNAME)!.toUpperCase();
    const intType = literal(row.INTTYPE)?.toUpperCase() ?? "C";
    const length = Number(row.INTLEN ?? 1);
    const decimals = Number(row.DECIMALS ?? 0);
    const outputLength = Number(row.OUTPUTLEN ?? length);
    const flag = (value: string | undefined) => value?.toUpperCase() === "ABAP_TRUE";
    return {
      name,
      intType,
      length: Number.isFinite(length) && length > 0 ? length : 1,
      decimals: Number.isFinite(decimals) && decimals >= 0 ? decimals : 0,
      outputLength: Number.isFinite(outputLength) && outputLength > 0 ? outputLength : length,
      checkbox: flag(row.CHECKBOX),
      editable: flag(row.EDIT),
      total: flag(row.DO_SUM),
      title: literal(row.COLTEXT) ?? name,
      currencyField: literal(row.CFIELDNAME)?.toUpperCase() ?? "",
    };
  });
}

function abapType(entry: DynamicAlvField): string {
  switch (entry.intType) {
    case "I": return "i";
    case "P": return `p LENGTH ${entry.length} DECIMALS ${entry.decimals}`;
    case "D": return "d";
    case "T": return "t";
    case "F": return "f";
    case "STRING": return "string";
    default: return `c LENGTH ${entry.length}`;
  }
}

// The field symbol APPEND INITIAL LINE TO <table> ASSIGNING <row> binds.
function appendedRow(statements: Statement[]): string | undefined {
  const ast = statementsOf(statements, Statements.Append)
    .find((item) => /^APPEND INITIAL LINE TO _ ASSIGNING _/.test(item.words())
      && item.findDirect(Expressions.Target)?.findDirectExpression(Expressions.TargetFieldSymbol));
  return ast?.sourceOf(Expressions.FSTarget)?.slice(1, -1).toUpperCase();
}

// The field symbol ASSIGN COMPONENT 'name' OF STRUCTURE ... TO <fs> binds.
function assignedComponent(statements: Statement[], component: string): string | undefined {
  const ast = statementsOf(statements, Statements.Assign).find((item) => {
    const source = item.findDirect(Expressions.AssignSource);
    return source && item.has("COMPONENT", source) && item.after("COMPONENT", source) && item.source(item.after("COMPONENT", source)!).toUpperCase() === `'${component}'`;
  });
  const target = ast?.findDirect(Expressions.FSTarget);
  return target && ast?.source(target).startsWith("<") ? ast.source(target).slice(1, -1).toUpperCase() : undefined;
}

// The first DATA name TYPE type, of the type as written.
function declaredOfType(statements: Statement[], type: string): string | undefined {
  return statementsOf(statements, Statements.Data)
    .find((ast) => ast.find(Expressions.Type)?.getChildren().map((child: Nodes.ExpressionNode | Nodes.TokenNode) => ast.source(child).toUpperCase()).join(" ") === type)
    ?.sourceOf(Expressions.DefinitionName)?.toUpperCase();
}

export function detectDynamicAlv(ir: ReportIR): DynamicAlv | undefined {
  // The pattern lives in the program itself, not in its includes.
  const statements = (ir.statements ?? []).filter((statement) => statement.filename === ir.source.filename);
  if (!statements.some((statement) => callsStatic(statement.text, "CL_ALV_TABLE_CREATE", ["CREATE_DYNAMIC_TABLE"]))) return undefined;
  const symbols = fieldSymbols(statements);
  const table = symbols.find((item) => /^(?:STANDARD\s+)?TABLE\b/i.test(item.type));
  const entries = catalogEntries(statements);
  if (!table || entries.length === 0) return undefined;

  const styleConstant = statementsOf(statements, Statements.Constant)
    .find((ast) => ast.find(Expressions.TypeName) && ast.sourceOf(Expressions.TypeName)!.toUpperCase() === "LVC_FNAME");
  const styleField = literal(styleConstant?.find(Expressions.Value)?.findFirstExpression(Expressions.ConstantString)
    ? styleConstant.source(styleConstant.find(Expressions.Value)!.findFirstExpression(Expressions.ConstantString)!) : undefined)?.toUpperCase() ?? "CELLSTYLES";
  const row = appendedRow(statements) ?? "LS_ROW";

  return {
    rowType: "ty_dynamic_alv_row",
    tableType: "ty_dynamic_alv_rows",
    tableMember: table.name,
    tableSymbol: table.name,
    referenceMember: declaredOfType(statements, "TYPE REF TO DATA") ?? "GR_TABLE",
    styleMember: declaredOfType(statements, "TYPE LVC_FNAME") ?? "GV_STYLE_FIELD",
    styleComponent: styleField,
    rowSymbol: row,
    componentSymbol: assignedComponent(statements, "ID") ?? "LV_COMPONENT",
    styleTableSymbol: assignedComponent(statements, "CELLSTYLES") ?? "LT_STYLES",
    // The first APPEND INITIAL LINE ... ASSIGNING binds the style row too.
    styleRowSymbol: appendedRow(statements) ?? "LS_STYLE",
    styleValueSymbol: assignedComponent(statements, "STYLE") ?? "LV_STYLE",
    fieldSymbols: [...new Set(symbols.map((item) => item.name))],
    fields: entries,
    typeFields: [
      ...entries.map((entry) => ({name: entry.name, type: abapType(entry)})),
      {name: styleField, type: "lvc_t_styl"},
    ],
  };
}
