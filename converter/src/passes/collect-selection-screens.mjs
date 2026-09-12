import { declarationInfo } from "./collect-declarations.mjs";

function quoted(value) {
  const match = /'((?:''|[^'])*)'/.exec(value);
  return match ? `'${match[1]}'` : undefined;
}

function typeDefinition(additions) {
  const type = /\bTYPE\s+([A-Z0-9_\/]+)(?:\s+LENGTH\s+(\d+))?(?:\s+DECIMALS\s+(\d+))?/i.exec(additions);
  const typ = type?.[1]?.toUpperCase() ?? "STRING";
  const defaultLength = typ === "D" ? 8 : typ === "T" ? 6 : undefined;
  return {
    typ,
    ...(type?.[2] ? { length: Number(type[2]) } : defaultLength !== undefined ? { length: defaultLength } : {}),
    ...(type?.[3] ? { decimals: Number(type[3]) } : {}),
  };
}

function defaultScreen(result) {
  let screen = result.find((item) => item.number === "0100");
  if (!screen) {
    screen = { number: "0100", elements: [] };
    result.unshift(screen);
  }
  return screen;
}

function layoutItem(raw, span) {
  const text = raw.replace(/\.$/, "");
  let match = /COMMENT\s+\/?(\d+)?(?:\((\d+)\))?\s+([^\s]+)/i.exec(text);
  if (match) {
    const key = match[3].replace(/^TEXT[-_]/i, "");
    const name = /^[A-Z]\d+$/i.test(key) ? key.toUpperCase() : `CMT${match[1] ?? "1"}`;
    return { kind: "layout", layout: "comment", name, text: match[3].toUpperCase(), position: match[1] ? Number(match[1]) : undefined, length: match[2] ? Number(match[2]) : undefined, span };
  }
  match = /SKIP\s+(\d+)/i.exec(text);
  if (match) return { kind: "layout", layout: "skip", lines: Number(match[1]), span };
  match = /ULINE\s+\/?(\d+)?(?:\((\d+)\))?/i.exec(text);
  if (match) return { kind: "layout", layout: "uline", position: match[1] ? Number(match[1]) : undefined, length: match[2] ? Number(match[2]) : undefined, span };
  match = /POSITION\s+(\d+)/i.exec(text);
  if (match) return { kind: "layout", layout: "position", position: Number(match[1]), span };
  if (/BEGIN OF LINE/i.test(text)) return { kind: "layout", layout: "begin_line", span };
  if (/END OF LINE/i.test(text)) return { kind: "layout", layout: "end_line", span };
  match = /BEGIN OF BLOCK\s+(\w+)(.*)$/i.exec(text);
  if (match) return { kind: "layout", layout: "begin_block", name: match[1].toUpperCase(), title: /TITLE\s+([^\s]+)/i.exec(match[2])?.[1]?.toUpperCase(), withFrame: /WITH FRAME/i.test(match[2]), span };
  match = /END OF BLOCK\s+(\w+)/i.exec(text);
  if (match) return { kind: "layout", layout: "end_block", span };
  match = /PUSHBUTTON\s+\/?(\d+)?(?:\((\d+)\))?\s+([^\s]+).*USER-COMMAND\s+(\w+)/i.exec(text);
  if (match) return { kind: "layout", layout: "pushbutton", name: `PB_${match[4].toUpperCase()}`, text: match[3].toUpperCase(), position: match[1] ? Number(match[1]) : undefined, length: match[2] ? Number(match[2]) : undefined, ucomm: match[4].toUpperCase(), span };
  match = /FUNCTION KEY\s+(\d+)/i.exec(text);
  if (match) return { kind: "layout", layout: "function_key", number: Number(match[1]), text: `FUNCTION_KEY_${match[1]}`, span };
  match = /BEGIN OF TABBED BLOCK\s+(\w+)\s+FOR\s+(\d+)\s+LINES/i.exec(text);
  if (match) return { kind: "layout", layout: "begin_tabbed_block", name: match[1].toUpperCase(), lines: Number(match[2]), span };
  match = /TAB\s+\((\d+)\)\s+(\w+).*USER-COMMAND\s+(\w+).*DEFAULT SCREEN\s+(\d+)/i.exec(text);
  if (match) return { kind: "layout", layout: "tab", name: match[2].toUpperCase(), text: match[2].toUpperCase(), ucomm: match[3].toUpperCase(), subscreen: match[4].padStart(4, "0"), span };
  if (/END OF BLOCK/i.test(text)) return { kind: "layout", layout: "end_tabbed_block", span };
  return undefined;
}

export function collectSelectionScreens(declarations) {
  const result = [];
  let currentScreen = undefined;
  let inLine = false;
  for (const declaration of declarations) {
    if (declaration.kind === "selectionscreen") {
      const begin = /BEGIN OF SCREEN\s+(\d+)(.*)$/i.exec(declaration.raw);
      const end = /END OF SCREEN\s+(\d+)/i.exec(declaration.raw);
      if (begin) {
        currentScreen = {
          number: begin[1].padStart(4, "0"),
          additions: begin[2],
          asWindow: /AS WINDOW/i.test(begin[2]),
          asSubscreen: /AS SUBSCREEN/i.test(begin[2]),
          elements: [],
          span: declaration.statement.span,
        };
        result.push(currentScreen);
      } else if (end) {
        currentScreen = undefined;
      } else if (currentScreen) {
        const item = layoutItem(declaration.raw, declaration.statement.span);
        if (item) {
          currentScreen.elements.push(item);
          if (item.layout === "begin_line") inLine = true;
          if (item.layout === "end_line") inLine = false;
        }
      } else {
        const item = layoutItem(declaration.raw, declaration.statement.span);
        if (item) {
          defaultScreen(result).elements.push(item);
          if (item.layout === "begin_line") inLine = true;
          if (item.layout === "end_line") inLine = false;
        }
      }
      continue;
    }
    if (declaration.kind === "parameter" || declaration.kind === "select-option") {
      const item = {
        ...declaration,
        dataType: typeDefinition(declaration.additions),
        default: quoted(declaration.additions),
        screen: currentScreen?.number ?? "0100",
        text: inLine ? "" : declaration.name,
        suppressTextPool: inLine,
      };
      if (currentScreen) currentScreen.elements.push(item);
      else defaultScreen(result).elements.push(item);
    }
  }
  return result;
}
