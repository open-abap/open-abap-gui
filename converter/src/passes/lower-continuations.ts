import crypto from "node:crypto";
import { Expressions, Statements } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import { callsStatic, functionModule, referencedNames } from "../abap/statements.js";
import { BLOCK_BRANCHES, BLOCK_ENDS, BLOCK_OPENERS, closesBlock } from "./blocks.js";
import type { Continuation, ControlFrame, Statement } from "../types.js";

const CONTROL_WORDS = new Set(["CALL", "SCREEN", "SELECTION", "SUBMIT", "AND", "RETURN", "TRANSACTION", "USING", "WITH", "VALUE", "TYPE", "IF", "ELSE", "ELSEIF", "ENDIF", "DO", "ENDDO", "CASE", "WHEN", "ENDCASE"]);

// The popups the host shows and returns from, which suspend like a screen.
const POPUP_FUNCTIONS = ["POPUP_TO_CONFIRM", "POPUP_TO_INFORM", "POPUP_GET_VALUES", "POPUP_WITH_TABLE_DISPLAY", "POPUP_TO_SELECT_MONTH"];
const FRONTEND_DIALOGS = ["FILE_OPEN_DIALOG", "FILE_SAVE_DIALOG", "CLIPBOARD_IMPORT"];

export function isPopupStatement(statement: Statement): boolean {
  return (statement.kind === "CallFunction" && POPUP_FUNCTIONS.includes(functionModule(statement.text) ?? ""))
    || (["Call", "CallMethod"].includes(statement.kind) && callsStatic(statement.text, "CL_GUI_FRONTEND_SERVICES", FRONTEND_DIALOGS));
}

export function isSuspendingStatement(statement: Statement): boolean {
  if (isPopupStatement(statement)) return true;
  if (["CallScreen", "CallSelectionScreen", "CallTransaction"].includes(statement.kind)) return true;
  return statement.kind === "Submit" && Boolean(statementAst(statement.text)?.findDirect(Expressions.AndReturn));
}

function names(text: string): Set<string> {
  return new Set(referencedNames(text).filter((name) => !CONTROL_WORDS.has(name)));
}

// The variable an assignment writes, or its component.
function assigned(text: string): string | undefined {
  const ast = statementAst(text);
  const target = ast?.is(Statements.Move) ? ast.findDirect(Expressions.Target) : undefined;
  const name = target && ast ? ast.source(target) : undefined;
  return name && /^[A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)?$/i.test(name) ? name.toUpperCase() : undefined;
}

// The screen a CALL SCREEN or CALL SELECTION-SCREEN calls, if a number.
function calledScreen(statement: Statement): string | undefined {
  if (statement.kind !== "CallScreen" && statement.kind !== "CallSelectionScreen") return undefined;
  const screen = statementAst(statement.text)?.sourceOf(Expressions.Source);
  return screen && /^\d+$/.test(screen) ? screen.padStart(4, "0") : undefined;
}

export function collectContinuations(statements: Statement[], knownVariables: string[] = []): Continuation[] {
  const controlStack: ControlFrame[] = [];
  const result: { statement: Statement; contextDepth: number; controlStack: ControlFrame[] }[] = [];
  const declared = statements.flatMap((statement) => {
    if (!['Data', 'Static'].includes(statement.kind)) return [];
    const name = statementAst(statement.text)?.sourceOf(Expressions.DefinitionName);
    return name ? [name.toUpperCase()] : [];
  });
  const known = new Set([...knownVariables, ...declared].map((name) => name.toUpperCase()));
  for (const statement of statements) {
    const contextDepth = controlStack.length;
    if (isSuspendingStatement(statement)) {
      result.push({
        statement,
        contextDepth,
        controlStack: controlStack.map((item) => ({ ...item })),
      });
    }
    if (BLOCK_BRANCHES.has(statement.kind) && controlStack.length) {
      controlStack[controlStack.length - 1].branch = statement.kind;
    }
    if (BLOCK_OPENERS.has(statement.kind)) controlStack.push({
      kind: statement.kind,
      branch: "body",
    });
    if (BLOCK_ENDS.has(statement.kind)) {
      const index = controlStack.findLastIndex((item) => closesBlock(item.kind, statement.kind));
      if (index >= 0) controlStack.splice(index, 1);
    }
  }
  const usedIds = new Map<string, number>();
  return result.map(({ statement, contextDepth, controlStack }) => {
    const index = statements.indexOf(statement);
    const before = new Set(statements.slice(0, index + 1).map((item) => assigned(item.text)).filter(Boolean));
    const after = new Set(statements.slice(index + 1).flatMap((item) => [...names(item.text)]));
    const liveVariables = [...after].filter((name) => before.has(name) || known.has(name)).sort();
    const seed = `${statement.filename}:${statement.span.start.line}:${statement.span.start.column}`;
    const sourceId = `C_${crypto.createHash("sha1").update(seed).digest("hex").slice(0, 10).toUpperCase()}`;
    const raw = statement.text.trim();
    const screen = calledScreen(statement);
    const base = screen ? `AFTER_${screen}`
      : statement.kind === "Submit" ? "AFTER_SUBMIT"
        : statement.kind === "CallTransaction" ? "AFTER_TCODE"
          : sourceId;
    const count = usedIds.get(base) ?? 0;
    usedIds.set(base, count + 1);
    const id = count === 0 ? base : `${base}_${sourceId.slice(2, 8)}`;
    return { id, sourceId, filename: statement.filename, span: statement.span, source: raw, contextDepth, controlStack, liveVariables };
  });
}
