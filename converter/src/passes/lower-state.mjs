export function buildStatePlan(ir) {
  const globals = ir.declarations.filter((item) => item.statement?.scope !== "local" && !item.statement?.localClassName && ["data", "static", "tables", "ranges"].includes(item.kind)).flatMap((item) => item.names ?? []);
  const selections = ir.selections
    .flatMap((screen) => screen.elements)
    .filter((item) => ["parameter", "select-option"].includes(item.kind) && item.name)
    .map((item) => item.name);
  const reserved = new Set([
    "IO_SESSION", "IO_BUILDER", "LO_WRITER", "LS_CURSOR", "LS_LINE", "LS_STATE", "LS_RANGE",
    "LT_LINES", "LV_LINE", "IS_LINE", "IS_RESUME", "CT_VALUES", "IT_VALUES", "IR_RECORD",
    "LV_GGCONV_DYNAMIC_NAME", "GGCONV_DYNAMIC_VALUE",
  ]);
  const used = new Set([...globals, ...selections]);
  const renames = {};
  for (const name of [...new Set(globals)].sort()) {
    if (!reserved.has(name)) continue;
    let candidate = `mv_${name.toLowerCase()}`;
    let suffix = 1;
    while (used.has(candidate)) candidate = `MV_${name}_${suffix++}`;
    renames[name] = candidate;
    used.add(candidate);
  }
  const selectionState = {};
  for (const name of [...new Set(selections)].sort()) {
    const base = `MV_${name}`;
    let candidate = base;
    let suffix = 1;
    while (used.has(candidate)) candidate = `${base}_${suffix++}`;
    used.add(candidate);
    selectionState[name] = {
      member: candidate.toLowerCase(),
      ranges: ir.selections.flatMap((screen) => screen.elements).some((item) => item.name === name && item.kind === "select-option"),
    };
  }
  return {
    globals: [...new Set(globals)].sort(),
    selections: [...new Set(selections)].sort(),
    renames,
    selectionState,
    hydration: selections.map((name) => ({ name, from: "it_values", target: selectionState[name].member })),
    flush: selections.map((name) => ({ name, source: selectionState[name].member, to: "ct_values" })),
    systemFields: { ucomm: "iv_ucomm", subrc: "sy-subrc", listIndex: "iv_line_index" },
  };
}
