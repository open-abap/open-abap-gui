export const REPORT_EVENTS = [
  "load_of_program", "initialization", "start_of_selection", "end_of_selection",
  "at_selection_screen_output", "at_selection_screen", "at_selection_screen_on_field",
  "at_selection_screen_on_end_of", "at_selection_screen_on_block", "at_selection_screen_on_radio",
  "at_selection_screen_value_req", "at_selection_screen_help_req", "at_selection_screen_on_exit",
  "top_of_page", "end_of_page", "top_of_page_during_line_sel",
  "at_line_selection", "at_user_command", "at_pf",
];

export function emptyReportIR({ filename, source, sourceHash, newline }) {
  return {
    kind: "report",
    programName: undefined,
    header: { raw: "", lineSize: undefined, lineCount: undefined, footerLines: undefined, noStandardPageHeading: false },
    source: { filename, source, sourceHash, newline },
    units: [],
    statements: [],
    declarations: [],
    selections: [],
    events: Object.fromEntries(REPORT_EVENTS.map((event) => [event, []])),
    eventQualifiers: {},
    eventHeaders: {},
    duplicateEvents: [],
    eventBlocks: [],
    routines: [],
    localClasses: [],
    modules: [],
    controlFlowGraphs: [],
    dynproMetadata: undefined,
    screenMetadata: undefined,
    guiStatusMetadata: {},
    references: { globals: [], selections: [] },
    programKind: "unknown",
    interfaces: ["zif_gg_report_v1", "zif_gg_transaction_v1"],
    features: [],
    capabilities: [],
  };
}

export function addEvent(ir, name, statement) {
  if (!ir.events[name]) ir.events[name] = [];
  ir.events[name].push(statement);
}
