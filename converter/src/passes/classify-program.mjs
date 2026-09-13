import { REPORT_EVENTS } from "../ir/report-ir.mjs";

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

export function normalizedText(statement) {
  return statement.text.replace(/\s+/g, " ").trim();
}

export function eventName(statement) {
  const text = normalizedText(statement).toUpperCase();
  if (text === "AT SELECTION-SCREEN OUTPUT.") return "at_selection_screen_output";
  if (text.includes("AT SELECTION-SCREEN ON VALUE-REQUEST")) return "at_selection_screen_value_req";
  if (text.includes("AT SELECTION-SCREEN ON HELP-REQUEST")) return "at_selection_screen_help_req";
  if (text.includes("AT SELECTION-SCREEN ON EXIT-COMMAND")) return "at_selection_screen_on_exit";
  if (text.includes("AT SELECTION-SCREEN ON END OF")) return "at_selection_screen_on_end_of";
  if (text.includes("AT SELECTION-SCREEN ON BLOCK")) return "at_selection_screen_on_block";
  if (text.includes("AT SELECTION-SCREEN ON RADIOBUTTON GROUP")) return "at_selection_screen_on_radio";
  if (text.includes("AT SELECTION-SCREEN ON ")) return "at_selection_screen_on_field";
  if (text === "TOP-OF-PAGE DURING LINE-SELECTION.") return "top_of_page_during_line_sel";
  // GET CURSOR is an executable list statement. Check the concrete parser
  // kind before any generic GET handling.
  if (statement.kind === "GetCursor" || /^GET\s+CURSOR\b/i.test(text)) return undefined;
  const direct = EVENT_KINDS.get(statement.kind);
  if (direct) return direct;
  return undefined;
}

export function reportName(statements) {
  const header = statements.find((item) => item.kind === "Report" || item.kind === "Program" || item.kind === "FunctionPool" || /^\s*(?:INCLUDE|FUNCTION-POOL|CLASS-POOL)\b/i.test(item.text));
  if (!header) return undefined;
  const match = /^\s*(?:REPORT|PROGRAM|INCLUDE|FUNCTION-POOL|CLASS-POOL)\s+([^\s.]+)/i.exec(header.text);
  return match?.[1]?.toUpperCase();
}

export function classifyProgram(statements) {
  const name = reportName(statements);
  const header = statements.find((item) => item.kind === "Report" || item.kind === "Program");
  const firstHeader = statements.find((item) => item.kind !== "Comment" && item.kind !== "Empty" && item.text.trim() !== "");
  const headerText = firstHeader?.text.trim() ?? "";
  const kind = header?.kind === "Program"
    ? "module-pool"
    : header?.kind === "Report"
      ? "report"
      : /^INCLUDE\b/i.test(headerText)
        ? "include"
        : /^FUNCTION-POOL\b/i.test(headerText) || firstHeader?.kind === "FunctionPool"
          ? "function-pool"
          : /^CLASS-POOL\b/i.test(headerText)
            ? "class-pool"
            : "unknown";
  return {
    programKind: kind,
    programName: name,
    header,
    events: REPORT_EVENTS.filter((event) => statements.some((item) => eventName(item) === event)),
  };
}
