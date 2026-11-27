import { ABAPObject, Config, Expressions, MemoryFile, Nodes, Registry, Statements, Tokens, Unknown } from "@abaplint/core";
import type { Token } from "@abaplint/core";

// SAP rejects source lines longer than 255 characters. The repository's lint
// allows 220, which leaves room for the longer names the SAP build renames
// objects to.
export const MAX_LINE_LENGTH = 220;

const MAX_PASSES = 200;

const DECLARATIONS = [
  Statements.Data, Statements.DataBegin, Statements.Constant, Statements.ConstantBegin, Statements.Static,
  Statements.StaticBegin, Statements.ClassData, Statements.ClassDataBegin, Statements.Type, Statements.TypeBegin,
  Statements.Parameter, Statements.SelectOption,
];

// A statement's line break: the whitespace from `from` up to the token at
// `to` becomes a new line indented to `column` (0-based).
interface Edit {
  from: number;
  to: number;
  text: string;
}

// Items of one construct that go one per line, aligned below the first:
// component assignments of a VALUE body, parameters of a call, operands of
// an && chain. `equals` gives each item's "=" token, aligned too.
interface Group {
  depth: number;
  items: Token[];
  equals?: (Token | undefined)[];
  lefts?: (Token | undefined)[];
}

class Text {
  private readonly offsets: number[] = [];

  public constructor(public readonly source: string) {
    let offset = 0;
    for (const line of source.split("\n")) {
      this.offsets.push(offset);
      offset += line.length + 1;
    }
  }

  public offset(row: number, col: number): number {
    return this.offsets[row - 1] + col - 1;
  }

  public line(row: number): string {
    const start = this.offsets[row - 1];
    const end = row < this.offsets.length ? this.offsets[row] - 1 : this.source.length;
    return this.source.slice(start, end).replace(/\r$/, "");
  }
}

function isTemplate(token: Token): boolean {
  return token instanceof Tokens.StringTemplate || token instanceof Tokens.StringTemplateBegin
    || token instanceof Tokens.StringTemplateMiddle || token instanceof Tokens.StringTemplateEnd;
}

// Tokens inside the embedded expressions of a string template. ABAP does not
// break lines there.
function embedded(tokens: readonly Token[]): Set<Token> {
  const inside = new Set<Token>();
  let depth = 0;
  for (const token of tokens) {
    if (token instanceof Tokens.StringTemplateEnd) depth--;
    if (depth > 0 && !(token instanceof Tokens.StringTemplateMiddle && depth === 1)) inside.add(token);
    if (token instanceof Tokens.StringTemplateBegin) depth++;
  }
  return inside;
}

function groups(statement: Nodes.StatementNode, inside: Set<Token>, next: (token: Token) => Token | undefined): Group[] {
  const result: Group[] = [];
  const assignmentGroup = (depth: number, children: Nodes.ExpressionNode[], other: Nodes.ExpressionNode[] = []) => {
    const items = [...children, ...other].sort((a, b) => a.getFirstToken().getStart().isBefore(b.getFirstToken().getStart()) ? -1 : 1);
    if (items.length < 2 || inside.has(items[0].getFirstToken())) return;
    const equals = items.map(item => children.includes(item)
      ? item.getChildren().find(child => child instanceof Nodes.TokenNode && child.getFirstToken().getStr() === "=")?.getFirstToken()
      : undefined);
    const tokens = statement.getTokens();
    const lefts = equals.map(token => token ? tokens[tokens.indexOf(token) - 1] : undefined);
    result.push({depth, items: items.map(item => item.getFirstToken()), equals, lefts});
  };
  const chain = (source: Nodes.ExpressionNode): Token[] => {
    const children = source.getChildren();
    const index = children.findIndex(child => child instanceof Nodes.TokenNode && child.getFirstToken().getStr() === "&&");
    if (index < 0) return [];
    const tail = children[index + 1];
    return [children[index].getFirstToken(), ...(tail instanceof Nodes.ExpressionNode && tail.get() instanceof Expressions.Source ? chain(tail) : [])];
  };
  const visit = (node: Nodes.StatementNode | Nodes.ExpressionNode, depth: number, tail: boolean) => {
    if (node instanceof Nodes.ExpressionNode) {
      const type = node.get();
      const expressions = node.getChildren().filter((child): child is Nodes.ExpressionNode => child instanceof Nodes.ExpressionNode);
      if (type instanceof Expressions.ValueBody) {
        assignmentGroup(depth,
          expressions.filter(child => child.get() instanceof Expressions.FieldAssignment),
          expressions.filter(child => child.get() instanceof Expressions.ValueBodyLine));
      } else if (type instanceof Expressions.ValueBodyLine) {
        assignmentGroup(depth, expressions.filter(child => child.get() instanceof Expressions.FieldAssignment));
      } else if (type instanceof Expressions.ParameterListS) {
        assignmentGroup(depth, expressions.filter(child => child.get() instanceof Expressions.ParameterS));
      } else if (type instanceof Expressions.ParameterListT) {
        assignmentGroup(depth, expressions.filter(child => child.get() instanceof Expressions.ParameterT));
      } else if (type instanceof Expressions.ParameterListExceptions) {
        assignmentGroup(depth, expressions.filter(child => child.get() instanceof Expressions.ParameterException));
      } else if (type instanceof Expressions.Source && !tail) {
        // An && that ends its line already has its operand on the next one.
        const operators = chain(node).filter(token => !inside.has(token) && next(token)?.getRow() === token.getRow());
        if (operators.length && !inside.has(node.getFirstToken())) result.push({depth, items: [node.getFirstToken(), ...operators]});
      }
    }
    const children = node.getChildren();
    children.forEach((child, index) => {
      if (child instanceof Nodes.TokenNode) return;
      const previous = children[index - 1];
      const isTail = child.get() instanceof Expressions.Source && previous instanceof Nodes.TokenNode && previous.getFirstToken().getStr() === "&&";
      visit(child, depth + 1, isTail);
    });
  };
  visit(statement, 0, false);
  return result;
}

