// A PARAMETERS or SELECT-OPTIONS typed with a dictionary type, such as
// PARAMETERS p_count TYPE zcount, only names the type; the screen needs the
// built-in type behind it to render the field, e.g. an integer data element
// as a number field. The abaplint syntax check resolves the declared variable
// through the dictionary objects next to the report. When it cannot, because
// the objects are not in the converter input, the type stays as written.

import { BasicTypes } from "@abaplint/core";
import type { AbstractType } from "@abaplint/core";
import type { ProgramScopeGetter } from "./program-scope.js";
import { selectionOptions } from "./collect-selection-screens.js";
import type { DataType, ReportIR, SelectionElement } from "../types.js";

const BUILT_IN = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "XSTRING"]);

function needsResolution(item: SelectionElement): boolean {
  const typ = String(item.dataType?.typ ?? "").toUpperCase();
  const options = selectionOptions(item.raw);
  if (options.type) return !BUILT_IN.has(typ);
  // LIKE and FOR take the type of a data object; without explicit metadata
  // it is left at the STRING default.
  if (options.like || options.for) return !BUILT_IN.has(typ) || typ === "STRING";
  return false;
}

function builtInType(type: AbstractType): DataType | undefined {
  if (type instanceof BasicTypes.IntegerType || type instanceof BasicTypes.Integer8Type) return { typ: "I" };
  if (type instanceof BasicTypes.CharacterType) return { typ: "C", length: type.getLength() };
  if (type instanceof BasicTypes.NumericType) return { typ: "N", length: type.getLength() };
  if (type instanceof BasicTypes.DateType) return { typ: "D", length: 8 };
  if (type instanceof BasicTypes.TimeType) return { typ: "T", length: 6 };
  if (type instanceof BasicTypes.PackedType) {
    return { typ: "P", length: type.getLength(), ...(type.getDecimals() ? { decimals: type.getDecimals() } : {}) };
  }
  if (type instanceof BasicTypes.FloatType) return { typ: "F" };
  if (type instanceof BasicTypes.StringType) return { typ: "STRING" };
  if (type instanceof BasicTypes.HexType) return { typ: "X", length: type.getLength() };
  return undefined;
}

export function resolveSelectionTypes(ir: ReportIR, programScope: ProgramScopeGetter): void {
  const pending = (ir.selections ?? [])
    .flatMap((screen) => screen.elements)
    .filter((item) => (item.kind === "parameter" || item.kind === "select-option") && item.name && needsResolution(item));
  if (!pending.length) return;
  const program = programScope();
  if (!program) return;
  const variables = program.scope.getData().vars;
  for (const item of pending) {
    let type: AbstractType | undefined = variables[item.name!]?.getType();
    // A selection table's row carries the field type in LOW.
    if (item.kind === "select-option") {
      const row = type instanceof BasicTypes.TableType ? type.getRowType() : undefined;
      type = row instanceof BasicTypes.StructureType ? row.getComponentByName("LOW") : undefined;
    }
    const dataType = type ? builtInType(type) : undefined;
    if (!dataType) continue;
    const rollname = type!.getQualifiedName()?.toUpperCase();
    if (rollname && program.registry.getObject("DTEL", rollname)) dataType.rollname = rollname;
    item.dataType = dataType;
  }
}
