import type { Declaration, ReportIR, SelectionState, StatePlan } from "../types.js";

// A report global: not declared in a routine, a local class or a dialog module,
// whose declarations the converter keeps with the module. Indentation does not
// matter; DATA anywhere else belongs to the program.
export function isReportGlobal(ir: ReportIR, item: Declaration): boolean {
  return item.statement?.scope !== "local"
    && !item.statement?.localClassName
    && !(ir.modules ?? []).some((module) => module.statements.includes(item.statement!));
}

export function buildStatePlan(ir: ReportIR): StatePlan {
  const globals = ir.declarations.filter((item) => isReportGlobal(ir, item) && ["data", "static", "tables", "ranges"].includes(item.kind)).flatMap((item) => item.names ?? []);
  const selections: string[] = ir.selections
    .flatMap((screen) => screen.elements)
    .filter((item) => ["parameter", "select-option"].includes(item.kind) && item.name)
    .map((item) => item.name!);
  const reserved = new Set([
    "IO_SESSION", "IO_BUILDER", "LO_WRITER", "LS_CURSOR", "LS_LINE", "LS_STATE", "LS_RANGE",
    "LT_LINES", "LV_LINE", "IS_LINE", "IS_RESUME", "CT_VALUES", "IT_VALUES", "IR_RECORD",
    "LV_GGCONV_DYNAMIC_NAME", "GGCONV_DYNAMIC_VALUE",
  ]);
  const used = new Set([...globals, ...selections]);
  const renames: Record<string, string> = {};
  for (const name of [...new Set(globals)].sort()) {
    if (!reserved.has(name)) continue;
    let candidate = `mv_${name.toLowerCase()}`;
    let suffix = 1;
    while (used.has(candidate)) candidate = `MV_${name}_${suffix++}`;
    renames[name] = candidate;
    used.add(candidate);
  }
  const selectionState: Record<string, SelectionState> = {};
  for (const name of [...new Set(selections)].sort()) {
    const selection = ir.selections
      .flatMap((screen) => screen.elements ?? [])
      .find((item) => item.name?.toUpperCase() === name);
    const base = `MV_${name}`;
    let candidate = base;
    let suffix = 1;
    while (used.has(candidate)) candidate = `${base}_${suffix++}`;
    used.add(candidate);
    selectionState[name] = {
      member: candidate.toLowerCase(),
      ranges: ir.selections.flatMap((screen) => screen.elements).some((item) => item.name === name && item.kind === "select-option"),
      dataType: selection?.dataType,
      additions: selection?.additions,
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
