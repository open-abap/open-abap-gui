import { Expressions, Nodes } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import type { AstNode, StatementAst } from "../abap/ast.js";
import type { DataType, Declaration, SelectionElement, SelectionScreen, Span } from "../types.js";

/** The additions of a PARAMETERS or SELECT-OPTIONS statement, as written. */
export interface SelectionOptions {
  type?: string;
  /** LENGTH and DECIMALS right after TYPE, digits only. */
  length?: string;
  decimals?: string;
  /** The obsolete length after the name, as in p(10). */
  fieldLength?: string;
  like?: string;
  for?: string;
  defaultValue?: string;
  defaultHigh?: string;
  checkbox: boolean;
  listbox: boolean;
  radioGroup?: string;
  userCommand?: string;
  modifId?: string;
  memoryId?: string;
  matchcode?: string;
  visibleLength?: string;
  obligatory: boolean;
  lowerCase: boolean;
  noDisplay: boolean;
  noExtension: boolean;
  noIntervals: boolean;
}

/** The additions of the PARAMETERS or SELECT-OPTIONS statement `raw`. */
export function selectionOptions(raw: string | undefined): SelectionOptions {
  const ast = raw === undefined ? undefined : statementAst(raw);
  const operand = (phrase: string) => ast?.operand(phrase);
  const has = (phrase: string) => ast?.hasPhrase(phrase) ?? false;
  const children = ast?.node.getChildren() ?? [];
  // TYPE x LENGTH n DECIMALS m, read in that order as the screen reads it.
  const type = ast?.after("TYPE", ast.node);
  const next = (node: Nodes.ExpressionNode | Nodes.TokenNode | undefined, keyword: string) => {
    const index = node ? children.indexOf(node) : -1;
    const word = children[index + 1];
    if (index < 0 || !(word instanceof Nodes.TokenNode) || word.getFirstToken().getUpperStr() !== keyword) return undefined;
    return children[index + 2];
  };
  const lengthNode = next(type, "LENGTH");
  const decimalsNode = next(lengthNode ?? type, "DECIMALS");
  const digits = (node: AstNode | undefined) => {
    const value = node && ast ? ast.source(node) : undefined;
    return value !== undefined && /^\d+$/.test(value) ? value : undefined;
  };
  // A text symbol literal, 'text'(001), defaults to its text.
  const defaultNode = ast?.after("DEFAULT", ast.node);
  const defaultText = defaultNode instanceof Nodes.ExpressionNode ? defaultNode.findDirectExpression(Expressions.TextElementString)?.getChildren()[0] : undefined;
  const fieldLength = ast?.findDirect(Expressions.ConstantFieldLength)?.findFirstExpression(Expressions.Integer);
  return {
    type: type && ast ? ast.source(type) : undefined,
    length: digits(lengthNode),
    decimals: digits(decimalsNode),
    fieldLength: fieldLength && ast ? ast.source(fieldLength) : undefined,
    like: operand("LIKE"),
    for: operand("FOR"),
    defaultValue: defaultNode && ast ? ast.source(defaultText ?? defaultNode) : undefined,
    defaultHigh: next(defaultNode, "TO") && ast ? ast.source(next(defaultNode, "TO")!) : undefined,
    checkbox: has("AS CHECKBOX"),
    listbox: has("AS LISTBOX"),
    radioGroup: operand("RADIOBUTTON GROUP"),
    userCommand: operand("USER-COMMAND"),
    modifId: operand("MODIF ID"),
    memoryId: operand("MEMORY ID"),
    matchcode: operand("MATCHCODE OBJECT"),
    visibleLength: operand("VISIBLE LENGTH"),
    obligatory: has("OBLIGATORY"),
    lowerCase: has("LOWER CASE"),
    noDisplay: has("NO-DISPLAY"),
    noExtension: has("NO-EXTENSION"),
    noIntervals: has("NO INTERVALS"),
  };
}

