const OPENERS = new Set(["If", "Do", "Loop", "Case", "Try", "While"]);
const BRANCHES = new Set(["Else", "When", "WhenOthers", "Catch", "Cleanup"]);
const CLOSERS = new Set(["EndIf", "EndDo", "EndLoop", "EndCase", "EndTry", "EndWhile"]);

function graph(name, statements) {
  const nodes = statements.map((statement, index) => ({
    id: `${name}:${index + 1}`,
    index,
    kind: statement.kind,
    source: statement.text,
    filename: statement.filename,
    span: statement.span,
  }));
  const edges = [];
  for (let index = 0; index < nodes.length - 1; index++) {
    const source = nodes[index];
    const target = nodes[index + 1];
    edges.push({ from: source.id, to: target.id, kind: source.kind === "CallSelectionScreen" || source.kind === "CallScreen" || source.kind === "Submit" || source.kind === "CallTransaction" ? "suspend" : BRANCHES.has(target.kind) ? "branch" : "next" });
  }
  return { name, nodes, edges, structured: nodes.some((node) => OPENERS.has(node.kind) || CLOSERS.has(node.kind)) };
}

export function buildControlFlowGraphs(ir) {
  const result = [];
  for (const block of ir.eventBlocks ?? []) {
    if (block.statements.some((statement) => ir.continuations.some((continuation) => continuation.filename === statement.filename && continuation.span.start.line === statement.span.start.line && continuation.span.start.column === statement.span.start.column))) {
      result.push(graph(`event:${block.event}:${result.length + 1}`, block.statements));
    }
  }
  for (const routine of ir.routines ?? []) {
    if (routine.statements.some((statement) => ir.continuations.some((continuation) => continuation.filename === statement.filename && continuation.span.start.line === statement.span.start.line && continuation.span.start.column === statement.span.start.column))) {
      result.push(graph(`form:${routine.name}`, routine.statements));
    }
  }
  return result;
}
