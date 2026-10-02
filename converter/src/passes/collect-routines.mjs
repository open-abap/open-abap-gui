// Words that need a following operand inside a FORM parameter typing, and
// words that continue a typing that would otherwise be complete (TYPE any
// TABLE, TYPE c LENGTH 10). Anything else after a complete typing starts the
// next parameter.
const TYPING_OPERAND = new Set(["TYPE", "LIKE", "STRUCTURE", "REF", "TO", "LINE", "OF", "RANGE", "STANDARD", "SORTED", "HASHED", "INDEX", "LENGTH", "DECIMALS"]);
const TYPING_CONTINUATION = new Set(["TABLE", "OF", "LENGTH", "DECIMALS"]);

// An untyped FORM parameter is generic: any for USING and CHANGING, a
// standard table for TABLES. TABLES ... STRUCTURE names only the line type,
// which a method parameter cannot spell, so it is a generic standard table too.
function parameterType(section, typing) {
  if (section === "TABLES" && (!typing || /^STRUCTURE\b/i.test(typing))) return "standard table";
  if (!typing) return "any";
  return typing.replace(/^(?:TYPE|LIKE|STRUCTURE)\s+/i, "").toLowerCase();
}

function sectionParameters(section, text) {
  const tokens = text.split(/\s+/).filter(Boolean);
  const result = [];
  for (let index = 0; index < tokens.length;) {
    const name = /^(?:VALUE\(([A-Z][A-Z0-9_]*)\)|([A-Z][A-Z0-9_]*))$/i.exec(tokens[index++]);
    if (!name) continue;
    const typing = [];
    if (TYPING_OPERAND.has(tokens[index]?.toUpperCase())) {
      let needsOperand = false;
      while (index < tokens.length && (needsOperand || typing.length === 0 || TYPING_CONTINUATION.has(tokens[index].toUpperCase()))) {
        const word = tokens[index++];
        typing.push(word);
        needsOperand = TYPING_OPERAND.has(word.toUpperCase());
      }
    }
    result.push({
      name: (name[1] ?? name[2]).toLowerCase(),
      section,
      direction: section === "USING" ? "IMPORTING" : "CHANGING",
      type: parameterType(section, typing.join(" ")),
    });
  }
  return result;
}

function parseParameters(header) {
  const body = header.replace(/^FORM\s+[A-Z][A-Z0-9_]*\s*/i, "").replace(/\.$/, "");
  const result = [];
  for (const match of body.matchAll(/\b(USING|CHANGING|TABLES)\s+(.+?)(?=\s+(?:USING|CHANGING|TABLES|RAISING)\s+|\s+RAISING\b|$)/gi)) {
    result.push(...sectionParameters(match[1].toUpperCase(), match[2].trim()));
  }
  return result;
}

export function collectRoutines(ir) {
  const usedMethodNames = new Set();
  for (const routine of ir.routines) {
    const baseName = `form_${routine.name.toLowerCase()}`;
    let methodName = baseName.slice(0, 30);
    let suffix = 2;
    while (usedMethodNames.has(methodName)) {
      const marker = `_${suffix++}`;
      methodName = `${baseName.slice(0, 30 - marker.length)}${marker}`;
    }
    usedMethodNames.add(methodName);
    routine.methodName = methodName;
    routine.parameters = parseParameters(routine.statement.text);
  }
  return ir;
}