// Puts each item of the group on its own line, aligned to the first item and
// with the "=" of each aligned as align_parameters wants it.
function groupEdits(group: Group, text: Text, previous: (token: Token) => Token | undefined): Edit[] {
  const edits: Edit[] = [];
  const column = group.items[0].getCol() - 1;
  const rowOf = new Map<Token, number>();
  let row = group.items[0].getRow();
  group.items.forEach((item, index) => {
    if (index > 0) row++;
    rowOf.set(item, row);
  });
  // Column of "=" once each item starts its own line at `column`.
  let equalsColumn = 0;
  group.items.forEach((item, index) => {
    const left = group.lefts?.[index];
    if (!left || !group.equals?.[index] || left.getRow() !== item.getRow()) return;
    equalsColumn = Math.max(equalsColumn, column + left.getEnd().getCol() - item.getCol() + 1);
  });
  group.items.forEach((item, index) => {
    if (index > 0) {
      const before = previous(item);
      const from = before && before.getRow() === item.getRow() ? text.offset(before.getEnd().getRow(), before.getEnd().getCol()) : text.offset(item.getRow(), 1);
      edits.push({from, to: text.offset(item.getRow(), item.getCol()), text: (from === text.offset(item.getRow(), 1) ? "" : "\n") + " ".repeat(column)});
    }
    const left = group.lefts?.[index];
    const equals = group.equals?.[index];
    if (left && equals && equalsColumn && left.getRow() === item.getRow() && equals.getRow() === item.getRow()) {
      const at = column + left.getEnd().getCol() - item.getCol();
      edits.push({
        from: text.offset(left.getEnd().getRow(), left.getEnd().getCol()),
        to: text.offset(equals.getRow(), equals.getCol()),
        text: " ".repeat(Math.max(1, equalsColumn - at)),
      });
    }
  });
  return edits;
}

// Offsets inside a literal token where it can be cut in two, each relative to
// the token's start: never inside an escape, and for a text field literal
// never after a blank, which the concatenation would drop.
function cuts(token: Token): number[] {
  const value = token.getStr();
  const result: number[] = [];
  if (token instanceof Tokens.StringToken) {
    const quote = value[0];
    for (let i = 1; i < value.length - 1; i++) {
      if (value[i] === quote) {
        i++;
        continue;
      }
      if (i > 1 && !(quote === "'" && value[i - 1] === " ")) result.push(i);
    }
    return result;
  }
  // Template parts: |text{  }text{  }text|
  const start = value[0] === "|" || value[0] === "}" ? 1 : 0;
  const end = value.endsWith("{") || value.endsWith("|") ? value.length - 1 : value.length;
  const last = value.endsWith("|") ? end - 1 : end;
  for (let i = start; i <= last; i++) {
    if (value[i - 1] === "\\" && !escapedBackslash(value, i - 1)) continue;
    if (i === 1 && value[0] === "|") continue;
    result.push(i);
  }
  return result;
}

function escapedBackslash(value: string, index: number): boolean {
  let count = 0;
  for (let i = index - 1; i >= 0 && value[i] === "\\"; i--) count++;
  return count % 2 === 1;
}

