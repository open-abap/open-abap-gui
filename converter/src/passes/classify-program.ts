import { Expressions } from "@abaplint/core";
import { leadingWords, statementAst } from "../abap/ast.js";
import { REPORT_EVENTS } from "../ir/report-ir.js";
import type { Statement } from "../types.js";

const EVENT_KINDS = new Map([
  ["LoadOfProgram", "load_of_program"],
  ["Initialization", "initialization"],
  ["StartOfSelection", "start_of_selection"],
  ["EndOfSelection", "end_of_selection"],
  ["TopOfPage", "top_of_page"],
  ["EndOfPage", "end_of_page"],
  ["AtLineSelection", "at_line_selection"],
  ["AtUserCommand", "at_user_command"],
  ["AtPF", "at_pf"],
  ["AtSelectionScreen", "at_selection_screen"],
]);

// The variants of AT SELECTION-SCREEN by their keywords, most specific first.
const SELECTION_SCREEN_EVENTS: [string, string][] = [
  ["AT SELECTION-SCREEN OUTPUT", "at_selection_screen_output"],
  ["AT SELECTION-SCREEN ON VALUE-REQUEST", "at_selection_screen_value_req"],
  ["AT SELECTION-SCREEN ON HELP-REQUEST", "at_selection_screen_help_req"],
  ["AT SELECTION-SCREEN ON EXIT-COMMAND", "at_selection_screen_on_exit"],
  ["AT SELECTION-SCREEN ON END OF", "at_selection_screen_on_end_of"],
  ["AT SELECTION-SCREEN ON BLOCK", "at_selection_screen_on_block"],
  ["AT SELECTION-SCREEN ON RADIOBUTTON GROUP", "at_selection_screen_on_radio"],
  ["AT SELECTION-SCREEN ON", "at_selection_screen_on_field"],
];

export function normalizedText(statement: Statement): string {
  return statement.text.replace(/\s+/g, " ").trim();
}

export function eventName(statement: Statement): string | undefined {
  if (statement.kind === "AtSelectionScreen") {
    const words = statementAst(statement.text)?.words() ?? "";
    return SELECTION_SCREEN_EVENTS.find(([prefix]) => words === prefix || words.startsWith(`${prefix} `))?.[1]
      ?? "at_selection_screen";
  }
  if (statement.kind === "TopOfPage" && statementAst(statement.text)?.words() === "TOP-OF-PAGE DURING LINE-SELECTION") {
    return "top_of_page_during_line_sel";
  }
  return EVENT_KINDS.get(statement.kind);
}

/** What an event header names: a screen field, block, radio button group or function key. */
export interface EventQualifier {
  field?: string;
  block?: string;
  group?: string;
  pfKey?: number;
}

// AT SELECTION-SCREEN ON VALUE-REQUEST FOR f, ON HELP-REQUEST FOR f and ON f
// name a field, of which a select-option's LOW and HIGH count as the field;
// ON BLOCK b a block, ON RADIOBUTTON GROUP g a group; AT PFnn a function key.
export function eventQualifier(text: string | undefined): EventQualifier {
  const ast = text === undefined ? undefined : statementAst(text);
  if (!ast) return {};
  const words = ast.words();
  const name = (node: Parameters<typeof ast.source>[0] | undefined) => node ? ast.source(node).toUpperCase() : undefined;
  if (words.startsWith("AT PF")) {
    const key = /^PF0*(\d+)$/i.exec(ast.node.getChildren()[1]?.getFirstToken().getStr() ?? "")?.[1];
    return key ? { pfKey: Number(key) } : {};
  }
  if (words.startsWith("AT SELECTION-SCREEN ON VALUE-REQUEST FOR") || words.startsWith("AT SELECTION-SCREEN ON HELP-REQUEST FOR")
      || words === "AT SELECTION-SCREEN ON _") {
    return { field: name(ast.findDirect(Expressions.FieldSub))?.split("-")[0] };
  }
  if (words.startsWith("AT SELECTION-SCREEN ON BLOCK")) return { block: name(ast.findDirect(Expressions.BlockName)) };
  if (words.startsWith("AT SELECTION-SCREEN ON RADIOBUTTON GROUP")) return { group: name(ast.findDirect(Expressions.Field)) };
  return {};
}

// The name a REPORT, PROGRAM, FUNCTION-POOL or INCLUDE statement gives.
function headerName(statement: Statement): string | undefined {
  const ast = statementAst(statement.text);
  const name = ast?.find(Expressions.ReportName) ?? ast?.find(Expressions.IncludeName);
  return name && ast ? ast.source(name).toUpperCase() : undefined;
}

function isClassPool(statement: Statement): boolean {
  return /^CLASS-POOL(?: |$)/.test(leadingWords(statement.text));
}

export function classifyProgram(statements: Statement[]) {
  const named = statements.find((item) => ["Report", "Program", "FunctionPool", "Include"].includes(item.kind) || isClassPool(item));
  const header = statements.find((item) => item.kind === "Report" || item.kind === "Program");
  const firstHeader = statements.find((item) => item.kind !== "Comment" && item.kind !== "Empty" && item.text.trim() !== "");
  const kind = header?.kind === "Program"
    ? "module-pool"
    : header?.kind === "Report"
      ? "report"
      : firstHeader?.kind === "Include"
        ? "include"
        : firstHeader?.kind === "FunctionPool"
          ? "function-pool"
          : firstHeader && isClassPool(firstHeader)
            ? "class-pool"
            : "unknown";
  return {
    programKind: kind,
    programName: named ? headerName(named) : undefined,
    header,
    events: REPORT_EVENTS.filter((event) => statements.some((item) => eventName(item) === event)),
  };
}
