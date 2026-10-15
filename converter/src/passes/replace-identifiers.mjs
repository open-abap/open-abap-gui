import { keywordOffsets } from "../parser.mjs";

// The converter renames report data in carried-over statements: a global that
// moved to the owner class, a reserved name, a selection parameter's member.
// Only a reference to the data object may change. The same spelling is also a
// component (`ls_row-value`, `get( )-value`), an attribute or method (`->name`,
// `=>name`, `~name`), a field symbol (`<value>`), a table key or a constructor
// component (`itab[ name = ... ]`, `VALUE #( name = ... )`), a formal parameter
// (`EXPORTING name = ...`) or a column, and renaming one of those either breaks
// the statement or changes what it means.

// A copy of the text, character for character, in which only code is left:
// literals, the text of templates and comments are blanked, so an offset found
// in it holds in the original text.
export function maskedCode(text) {
  let output = "";
  // what encloses the current character: a template, or an expression inside one
  const stack = [];
  const blank = (value) => value.replace(/[^\n]/g, " ");
  for (let index = 0; index < text.length; index++) {
    const char = text[index];
    if (stack.at(-1) === "|") {
      if (char === "\\" && index + 1 < text.length) {
        output += blank(text.slice(index, index + 2));
        index++;
      } else {
        if (char === "{") stack.push("{");
        else if (char === "|") stack.pop();
        output += blank(char);
      }
      continue;
    }
    if (char === "'" || char === "`") {
      let end = index + 1;
      while (end < text.length && !(text[end] === char && text[end + 1] !== char)) end += text[end] === char ? 2 : 1;
      end = Math.min(end, text.length - 1);
      output += blank(text.slice(index, end + 1));
      index = end;
    } else if (char === "|") {
      stack.push("|");
      output += " ";
    } else if (char === "}" && stack.at(-1) === "{") {
      stack.pop();
      output += " ";
    } else if (char === "\"" || (char === "*" && (index === 0 || text[index - 1] === "\n"))) {
      const newline = text.indexOf("\n", index);
      const end = newline < 0 ? text.length : newline;
      output += " ".repeat(end - index);
      index = end - 1;
    } else output += char;
  }
  return output;
}

// Keywords after which `name =` compares a data object instead of binding a
// name, and the built-in functions that take a logical expression.
const LOGICAL_KEYWORDS = new Set(["IF", "ELSEIF", "WHILE", "WHEN", "AND", "OR", "NOT", "EQUIV", "CHECK", "UNTIL", "ASSERT"]);
const PREDICATE_FUNCTIONS = new Set(["XSDBOOL", "BOOLC", "BOOLX"]);
const FORMAL_SECTIONS = new Set(["EXPORTING", "IMPORTING", "CHANGING", "TABLES", "EXCEPTIONS", "RECEIVING"]);
// Where a list of components or columns (SORT ... BY, COMPARING,
// TRANSPORTING, the SELECT list) ends.
const LIST_ENDS = new Set(["WHERE", "INTO", "APPENDING", "ASSIGNING", "REFERENCE", "FROM", "INDEX", "USING", "WITH", "UP", "HAVING", "ORDER", "GROUP", "CASTING", "FOR", "BYPASSING", "CLIENT", "CONNECTION"]);
const COMPARISON = /^\s*(?:=(?![=>])|<>|<=|>=|<(?![>=])|>(?!=)|(?:EQ|NE|LT|GT|LE|GE|IN|IS|BETWEEN|CP|NP|CO|CN|CA|NA|CS|NS|LIKE)\b)/i;