function typeDefinition(options: SelectionOptions): DataType {
  // The type's own name: of a component type, as filepath-pathintern, the
  // structure. A dictionary type is resolved later, see resolveSelectionTypes.
  const typ = options.type?.toUpperCase().split(/-|=>/)[0] ?? "STRING";
  const defaultLength = typ === "D" ? 8 : typ === "T" ? 6 : undefined;
  return {
    typ,
    ...(options.length ? { length: Number(options.length) } : defaultLength !== undefined ? { length: defaultLength } : {}),
    ...(options.decimals ? { decimals: Number(options.decimals) } : {}),
  };
}

// The standard selection screen is 1000, a number no program can declare, so
// SELECTION-SCREEN BEGIN OF SCREEN 100 stays a screen of its own.
export const DEFAULT_SELECTION_SCREEN = "1000";

function defaultScreen(result: SelectionScreen[]): SelectionScreen {
  let screen = result.find((item) => item.number === DEFAULT_SELECTION_SCREEN);
  if (!screen) {
    screen = { number: DEFAULT_SELECTION_SCREEN, elements: [] };
    result.unshift(screen);
  }
  return screen;
}

// The position and length of COMMENT, ULINE and PUSHBUTTON: [/]pos(len).
function placement(ast: StatementAst, keyword: string): { position?: number; length?: number; end: number } {
  const children = ast.node.getChildren();
  let index = children.findIndex((child) => child instanceof Nodes.TokenNode && child.getFirstToken().getUpperStr() === keyword) + 1;
  let position: number | undefined;
  const first = children[index];
  if (first instanceof Nodes.TokenNodeRegex) {
    const digits = /^\/?(\d+)$/.exec(first.getFirstToken().getStr())?.[1];
    position = digits ? Number(digits) : undefined;
    index++;
  }
  let length: number | undefined;
  if (children[index]?.getFirstToken().getStr() === "(") {
    length = Number(ast.source(children[index + 1]));
    index += 3;
  }
  return { position, length, end: index };
}

// The text a COMMENT, PUSHBUTTON or TAB shows: TEXT-nnn or a field.
function textOperand(ast: StatementAst): Nodes.ExpressionNode | undefined {
  return ast.findDirect(Expressions.TextElement) ?? ast.findDirect(Expressions.InlineField);
}

