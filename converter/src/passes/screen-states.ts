// SCREEN is a program global in ABAP: a FORM called from PBO loops over the
// same table as the PBO event itself. Only the PBO methods receive the states,
// as ct_states, so they store a reference to them in an attribute, and LOOP
// AT SCREEN anywhere else runs over that attribute. The selection-screen and
// dynpro states have different types, so each has its own attribute, and a
// FORM loops over the one of the screens it is called for.
import { performedForm } from "../abap/statements.js";
import type { ReportIR, Routine, Statement } from "../types.js";

export interface ScreenStates {
  kind: "selection" | "dynpro";
  table: string;
  guard?: string;
  row?: string;
  todo?: string;
}

interface ScreenStatePlan {
  defaultKind: "selection" | "dynpro";
  routines: Map<string, { kind: "selection" | "dynpro"; ambiguous: boolean }>;
  selection: boolean;
  dynpro: boolean;
}

const SELECTION_STATES = "mr_selection_states";
const DYNPRO_STATES = "mr_dynpro_states";
const DYNPRO_ROW = "mv_dynpro_row";

function hasLoopAtScreen(statements: Statement[] | undefined): boolean {
  return (statements ?? []).some((statement) => statement.kind === "LoopAtScreen");
}

function performedRoutines(ir: ReportIR, statementLists: Statement[][]): Set<string> {
  const reached = new Set<string>();
  const pending = [...statementLists];
  while (pending.length) {
    for (const statement of pending.pop() ?? []) {
      if (statement.kind !== "Perform") continue;
      const name = performedForm(statement.text);
      const routine = ir.routines?.find((item) => item.name === name);
      if (!routine || reached.has(routine.name)) continue;
      reached.add(routine.name);
      pending.push(routine.statements);
    }
  }
  return reached;
}

const plans = new WeakMap<ReportIR, ScreenStatePlan>();

// Which screens each FORM with LOOP AT SCREEN runs for, and which attributes
// the class needs. A FORM performed from a PBO event takes that screen's
// kind; one performed from neither takes the kind of the screens it is
// performed for at all, and the program's own kind when that is not known.
export function screenStatePlan(ir: ReportIR): ScreenStatePlan {
  if (plans.has(ir)) return plans.get(ir)!;
  const defaultKind: "selection" | "dynpro" = ir.programKind === "module-pool" ? "dynpro" : "selection";
  const blocks = ir.eventBlocks ?? [];
  const modules = ir.modules ?? [];
  const selectionOutput = performedRoutines(ir, blocks.filter((block) => block.event === "at_selection_screen_output").map((block) => block.statements));
  const dynproOutput = performedRoutines(ir, modules.filter((module) => module.direction === "OUTPUT").map((module) => module.statements));
  const selectionAny = performedRoutines(ir, blocks.map((block) => block.statements));
  const dynproAny = performedRoutines(ir, modules.map((module) => module.statements));
  const needed = new Set<"selection" | "dynpro">();
  const routines: ScreenStatePlan["routines"] = new Map();
  for (const routine of ir.routines ?? []) {
    if (!hasLoopAtScreen(routine.statements)) continue;
    const callers = (selection: Set<string>, dynpro: Set<string>): ("selection" | "dynpro")[] => [
      ...(selection.has(routine.name) ? ["selection" as const] : []),
      ...(dynpro.has(routine.name) ? ["dynpro" as const] : []),
    ];
    let kinds = callers(selectionOutput, dynproOutput);
    if (!kinds.length) kinds = callers(selectionAny, dynproAny);
    const kind = kinds.length === 1 ? kinds[0] : defaultKind;
    routines.set(routine.name, { kind, ambiguous: kinds.length > 1 });
    needed.add(kind);
  }
  if (blocks.some((block) => block.event !== "at_selection_screen_output" && hasLoopAtScreen(block.statements))) needed.add(defaultKind);
  if (modules.some((module) => module.direction !== "OUTPUT" && hasLoopAtScreen(module.statements))) needed.add("dynpro");
  if ((ir.localClasses ?? []).some((localClass) => (localClass.methods ?? []).some((localMethod) => hasLoopAtScreen(localMethod.statements)))) needed.add(defaultKind);
  // A continuation resumes outside the PBO method it was suspended in.
  if (ir.continuations?.length) {
    if (blocks.some((block) => block.event === "at_selection_screen_output" && hasLoopAtScreen(block.statements))) needed.add("selection");
    if (modules.some((module) => module.direction === "OUTPUT" && hasLoopAtScreen(module.statements))) needed.add("dynpro");
  }
  const plan = { defaultKind, routines, selection: needed.has("selection"), dynpro: needed.has("dynpro") };
  plans.set(ir, plan);
  return plan;
}

export function isAmbiguousScreenRoutine(ir: ReportIR, routine: Routine | undefined): boolean {
  return Boolean(routine && screenStatePlan(ir).routines.get(routine.name)?.ambiguous === true);
}

export function screenStateMembers(ir: ReportIR): string[] {
  const plan = screenStatePlan(ir);
  return [
    ...(plan.selection ? [`DATA ${SELECTION_STATES} TYPE REF TO zif_gg_selection_screen_types=>ty_states.`] : []),
    ...(plan.dynpro ? [`DATA ${DYNPRO_STATES} TYPE REF TO zif_gg_dynpro_types_v1=>ty_states.`, `DATA ${DYNPRO_ROW} TYPE i.`] : []),
  ];
}

export function selectionStatesSetter(ir: ReportIR): string[] {
  return screenStatePlan(ir).selection ? [`${SELECTION_STATES} = REF #( ct_states ).`] : [];
}

export function dynproStatesSetter(ir: ReportIR): string[] {
  return screenStatePlan(ir).dynpro ? [`${DYNPRO_STATES} = REF #( ct_states ).`, `${DYNPRO_ROW} = is_context-row.`] : [];
}

// The states LOOP AT SCREEN runs over outside the PBO methods. `owner` is the
// prefix that reaches the report class's attributes, `row` the table-control
// row a dynpro module runs for.
export function storedScreenStates(kind: "selection" | "dynpro", {owner = "", row = `${owner}${DYNPRO_ROW}`, todo}: { owner?: string; row?: string; todo?: string } = {}): ScreenStates {
  const attribute = `${owner}${kind === "dynpro" ? DYNPRO_STATES : SELECTION_STATES}`;
  return { kind, table: `${attribute}->*`, guard: attribute, ...(kind === "dynpro" ? { row } : {}), ...(todo ? { todo } : {}) };
}

export function routineScreenStates(ir: ReportIR, routine: Routine | undefined): ScreenStates {
  const entry = routine ? screenStatePlan(ir).routines.get(routine.name) : undefined;
  if (!entry) return storedScreenStates(screenStatePlan(ir).defaultKind);
  return storedScreenStates(entry.kind, entry.ambiguous
    ? { todo: `FORM ${routine!.name} is called for both selection screens and dynpros; LOOP AT SCREEN only runs over the ${entry.kind === "dynpro" ? "dynpro" : "selection-screen"} states.` }
    : {});
}
