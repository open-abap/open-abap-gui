import crypto from "node:crypto";
import { BLOCK_BRANCHES, BLOCK_ENDS, BLOCK_OPENERS, closesBlock } from "./blocks.mjs";

const CONTROL_WORDS = new Set(["CALL", "SCREEN", "SELECTION", "SUBMIT", "AND", "RETURN", "TRANSACTION", "USING", "WITH", "VALUE", "TYPE", "IF", "ELSE", "ELSEIF", "ENDIF", "DO", "ENDDO", "CASE", "WHEN", "ENDCASE"]);

export function isPopupStatement(statement) {
  return (statement.kind === "CallFunction" && /CALL\s+FUNCTION\s+'POPUP_(?:TO_CONFIRM|TO_INFORM|GET_VALUES|WITH_TABLE_DISPLAY|TO_SELECT_MONTH)'/i.test(statement.text))
    || (["Call", "CallMethod"].includes(statement.kind) && /\bcl_gui_frontend_services\s*=>\s*(?:file_open_dialog|file_save_dialog|clipboard_import)\b/i.test(statement.text));
}

export function isSuspendingStatement(statement) {
  if (isPopupStatement(statement)) return true;
  if (["CallScreen", "CallSelectionScreen", "CallTransaction"].includes(statement.kind)) return true;
  return statement.kind === "Submit" && /\bAND\s+RETURN\b/i.test(statement.text);
}

function names(text) {
  return new Set([...text.replace(/'(?:''|[^'])*'/g, " ").matchAll(/\b[A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)?\b/gi)]
    .map((match) => match[0].toUpperCase())
    .filter((name) => !CONTROL_WORDS.has(name) && !name.startsWith("TEXT-")));
}

function assigned(text) {
  return /^\s*([A-Z][A-Z0-9_]*(?:-[A-Z][A-Z0-9_]*)?)\s*=/i.exec(text)?.[1]?.toUpperCase();
}

export function collectContinuations(statements, knownVariables = []) {
  const controlStack = [];
  const result = [];
  const declared = statements.flatMap((statement) => {
    if (!['Data', 'Static'].includes(statement.kind)) return [];
    return [...String(statement.text ?? '').matchAll(/\b(?:DATA|STATICS)\s+([A-Z][A-Z0-9_]*)\b/gi)]
      .map((match) => match[1].toUpperCase());
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
  const usedIds = new Map();
  return result.map(({ statement, contextDepth, controlStack }) => {
    const index = statements.indexOf(statement);
    const before = new Set(statements.slice(0, index + 1).map((item) => assigned(item.text)).filter(Boolean));
    const after = new Set(statements.slice(index + 1).flatMap((item) => [...names(item.text)]));
    const liveVariables = [...after].filter((name) => before.has(name) || known.has(name)).sort();
    const seed = `${statement.filename}:${statement.span.start.line}:${statement.span.start.column}`;
    const sourceId = `C_${crypto.createHash("sha1").update(seed).digest("hex").slice(0, 10).toUpperCase()}`;
    const raw = statement.text.trim();
    const base = /CALL\s+SELECTION-SCREEN\s+(\d+)/i.exec(raw)?.[1]
      ? `AFTER_${/CALL\s+SELECTION-SCREEN\s+(\d+)/i.exec(raw)[1].padStart(4, "0")}`
      : /CALL\s+SCREEN\s+(\d+)/i.exec(raw)?.[1]
        ? `AFTER_${/CALL\s+SCREEN\s+(\d+)/i.exec(raw)[1].padStart(4, "0")}`
        : /SUBMIT\b/i.test(raw)
          ? "AFTER_SUBMIT"
          : /CALL\s+TRANSACTION\b/i.test(raw)
            ? "AFTER_TCODE"
            : sourceId;
    const count = usedIds.get(base) ?? 0;
    usedIds.set(base, count + 1);
    const id = count === 0 ? base : `${base}_${sourceId.slice(2, 8)}`;
    return { id, sourceId, filename: statement.filename, span: statement.span, source: raw, contextDepth, controlStack, liveVariables };
  });
}
