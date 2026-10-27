import { Comment, Config, MemoryFile, Nodes, Unknown } from "@abaplint/core";
import type { Token } from "@abaplint/core";
import { ABAPParser } from "@abaplint/core/build/src/abap/abap_parser.js";

// The converter rewrites ABAP as text, but finds its way around a statement
// through the abaplint syntax tree of that text. The text is parsed on its own,
// so the position of every token is an offset into it, and a node's source is
// the slice of the text it spans: what a rewrite copies keeps its spelling,
// layout and comments.

export type AstNode = Nodes.StatementNode | Nodes.ExpressionNode | Nodes.TokenNode;
/** An expression class, such as Expressions.Source. */
export type ExpressionType = Parameters<Nodes.ExpressionNode["findFirstExpression"]>[0];
/** A statement class, such as Statements.Write. */
export type StatementType = new () => object;

/** A token of the text, with the node that holds it and the nodes above. */
export interface TokenEntry {
  token: Token;
  node: Nodes.TokenNode;
  parent: Nodes.StatementNode | Nodes.ExpressionNode;
  /** From the statement down to the parent. */
  ancestors: (Nodes.StatementNode | Nodes.ExpressionNode)[];
  statement: Nodes.StatementNode;
  start: number;
  end: number;
}

let parser: ABAPParser | undefined;

function abapParser(): ABAPParser {
  parser ??= new ABAPParser({ release: Config.getDefault().getRelease(), reg: undefined });
  return parser;
}

function lineStarts(text: string): number[] {
  const starts = [0];
  for (let index = 0; index < text.length; index++) if (text[index] === "\n") starts.push(index + 1);
  return starts;
}

/** ABAP source parsed on its own. Offsets are into `text`. */
export class SourceAst {
  readonly text: string;
  readonly statements: readonly Nodes.StatementNode[];
  private readonly starts: number[];
  // The parsed text can be the text behind a prefix that makes it parse, see
  // expressionAst; offsets leave the prefix out.
  private readonly shift: number;
  private entries: TokenEntry[] | undefined;
  private byStart: Map<number, TokenEntry> | undefined;

  constructor(text: string, statements: readonly Nodes.StatementNode[], parsed: string, shift: number) {
    this.text = text;
    this.statements = statements;
    this.starts = lineStarts(parsed);
    this.shift = shift;
  }

  offset(token: Token): number {
    const start = token.getStart();
    return this.starts[start.getRow() - 1] + start.getCol() - 1 - this.shift;
  }

  start(node: AstNode): number {
    return this.offset(node.getFirstToken());
  }

  end(node: AstNode): number {
    const last = node.getLastToken();
    return this.offset(last) + last.getStr().length;
  }

  /** The text a node spans, as written. */
  source(node: AstNode): string {
    return this.text.slice(this.start(node), this.end(node));
  }

  /** Every token of the text in order, with the node holding it. */
  tokens(): TokenEntry[] {
    if (this.entries) return this.entries;
    const entries: TokenEntry[] = [];
    for (const statement of this.statements) {
      const visit = (node: Nodes.StatementNode | Nodes.ExpressionNode, ancestors: (Nodes.StatementNode | Nodes.ExpressionNode)[]) => {
        for (const child of node.getChildren()) {
          if (child instanceof Nodes.TokenNode) {
            const token = child.getFirstToken();
            const start = this.offset(token);
            // A probe's own tokens lie outside the text.
            if (start < 0 || start >= this.text.length) continue;
            entries.push({ token, node: child, parent: node, ancestors, statement, start, end: start + token.getStr().length });
          } else {
            visit(child, [...ancestors, child]);
          }
        }
      };
      visit(statement, [statement]);
    }
    // The statements of a chain share the tokens before its colon.
    const seen = new Set<number>();
    this.entries = entries.sort((left, right) => left.start - right.start)
      .filter((entry) => !seen.has(entry.start) && Boolean(seen.add(entry.start)));
    return this.entries;
  }

  /**
   * A node's own words: its tokens in upper case and each expression under it
   * as `_`, spaced as written, without a statement's terminator. The skeleton
   * of `AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.` is
   * `AT SELECTION-SCREEN ON VALUE-REQUEST FOR _`, whatever the operand says.
   */
  skeleton(node: Nodes.StatementNode | Nodes.ExpressionNode): string {
    let result = "";
    let previousEnd: number | undefined;
    const children = node.getChildren();
    for (const [index, child] of children.entries()) {
      const isToken = child instanceof Nodes.TokenNode;
      if (isToken && index === children.length - 1 && node instanceof Nodes.StatementNode && /^[.,]$/.test(child.getFirstToken().getStr())) break;
      const start = this.start(child);
      if (start < 0) continue;
      const piece = isToken ? child.getFirstToken().getUpperStr() : "_";
      result += (previousEnd === undefined || start === previousEnd ? "" : " ") + piece;
      previousEnd = this.end(child);
    }
    return result;
  }

