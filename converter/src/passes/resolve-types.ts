import { Expressions } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import { selectionOptions } from "./collect-selection-screens.js";
import type { DataType, Declaration, Metadata, NormalizedOptions, ReportIR } from "../types.js";

function metadataMap(value: unknown): Record<string, Metadata> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return Object.fromEntries(Object.entries(value).map(([name, item]) => [name.toUpperCase(), item]));
}

function typeInfo(value: unknown, fallback?: string): Metadata | undefined {
  if (typeof value === "string" && value.trim()) return { type: value.trim().toLowerCase(), fields: {} };
  if (!value || typeof value !== "object") return undefined;
  const record = value as Metadata;
  const type = record.type ?? record.abapType ?? record.name ?? fallback;
  if (!type) return undefined;
  return { ...record, type: String(type).toLowerCase(), fields: metadataMap(record.fields ?? record.components) };
}

function lookup(map: Record<string, Metadata> | undefined, name: unknown): Metadata | undefined {
  return map?.[String(name ?? "").toUpperCase()];
}

// The built-in type of DATA x TYPE c LENGTH n DECIMALS m, which a select-option
// FOR x takes.
function scalarType(declaration: Declaration): DataType | undefined {
  const ast = statementAst(declaration.raw);
  const definition = ast?.find(Expressions.DataDefinition);
  const type = definition?.findDirectExpression(Expressions.Type);
  if (!ast || !type || ast.skeleton(type) !== "TYPE _") return undefined;
  const length = definition!.findDirectExpression(Expressions.Length)?.findDirectExpression(Expressions.Integer);
  const decimals = definition!.findDirectExpression(Expressions.Decimals)?.findDirectExpression(Expressions.Integer);
  return {
    // The type's own name, as for a selection screen field, see typeDefinition.
    typ: ast.source(type.findDirectExpression(Expressions.TypeName)!).toUpperCase().split(/-|=>/)[0],
    ...(length ? { length: Number(ast.source(length)) } : {}),
    ...(decimals ? { decimals: Number(ast.source(decimals)) } : {}),
  };
}

// Every type a declaration references is assumed to exist in the target
// system, so declarations are emitted with the type name exactly as written.
// `ddicTypes` is optional field metadata: it types selection-screen elements
// declared FOR <table>-<field>, and never renames a type or gates conversion.
export function resolveTypes(ir: ReportIR, options: NormalizedOptions): ReportIR {
  const dictionary = metadataMap(options.ddicTypes);
  ir.resolvedTypes = {};
  const scalarTypes = new Map<string, DataType>();
  for (const declaration of ir.declarations) {
    if (!['data', 'static'].includes(declaration.kind)) continue;
    const type = scalarType(declaration);
    for (const entry of declaration.entries ?? []) if (type) scalarTypes.set(entry.name.toUpperCase(), type);
  }
  for (const declaration of ir.declarations) {
    if (declaration.kind === "tables") {
      const name = declaration.names?.[0];
      if (!name) continue;
      // TABLES <name> declares a work area of the dictionary type <name>,
      // TABLES *<name> a second one.
      const table = declaration.table ?? name;
      declaration.type = table.toLowerCase();
      declaration.fields = typeInfo(lookup(dictionary, table), table)?.fields ?? {};
      declaration.resolved = true;
      declaration.statement.resolvedType = true;
      if (lookup(dictionary, table)) ir.resolvedTypes[name] = typeInfo(lookup(dictionary, table), table)!;
      continue;
    }
    if (declaration.kind === "type") {
      const name = declaration.names?.[0]?.toUpperCase();
      declaration.resolved = true;
      declaration.statement.resolvedType = true;
      // The type the declaration is made of: the line type of a table or
      // range, the type of a reference, or the type itself. Of a component,
      // as zs-f, that is the structure.
      const reference = statementAst(declaration.raw)?.sourceOf(Expressions.TypeName)?.split("-")[0];
      if (name && reference && lookup(dictionary, reference)) ir.resolvedTypes[name] = typeInfo(lookup(dictionary, reference), reference)!;
    }
  }
  for (const screen of ir.selections) {
    for (const item of screen.elements) {
      const [head, component] = (selectionOptions(item.raw).for ?? "").toUpperCase().split("-");
      const scalarType = scalarTypes.get(head);
      if (scalarType) {
        item.dataType = scalarType;
        continue;
      }
      if (!component) continue;
      const table = lookup(ir.resolvedTypes, head) ?? lookup(dictionary, head);
      const field = table?.fields ? lookup(table.fields, component) : undefined;
      const info = typeInfo(field);
      if (info?.type) {
        item.dataType = {
          typ: info.type.toUpperCase(),
          ...(info.length ? { length: Number(info.length) } : {}),
          ...(info.decimals ? { decimals: Number(info.decimals) } : {}),
        };
      }
    }
  }
  return ir;
}