// END OF BLOCK closes plain and tabbed blocks alike, so the names of open
// tabbed blocks decide which one it ends.
function layoutItem(raw: string, span: Span, tabbedBlocks: Set<string>): SelectionElement | undefined {
  const ast = statementAst(raw);
  if (!ast) return undefined;
  const words = ast.words().replace(/^SELECTION-SCREEN /, "");
  const upper = (node: AstNode | undefined) => node ? ast.source(node).toUpperCase() : undefined;
  if (words.startsWith("COMMENT")) {
    const { position, length } = placement(ast, "COMMENT");
    const text = textOperand(ast);
    const key = text?.get() instanceof Expressions.TextElement
      ? ast.sourceOf(Expressions.TextElementKey)!
      : text ? ast.source(text) : "";
    const name = /^[A-Z]\d+$/i.test(key) ? key.toUpperCase() : `CMT${position ?? "1"}`;
    return { kind: "layout", layout: "comment", name, text: upper(text), position, length, span };
  }
  if (words.startsWith("SKIP")) return { kind: "layout", layout: "skip", lines: Number(ast.operand("SKIP") ?? 1), span };
  if (words.startsWith("ULINE")) {
    const { position, length } = placement(ast, "ULINE");
    return { kind: "layout", layout: "uline", position, length, span };
  }
  if (words.startsWith("POSITION")) {
    const position = ast.operand("POSITION");
    return position && /^\d+$/.test(position) ? { kind: "layout", layout: "position", position: Number(position), span } : undefined;
  }
  if (words === "BEGIN OF LINE") return { kind: "layout", layout: "begin_line", span };
  if (words === "END OF LINE") return { kind: "layout", layout: "end_line", span };
  if (words.startsWith("BEGIN OF BLOCK")) {
    const title = ast.after("TITLE", ast.node);
    return { kind: "layout", layout: "begin_block", name: upper(ast.findDirect(Expressions.BlockName)), title: upper(title), withFrame: ast.hasPhrase("WITH FRAME"), span };
  }
  if (words.startsWith("END OF BLOCK")) {
    return { kind: "layout", layout: tabbedBlocks.delete(upper(ast.findDirect(Expressions.BlockName))!) ? "end_tabbed_block" : "end_block", span };
  }
  if (words.startsWith("PUSHBUTTON")) {
    const ucomm = ast.operand("USER-COMMAND")?.toUpperCase();
    if (!ucomm) return undefined;
    const { position, length } = placement(ast, "PUSHBUTTON");
    return { kind: "layout", layout: "pushbutton", name: `PB_${ucomm}`, text: upper(textOperand(ast)), position, length, ucomm, span };
  }
  if (words.startsWith("FUNCTION KEY")) {
    const number = Number(ast.operand("FUNCTION KEY"));
    return { kind: "layout", layout: "function_key", number, text: `FUNCTION_KEY_${number}`, span };
  }
  if (words.startsWith("BEGIN OF TABBED BLOCK")) {
    const name = upper(ast.findDirect(Expressions.BlockName))!;
    tabbedBlocks.add(name);
    return { kind: "layout", layout: "begin_tabbed_block", name, lines: Number(ast.operand("FOR")), span };
  }
  if (words.startsWith("TAB")) {
    const ucomm = ast.operand("USER-COMMAND")?.toUpperCase();
    const subscreen = ast.operand("DEFAULT SCREEN");
    const name = upper(textOperand(ast));
    if (!ucomm || !subscreen || !name) return undefined;
    return { kind: "layout", layout: "tab", name, text: name, ucomm, subscreen: subscreen.padStart(4, "0"), span };
  }
  return undefined;
}

export function collectSelectionScreens(declarations: Declaration[]): SelectionScreen[] {
  const result: SelectionScreen[] = [];
  let currentScreen: SelectionScreen | undefined;
  let inLine = false;
  const tabbedBlocks = new Set<string>();
  for (const declaration of declarations) {
    if (declaration.kind === "selectionscreen") {
      const ast = statementAst(declaration.raw);
      const words = ast?.words() ?? "";
      const number = ast?.sourceOf(Expressions.Integer);
      if (ast && number && words.startsWith("SELECTION-SCREEN BEGIN OF SCREEN")) {
        const additions = declaration.raw.slice(ast.end(ast.find(Expressions.Integer)!));
        const title = ast.after("TITLE", ast.node);
        currentScreen = {
          number: number.padStart(4, "0"),
          additions,
          ...(title?.get() instanceof Expressions.InlineField ? { titleField: ast.source(title).toUpperCase() } : {}),
          asWindow: ast.hasPhrase("AS WINDOW"),
          asSubscreen: ast.hasPhrase("AS SUBSCREEN"),
          elements: [],
          span: declaration.statement.span,
        };
        result.push(currentScreen);
      } else if (words.startsWith("SELECTION-SCREEN END OF SCREEN")) {
        currentScreen = undefined;
      } else {
        const item = layoutItem(declaration.raw, declaration.statement.span, tabbedBlocks);
        if (item) {
          (currentScreen ?? defaultScreen(result)).elements.push(item);
          if (item.layout === "begin_line") inLine = true;
          if (item.layout === "end_line") inLine = false;
        }
      }
      continue;
    }
    if (declaration.kind === "parameter" || declaration.kind === "select-option") {
      const options = selectionOptions(declaration.raw);
      const item: SelectionElement = {
        ...declaration,
        dataType: typeDefinition(options),
        default: options.defaultValue,
        screen: currentScreen?.number ?? DEFAULT_SELECTION_SCREEN,
        text: inLine ? "" : declaration.name,
        suppressTextPool: inLine,
      };
      (currentScreen ?? defaultScreen(result)).elements.push(item);
    }
  }
  return result;
}
