import { formName, isFormEnd, isFormStart } from "../abap/statements.js";
import { addEvent } from "../ir/report-ir.js";
import { eventName } from "./classify-program.js";
import { leadingComments } from "./collect-modules.js";
import type { ReportIR, Routine, Statement } from "../types.js";

const FORWARD_DECLARATION_KINDS = new Set(["ClassDeferred", "InterfaceDeferred", "ClassDefinitionLoad", "InterfaceLoad"]);
// abaplint expands each macro call where it stands, so the definition is no
// code of its own.
export const MACRO_DEFINITION_KINDS = new Set(["Define", "MacroContent", "EndOfDefinition"]);

const SINGLETON_EVENTS = new Set(["load_of_program", "initialization", "start_of_selection", "end_of_selection", "top_of_page", "end_of_page", "top_of_page_during_line_sel", "at_line_selection", "at_user_command"]);

export function collectEvents(ir: ReportIR, statements: Statement[]): ReportIR {
  // Statements before the first event belong to START-OF-SELECTION in an
  // executable report. Once an explicit LOAD-OF-PROGRAM header is seen, the
  // following top-level executable statements belong to that load event until
  // the next event header; do not relocate either case heuristically.
  let currentEvent = "start_of_selection";
  let routine: Routine | undefined;
  let moduleDepth = 0;
  let currentBlock: ReportIR["eventBlocks"][number] | undefined;
  let localClassDepth = 0;
  const declarationKinds = new Set(["Data", "Constant", "ConstantBegin", "ConstantEnd", "Static", "StaticBegin", "StaticEnd", "FieldSymbol", "Parameter", "SelectOption", "SelectionScreen", "Tables", "Ranges", "Type", "TypeBegin", "TypeEnd", "IncludeType", "DataBegin", "DataEnd", "TypePools"]);
  ir.eventQualifiers ??= {};
  const blockComments = leadingComments(statements);
  const movedComments = new Set([...blockComments.values()].flat());
  for (const statement of statements) {
    if (statement.kind === "Include") continue;
    if (movedComments.has(statement)) continue;
    // Forward declarations and the obsolete LOAD additions only steer the
    // compiler; local classes become global helper classes, which need neither.
    if (FORWARD_DECLARATION_KINDS.has(statement.kind)) continue;
    if (MACRO_DEFINITION_KINDS.has(statement.kind)) continue;
    if (["ClassDefinition", "ClassImplementation"].includes(statement.kind)) {
      localClassDepth++;
      continue;
    }
    if (statement.kind === "EndClass") {
      localClassDepth = Math.max(0, localClassDepth - 1);
      continue;
    }
    if (localClassDepth > 0) continue;
    if (statement.kind === "Module") {
      moduleDepth++;
      continue;
    }
    if (statement.kind === "EndModule") {
      moduleDepth = Math.max(0, moduleDepth - 1);
      continue;
    }
    if (moduleDepth > 0) continue;
    if (["Report", "Program"].includes(statement.kind)) continue;
    if (isFormStart(statement)) {
      routine = { name: formName(statement)!, statements: [...(blockComments.get(statement) ?? [])], statement };
      ir.routines.push(routine);
      continue;
    }
    if (isFormEnd(statement)) {
      routine = undefined;
      continue;
    }
    const event = eventName(statement);
    if (event) {
      currentEvent = event;
      ir.eventHeaders[event] ??= [];
      if (SINGLETON_EVENTS.has(event) && ir.eventHeaders[event].length) ir.duplicateEvents.push({ event, statement });
      ir.eventHeaders[event].push(statement);
      ir.eventQualifiers[event] = statement.text;
      currentBlock = { event, qualifier: statement.text, statements: [] };
      ir.eventBlocks.push(currentBlock);
      continue;
    }
    if (routine) {
      if (declarationKinds.has(statement.kind)) statement.scope = "local";
      routine.statements.push(statement);
      continue;
    }
    if (declarationKinds.has(statement.kind)) continue;
    currentBlock ??= { event: currentEvent, qualifier: undefined, statements: [] };
    if (!ir.eventBlocks.includes(currentBlock)) ir.eventBlocks.push(currentBlock);
    currentBlock.statements.push(statement);
    addEvent(ir, currentEvent, statement);
  }
  for (const event of Object.keys(ir.events)) {
    const entries = ir.events[event];
    if (entries.length > 0 && !ir.features.includes(`event:${event}`)) ir.features.push(`event:${event}`);
  }
  return ir;
}