// Offsets in masked code at which an identifier is a name rather than a
// reference to a data object.
export function nameOffsets(code) {
  const names = new Set();
  const statement = /^\s*([A-Z][A-Z0-9_]*)/i.exec(code)?.[1]?.toUpperCase();
  const stack = [{ kind: "top", where: false, formal: false, key: false, list: statement === "SELECT" }];
  let previous = "";
  let tableName = false;
  for (const match of code.matchAll(/[A-Z_][A-Z0-9_]*|->|=>|\S/gi)) {
    const token = match[0];
    const upper = token.toUpperCase();
    const start = match.index;
    const end = start + token.length;
    const frame = stack.at(-1);
    if (token === "(") {
      // `meth( a = 1 )`, `VALUE #( a = 1 )`; a row of VALUE #( ( a = 1 ) )
      // binds too. `IF ( a = 1 )` and xsdbool( a = 1 ) compare.
      const adjacent = start > 0 && /[A-Z0-9_#]/i.test(code[start - 1]);
      const call = adjacent
        ? !PREDICATE_FUNCTIONS.has(previous)
        : frame.kind === "call" && !LOGICAL_KEYWORDS.has(previous) && previous !== "WHERE";
      stack.push({ kind: call ? "call" : "logical", where: !call && (frame.where || previous === "WHERE"), formal: false, key: false, list: false });
    } else if (token === "[") {
      stack.push({ kind: "key", where: false, formal: false, key: false, list: false });
    } else if ((token === ")" || token === "]") && stack.length > 1) {
      stack.pop();
    } else if (/^[A-Z_]/i.test(token)) {
      if (isName(code, start, end, frame, previous)) names.add(start);
      if (tableName) {
        names.add(start);
        tableName = false;
      }
      if (upper === "WHERE") frame.where = true;
      if (FORMAL_SECTIONS.has(upper)) frame.formal = true;
      if (upper === "KEY" || upper === "COMPONENTS") frame.key = true;
      if (frame.kind === "top") {
        if (LIST_ENDS.has(upper)) frame.list = false;
        if (upper === "COMPARING" || upper === "TRANSPORTING") frame.list = true;
        if (upper === "BY" && (statement === "SORT" || statement === "SELECT")) frame.list = true;
        if (upper === "FIELDS" && statement === "SELECT") frame.list = true;
        if (["INTO", "ASSIGNING", "REFERENCE", "TRANSPORTING", "BINARY"].includes(upper)) frame.key = false;
        if (statement === "SELECT" && (upper === "FROM" || upper === "JOIN")) tableName = true;
      }
    }
    previous = upper;
  }
  return names;
}

// The offset just past a component path such as `-sub-field`.
function pathEnd(code, end) {
  const match = /^(?:-[A-Z_][A-Z0-9_]*)*/i.exec(code.slice(end));
  return end + match[0].length;
}

function isName(code, start, end, frame, previous) {
  const before = code[start - 1] ?? "";
  if (before === "-" && /[A-Z0-9_)\]>]/i.test(code[start - 2] ?? "")) return true;
  if (/->|=>/.test(code.slice(Math.max(0, start - 2), start)) || before === "~" || code[end] === "~") return true;
  if (before === "<" && code[end] === ">") return true;
  if (frame.list) return true;
  const rest = code.slice(end);
  const binds = /^\s*=(?![=>])/.test(rest);
  if (frame.kind === "key" && binds) return true;
  if (frame.where && COMPARISON.test(code.slice(pathEnd(code, end)))
    && (previous === "WHERE" || previous === "AND" || previous === "OR" || previous === "NOT" || previous === "(")) return true;
  if (frame.kind === "call" && binds && !LOGICAL_KEYWORDS.has(previous) && !frame.where) return true;
  if (frame.kind === "top" && binds && (frame.formal || frame.key)) return true;
  return false;
}

// Applies [pattern, replacement] pairs in order, each to the result of the
// ones before, at references only. A pattern is a regular expression source
// without anchors, e.g. a name or `screen-(input|output)`, and the replacement
// may use its groups.
export function replaceIdentifiers(text, replacements) {
  let output = String(text ?? "");
  for (const [name, replacement] of replacements ?? []) {
    const pattern = new RegExp(`\\b(?:${name})\\b`, "gi");
    if (!pattern.test(output)) continue;
    const code = maskedCode(output);
    const names = nameOffsets(code);
    // A keyword spelled like the name, VALUE in VALUE #( ), is no reference either.
    const keywords = keywordOffsets(output) ?? new Set();
    pattern.lastIndex = 0;
    const whole = new RegExp(`^(?:${name})$`, "i");
    let result = "";
    let last = 0;
    for (const match of code.matchAll(pattern)) {
      if (names.has(match.index) || keywords.has(match.index)) continue;
      result += output.slice(last, match.index) + match[0].replace(whole, replacement);
      last = match.index + match[0].length;
    }
    output = result + output.slice(last);
  }
  return output;
}