  // Where a keyword phrase, such as "USER-COMMAND" or "MEMORY ID", stands among
  // the direct children of a node; names never match, only keywords.
  private phraseAt(phrase: string, node: Nodes.StatementNode | Nodes.ExpressionNode, from = 0): number {
    const words = phrase.toUpperCase().split(/( |-)/).filter((word) => word.trim());
    const children = node.getChildren();
    const matches = (child: AstNode | undefined, word: string) => child instanceof Nodes.TokenNode
      && !(child instanceof Nodes.TokenNodeRegex) && child.getFirstToken().getUpperStr() === word;
    for (let index = from; index + words.length <= children.length; index++) {
      if (words.every((word, offset) => matches(children[index + offset], word))) return index;
    }
    return -1;
  }

  /** Whether the keyword phrase is one of a node's own, outside its operands. */
  has(phrase: string, node: Nodes.StatementNode | Nodes.ExpressionNode): boolean {
    return this.phraseAt(phrase, node) >= 0;
  }

  /** The direct child after a keyword phrase: the operand of an addition. */
  after(phrase: string, node: Nodes.StatementNode | Nodes.ExpressionNode): Nodes.ExpressionNode | Nodes.TokenNode | undefined {
    const index = this.phraseAt(phrase, node);
    if (index < 0) return undefined;
    const words = phrase.split(/( |-)/).filter((word) => word.trim()).length;
    const children = node.getChildren();
    const operand = children[index + words];
    // A statement's period or chain comma is no operand.
    const terminator = node instanceof Nodes.StatementNode && index + words === children.length - 1
      && operand instanceof Nodes.TokenNode && /^[.,]$/.test(operand.getFirstToken().getStr());
    return terminator ? undefined : operand;
  }

  /** The expressions after a keyword phrase, up to the next keyword: STARTING AT x y. */
  operandsAfter(phrase: string, node: Nodes.StatementNode | Nodes.ExpressionNode): Nodes.ExpressionNode[] {
    const index = this.phraseAt(phrase, node);
    if (index < 0) return [];
    const operands: Nodes.ExpressionNode[] = [];
    const children = node.getChildren();
    for (let at = index + phrase.split(/( |-)/).filter((word) => word.trim()).length; children[at] instanceof Nodes.ExpressionNode; at++) {
      operands.push(children[at] as Nodes.ExpressionNode);
    }
    return operands;
  }

  /**
   * Where a keyword phrase, such as "WITH HEADER LINE", stands among all the
   * tokens of the text: the index of its first token, or -1. Names, literals
   * and the text inside them never match.
   */
  phraseIndex(phrase: string, from = 0): number {
    const words = phrase.toUpperCase().split(" ");
    const tokens = this.tokens();
    for (let index = from; index + words.length <= tokens.length; index++) {
      if (words.every((word, offset) => isKeyword(tokens[index + offset].node) && tokens[index + offset].token.getUpperStr() === word)) return index;
    }
    return -1;
  }

  /** Whether the keyword phrase stands anywhere in the text, see phraseIndex. */
  containsPhrase(phrase: string): boolean {
    return this.phraseIndex(phrase) >= 0;
  }

  /** The text from after its first token up to its terminator, trimmed: the operands of FREE a, b. */
  body(): string {
    const tokens = this.tokens();
    if (!tokens.length) return "";
    const last = tokens.at(-1)!;
    const end = tokens.length > 1 && /^[.,]$/.test(last.token.getStr()) ? last.start : this.text.length;
    return this.text.slice(tokens[0].end, end).trim();
  }

  /** The token starting at an offset of the text. */
  tokenAt(offset: number): TokenEntry | undefined {
    this.byStart ??= new Map(this.tokens().map((entry) => [entry.start, entry]));
    return this.byStart.get(offset);
  }
}

/** The syntax tree of one statement. */
export class StatementAst extends SourceAst {
  readonly node: Nodes.StatementNode;

  constructor(text: string, node: Nodes.StatementNode, parsed: string, shift: number) {
    super(text, [node], parsed, shift);
    this.node = node;
  }

  is(type: StatementType): boolean {
    return this.node.get() instanceof type;
  }

  find(type: ExpressionType): Nodes.ExpressionNode | undefined {
    return this.node.findFirstExpression(type);
  }

  /** The outermost expressions of a type: not those nested in another one. */
  findAll(type: ExpressionType): readonly Nodes.ExpressionNode[] {
    return this.node.findAllExpressions(type);
  }

  /** Every expression of a type, also those nested in another one. */
  findEvery(type: ExpressionType): readonly Nodes.ExpressionNode[] {
    return this.node.findAllExpressionsRecursive(type);
  }

  findDirect(type: ExpressionType): Nodes.ExpressionNode | undefined {
    return this.node.findDirectExpression(type);
  }

  /** The statement's own words, see SourceAst.skeleton. */
  words(): string {
    return this.skeleton(this.node);
  }

  /** The text of the first expression of a type, as written. */
  sourceOf(type: ExpressionType): string | undefined {
    const node = this.find(type);
    return node ? this.source(node) : undefined;
  }

  /** Whether the statement has the keyword phrase, see SourceAst.has. */
  hasPhrase(phrase: string): boolean {
    return this.has(phrase, this.node);
  }

