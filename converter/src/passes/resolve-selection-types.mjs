// A PARAMETERS or SELECT-OPTIONS typed with a dictionary type, such as
// PARAMETERS p_count TYPE zcount, only names the type; the screen needs the
// built-in type behind it to render the field, e.g. an integer data element
// as a number field. The abaplint syntax check resolves the declared variable
// through the dictionary objects next to the report. When it cannot, because
// the objects are not in the converter input, the type stays as written.

const BUILT_IN = new Set(["C", "N", "D", "T", "I", "P", "F", "X", "STRING", "XSTRING"]);

function needsResolution(item) {
  const typ = String(item.dataType?.typ ?? "").toUpperCase();
  const additions = item.additions ?? "";
  if (/\bTYPE\b/i.test(additions)) return !BUILT_IN.has(typ);
  // LIKE and FOR take the type of a data object; without explicit metadata
  // it is left at the STRING default.
  if (/\b(?:LIKE|FOR)\b/i.test(additions)) return !BUILT_IN.has(typ) || typ === "STRING";
  return false;
}

function builtInType(type) {
  switch (type.constructor.name) {
    case "IntegerType":
    case "Integer8Type":
      return { typ: "I" };
    case "CharacterType":
      return { typ: "C", length: type.getLength() };
    case "NumericType":
      return { typ: "N", length: type.getLength() };
    case "DateType":
      return { typ: "D", length: 8 };
    case "TimeType":
      return { typ: "T", length: 6 };
    case "PackedType":
      return { typ: "P", length: type.getLength(), ...(type.getDecimals() ? { decimals: type.getDecimals() } : {}) };
    case "FloatType":
      return { typ: "F" };
    case "StringType":
      return { typ: "STRING" };
    case "HexType":
      return { typ: "X", length: type.getLength() };
    default:
      return undefined;
  }
}

export function resolveSelectionTypes(ir, programScope) {
  const pending = (ir.selections ?? [])
    .flatMap((screen) => screen.elements)
    .filter((item) => (item.kind === "parameter" || item.kind === "select-option") && item.name && needsResolution(item));
  if (!pending.length) return;
  const program = programScope();
  if (!program) return;
  const variables = program.scope.getData().vars;
  for (const item of pending) {
    let type = variables[item.name]?.getType();
    // A selection table's row carries the field type in LOW.
    if (item.kind === "select-option") type = type?.getRowType?.()?.getComponentByName?.("LOW");
    const dataType = type ? builtInType(type) : undefined;
    if (!dataType) continue;
    const rollname = type.getQualifiedName?.()?.toUpperCase();
    if (rollname && program.registry.getObject("DTEL", rollname)) dataType.rollname = rollname;
    item.dataType = dataType;
  }
}
