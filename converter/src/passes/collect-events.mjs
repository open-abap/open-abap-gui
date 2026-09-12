import { addEvent } from "../ir/report-ir.mjs";
import { eventName } from "./classify-program.mjs";

const SINGLETON_EVENTS = new Set(["load_of_program", "initialization", "start_of_selection", "end_of_selection", "top_of_page", "end_of_page", "top_of_page_during_line_sel", "at_line_selection", "at_user_command"]);

function isRoutineStart(statement) {
  return statement.kind === "Form" || /^FORM\s+/i.test(statement.text);
}

function isRoutineEnd(statement) {
  return statement.kind === "EndForm" || /^ENDFORM\b/i.test(statement.text);
}

export function collectEvents(ir, statements) {
  // Statements before the first event belong to START-OF-SELECTION in an
  // executable report. Once an explicit LOAD-OF-PROGRAM header is seen, the
  // following top-level executable statements belong to that load event until
  // the next event header; do not relocate either case heuristically.
  let currentEvent = "start_of_selection";
  let routine = undefined;
  let moduleDepth = 0;
  let currentBlock;
  let localClassDepth = 0;
  const declarationKinds = new Set(["Data", "Constant", "Static", "FieldSymbol", "Parameter", "SelectOption", "SelectionScreen", "Tables", "Ranges", "Type", "TypeBegin", "TypeEnd", "DataBegin", "DataEnd"]);
  ir.eventQualifiers ??= {};
  for (const statement of statements) {
    if (statement.kind === "Include") continue;
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
    if (isRoutineStart(statement)) {
      routine = { name: /^FORM\s+([^\s.]+)/i.exec(statement.text)?.[1]?.toUpperCase(), statements: [], statement };
      ir.routines.push(routine);
      continue;
    }
    if (isRoutineEnd(statement)) {
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
    if (declarationKinds.has(statement.kind) && !currentBlock) {
      continue;
    }
    if (declarationKinds.has(statement.kind)) statement.scope = "local";
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
