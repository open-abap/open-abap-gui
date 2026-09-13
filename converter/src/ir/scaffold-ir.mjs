function operationKind(source) {
  const value = source.trim().toUpperCase();
  if (value.startsWith("IO_SESSION->GET_LIST( )->GET_WRITER( )->WRITE_") || value.includes("LO_WRITER->WRITE_")) return "list-write";
  if (value.includes("SET_STATUS")) return "session-status";
  if (value.includes("SET_TITLE")) return "session-title";
  if (value.includes("MESSAGE(")) return "session-message";
  if (value.includes("CALL_SELECTION_SCREEN")) return "dialog-call-selection-screen";
  if (value.includes("CALL_SCREEN")) return "dialog-call-screen";
  if (value.includes("SUBMIT_AND_RETURN")) return "navigation-submit-return";
  if (value.includes("CALL_TRANSACTION")) return "navigation-call-transaction";
  if (value.includes("LEAVE_PROGRAM")) return "navigation-leave-program";
  if (value.includes("SET_NEXT_SCREEN")) return "dialog-set-next-screen";
  if (value.includes("GET_LIST_FROM_MEMORY")) return "navigation-list-from-memory";
  if (value.includes("ADD_") || value.includes("BEGIN_SCREEN") || value.includes("END_SCREEN") || value.includes("BEGIN_BLOCK")) return "screen-builder";
  if (/^IF\b|^ELSE\b|^ENDIF\b|^CASE\b|^WHEN\b|^ENDCASE\b/.test(value)) return "control-flow";
  if (/^RETURN\.?$/.test(value)) return "return";
  return "statement";
}

function operationNodes(body) {
  return body.flatMap((source, index) => String(source).split("\n").map((line, lineIndex) => ({
    kind: operationKind(line),
    source: line,
    order: index + lineIndex / 1000,
  })));
}

function selectionOperations(screenBuilder) {
  if (!screenBuilder) return [];
  if (screenBuilder.kind === "dynpro") {
    const operations = [];
    for (const screen of screenBuilder.dynproMetadata?.screens ?? []) {
      operations.push({ kind: "begin-screen", number: String(screen.number ?? "").padStart(4, "0"), title: screen.title });
      for (const element of screen.elements ?? []) operations.push({ kind: `add-${element.kind ?? "element"}`, ...element });
      operations.push({ kind: "end-screen", number: String(screen.number ?? "").padStart(4, "0") });
    }
    for (const flow of screenBuilder.dynproMetadata?.flowLogic ?? []) {
      for (const phase of ["pbo", "pai", "pov", "poh"]) {
        const modules = Array.isArray(flow[phase]) ? flow[phase] : flow[phase]?.modules ?? [];
        for (const module of modules) operations.push({ kind: `flow-${phase}`, screen: flow.screen, field: module.field ?? flow[phase]?.field, name: module.name ?? module });
      }
    }
    return operations;
  }
  const operations = [];
  for (const screen of screenBuilder.selections ?? []) {
    if (screen.number !== "0100" || screen.asWindow || screen.asSubscreen) operations.push({ kind: "begin-screen", number: screen.number, asWindow: Boolean(screen.asWindow), asSubscreen: Boolean(screen.asSubscreen) });
    for (const item of screen.elements ?? []) {
      if (item.kind === "layout") {
        operations.push({ kind: `layout-${item.layout}`, ...Object.fromEntries(Object.entries(item).filter(([key]) => !["statement", "span"].includes(key))) });
      } else {
        operations.push({ kind: `add-${item.kind}`, ...Object.fromEntries(Object.entries(item).filter(([key]) => !["statement", "span"].includes(key))) });
      }
    }
    if (screen.number !== "0100" || screen.asWindow || screen.asSubscreen) operations.push({ kind: "end-screen", number: screen.number });
  }
  return operations;
}

export function scaffoldIR({
  className,
  transactionCode,
  description,
  interfaces,
  members,
  methods,
  sourceMap,
  definition,
  transaction,
  screenBuilder,
  listProcessing,
  continuations,
  controlFlowGraphs,
  noOpMethods,
}) {
  return {
    kind: "scaffold-class",
    className,
    transactionCode,
    description,
    definition: { ...definition },
    transaction: { ...transaction },
    interfaces: [...interfaces],
    members: members.map((member) => typeof member === "string" ? { source: member } : { ...member }),
    methods: methods.map((method) => ({ ...method, body: [...method.body], operations: operationNodes(method.body) })),
    screenBuilder: screenBuilder ? { ...screenBuilder, operations: selectionOperations(screenBuilder) } : undefined,
    listProcessing: listProcessing ? {
      ...listProcessing,
      handlers: methods.filter((method) => method.name.startsWith("zif_gg_list_processing_v1~"))
        .map((method) => ({ name: method.name, operations: operationNodes(method.body) })),
    } : undefined,
    sessionOperations: methods.flatMap((method) => operationNodes(method.body)
      .filter((operation) => operation.kind.startsWith("session-") || operation.kind.startsWith("dialog-") || operation.kind.startsWith("navigation-"))
      .map((operation) => ({ ...operation, method: method.name }))),
    continuations: continuations ? continuations.map((item) => ({ ...item, capturedVariables: [...(item.capturedVariables ?? [])] })) : [],
    controlFlowGraphs: (controlFlowGraphs ?? []).map((graph) => ({
      ...graph,
      nodes: graph.nodes.map((node) => ({ ...node })),
      edges: graph.edges.map((edge) => ({ ...edge })),
    })),
    noOpMethods: [...(noOpMethods ?? [])],
    sourceMap: [...sourceMap],
  };
}