// Cuts a literal of the row as close to the limit as it can into two literals
// joined by &&, the second on a new line aligned to the literal's start, or
// to the && starting the line the literal continues. A template is cut in its
// outermost text only.
function literalEdit(statement: Nodes.StatementNode, row: number, text: Text, inside: Set<Token>, limit: number,
                     previous: (token: Token) => Token | undefined): Edit | undefined {
  const declaration = DECLARATIONS.some(type => statement.get() instanceof type);
  let start: Token | undefined;
  const cutsAt: {position: number; column: number; quote: string}[] = [];
  for (const token of statement.getTokens()) {
    if (inside.has(token)) continue;
    if (token instanceof Tokens.StringTemplate || token instanceof Tokens.StringTemplateBegin || token instanceof Tokens.StringToken) start = token;
    if (token.getRow() !== row || !start) continue;
    if (!isTemplate(token) && !(token instanceof Tokens.StringToken && !declaration)) continue;
    const before = previous(start);
    const continues = before?.getStr() === "&&" && previous(before)?.getRow() !== before.getRow();
    const column = (continues ? before : start).getCol() - 1;
    const quote = token instanceof Tokens.StringToken ? token.getStr()[0] : "|";
    // The cut must leave the line within the limit and the rest shorter.
    const minimum = column + quote.length + "&& ".length + 1;
    for (const offset of cuts(token)) {
      const position = token.getCol() - 1 + offset;
      if (position > minimum && position + 1 <= limit) cutsAt.push({position, column, quote});
    }
  }
  const line = text.line(row);
  if (!cutsAt.length) return undefined;
  const last = Math.max(...cutsAt.map(cut => cut.position));
  if (last + 1 >= line.length) return undefined;
  const nice = cutsAt.filter(cut => cut.position > last - 40 && /[>;,} ]/.test(line[cut.position - 1]));
  const cut = nice.length
    ? nice.reduce((a, b) => b.position > a.position ? b : a)
    : cutsAt.find(candidate => candidate.position === last)!;
  const offset = text.offset(row, cut.position + 1);
  return {from: offset, to: offset, text: `${cut.quote}\n${" ".repeat(cut.column)}&& ${cut.quote}`};
}

function statementEdits(statement: Nodes.StatementNode, text: Text, limit: number): Edit[] {
  const tokens = statement.getTokens();
  if (!tokens.length || statement.get() instanceof Unknown) return [];
  const rows = [...new Set(tokens.map(token => token.getRow()))];
  const long = rows.filter(row => text.line(row).length > limit);
  if (!long.length) return [];
  const inside = embedded(tokens);
  const index = new Map<Token, number>(tokens.map((token, position) => [token, position]));
  const previous = (token: Token) => tokens[index.get(token)! - 1];
  const next = (token: Token) => tokens[index.get(token)! + 1];
  const all = groups(statement, inside, next);
  for (const row of long) {
    const candidates = all
      .filter(group => group.items.some(item => item.getRow() === row))
      .filter(group => group.items.slice(1).some(item => previous(item)?.getRow() === item.getRow()))
      .sort((a, b) => a.depth - b.depth);
    if (candidates.length) return groupEdits(candidates[0], text, previous);
  }
  // Each cut stays within its row, so all rows are cut in the same pass.
  return long.map(row => literalEdit(statement, row, text, inside, limit, previous)).filter((edit): edit is Edit => edit !== undefined);
}

function unknownCount(registry: Registry): number {
  const file = (registry.getFirstObject() as ABAPObject).getABAPFiles()[0];
  return file.getStatements().filter(statement => statement.get() instanceof Unknown).length;
}

/**
 * Breaks the lines of the source longer than the limit: VALUE bodies,
 * parameter lists and && chains get one item per line, and literals and
 * string templates are cut into pieces joined by &&. Lines it cannot break,
 * such as a long embedded expression, stay as they are.
 */
export function wrapLongLines(source: string, filename: string, limit = MAX_LINE_LENGTH): string {
  if (!source.split("\n").some(line => line.replace(/\r$/, "").length > limit)) return source;
  const registry = new Registry(Config.getDefault());
  registry.addFile(new MemoryFile(filename, source));
  registry.parse();
  const unknown = unknownCount(registry);
  let current = source;
  for (let pass = 0; pass < MAX_PASSES; pass++) {
    const text = new Text(current);
    const file = (registry.getFirstObject() as ABAPObject).getABAPFiles()[0];
    const edits = file.getStatements().flatMap(statement => statementEdits(statement, text, limit));
    if (!edits.length) break;
    for (const edit of edits.sort((a, b) => b.from - a.from)) {
      current = current.slice(0, edit.from) + edit.text + current.slice(edit.to);
    }
    registry.updateFile(new MemoryFile(filename, current));
    registry.parse();
  }
  // A break that leaves a statement unparsable is a bug here: keep the source.
  return unknownCount(registry) > unknown ? source : current;
}