  /** The operand after a keyword phrase of the statement, as written. */
  operand(phrase: string): string | undefined {
    const node = this.after(phrase, this.node);
    return node ? this.source(node) : undefined;
  }
}

/** The text with spans replaced; the spans may not overlap. */
export function spliceText(text: string, edits: { start: number; end: number; text: string }[]): string {
  let result = text;
  for (const edit of [...edits].sort((left, right) => right.start - left.start)) {
    result = `${result.slice(0, edit.start)}${edit.text}${result.slice(edit.end)}`;
  }
  return result;
}

/** A keyword of the syntax, as opposed to a name, a literal or punctuation. */
export function isKeyword(node: Nodes.TokenNode): boolean {
  return !(node instanceof Nodes.TokenNodeRegex) && /^[A-Z_]/i.test(node.getFirstToken().getStr());
}

const CACHE_LIMIT = 50_000;
// Statements and expressions recur; a whole generated class does not, and is
// parsed again rather than kept.
const CACHED_LENGTH = 4_000;
const sources = new Map<string, SourceAst | null>();

function remember<T extends SourceAst>(key: string, compute: () => T | undefined): T | undefined {
  if (key.length > CACHED_LENGTH) return compute();
  if (!sources.has(key)) {
    if (sources.size >= CACHE_LIMIT) sources.clear();
    sources.set(key, compute() ?? null);
  }
  return (sources.get(key) ?? undefined) as T | undefined;
}

function parse(text: string): readonly Nodes.StatementNode[] {
  return abapParser().parse([new MemoryFile("zggconv_probe.prog.abap", text)]).output[0]?.getStatements() ?? [];
}

// A chain element ends in its comma; on its own it is a statement ending in a
// period, which keeps every offset.
function terminated(text: string): string {
  const end = text.trimEnd();
  return end.endsWith(",") ? `${end.slice(0, -1)}.${text.slice(end.length)}` : text;
}

function parsed(statements: readonly Nodes.StatementNode[]): boolean {
  return statements.length > 0 && statements.every((statement) => !(statement.get() instanceof Unknown));
}

const parses = new Map<string, boolean>();

/**
 * Whether abaplint classifies every statement in the text, as written. Lowering
 * uses it to check that a rewrite left the statement parseable, for example
 * that a statement accepts a method call where it had a data object.
 */
export function parsesAsStatement(text: string): boolean {
  if (!parses.has(text)) {
    if (parses.size >= CACHE_LIMIT) parses.clear();
    parses.set(text, parsed(parse(text)));
  }
  return parses.get(text)!;
}

/** The statements of an ABAP text; undefined if abaplint cannot classify one. */
export function sourceAst(text: string): SourceAst | undefined {
  return remember(`S\0${text}`, () => {
    const statements = parse(terminated(text));
    return parsed(statements) ? new SourceAst(text, statements, terminated(text), 0) : undefined;
  });
}

/**
 * The text split into statements and tokens, whether or not abaplint knows
 * the statements: one it cannot classify is an Unknown statement holding its
 * tokens.
 */
export function lexedAst(text: string): SourceAst | undefined {
  return remember(`L\0${text}`, () => {
    const statements = parse(terminated(text));
    return statements.length ? new SourceAst(text, statements, terminated(text), 0) : undefined;
  });
}

/** The leading words of a statement's text, also of one abaplint does not know. */
export function leadingWords(text: string): string {
  const ast = lexedAst(text);
  const statement = ast?.statements.find((item) => !(item.get() instanceof Comment));
  return statement && ast ? ast.skeleton(statement) : "";
}

/** The syntax tree of a text holding exactly one statement, or undefined. */
export function statementAst(text: string): StatementAst | undefined {
  return remember(`T\0${text}`, () => {
    const statements = parse(terminated(text)).filter((statement) => !(statement.get() instanceof Comment));
    return statements.length === 1 && parsed(statements)
      ? new StatementAst(text, statements[0], terminated(text), 0)
      : undefined;
  });
}

// The text completed to a statement by a prefix, with offsets into the text.
function probeAst(prefix: string, text: string): StatementAst | undefined {
  return remember(`${prefix}\0${text}`, () => {
    const probe = `${prefix}${text}.`;
    const statements = parse(probe);
    return statements.length === 1 && parsed(statements)
      ? new StatementAst(text, statements[0], probe, prefix.length)
      : undefined;
  });
}

/**
 * The syntax tree of an expression, such as an operand cut from a statement,
 * parsed as the source of an assignment. Its offsets are into the expression.
 */
export function expressionAst(text: string): StatementAst | undefined {
  return probeAst("ggconv_probe = ", text);
}

/** The syntax tree of a type, such as `REF TO zcl_foo`, parsed as a TYPES. */
export function typeAst(text: string): StatementAst | undefined {
  return probeAst("TYPES ggconv_probe TYPE ", text);
}

/**
 * The syntax tree of ABAP code the converter holds as text: statements, an
 * expression, or a type. Undefined if it is none of these.
 */
export function fragmentAst(text: string): SourceAst | undefined {
  return sourceAst(text) ?? expressionAst(text) ?? typeAst(text);
}
