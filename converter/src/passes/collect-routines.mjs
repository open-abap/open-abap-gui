function parseParameters(header) {
  const body = header.replace(/^FORM\s+[A-Z][A-Z0-9_]*\s*/i, "").replace(/\.$/, "");
  const result = [];
  for (const match of body.matchAll(/\b(USING|CHANGING|TABLES)\s+(.+?)(?=\s+(?:USING|CHANGING|TABLES)\s+|$)/gi)) {
    const direction = match[1].toUpperCase() === "USING" ? "IMPORTING" : "CHANGING";
    const section = match[2].trim();
    const typed = [...section.matchAll(/([A-Z][A-Z0-9_]*)\s+(?:TYPE|LIKE)\s+(REF\s+TO\s+[A-Z0-9_\/]+|[A-Z0-9_\/]+(?:\s+LENGTH\s+\d+)?(?:\s+DECIMALS\s+\d+)?)/gi)];
    if (typed.length) {
      for (const item of typed) result.push({ name: item[1].toLowerCase(), direction, type: item[2].toLowerCase() });
    } else {
      for (const name of section.split(/[\s,]+/).filter(Boolean)) {
        if (/^[A-Z][A-Z0-9_]*$/i.test(name)) result.push({ name: name.toLowerCase(), direction, type: "string" });
      }
    }
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
