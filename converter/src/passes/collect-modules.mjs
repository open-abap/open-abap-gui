function moduleHeader(statement) {
  const match = /^MODULE\s+([A-Z][A-Z0-9_]*)\s+(INPUT|OUTPUT)\.?/i.exec(statement.text.trim());
  return match ? { name: match[1].toUpperCase(), direction: match[2].toUpperCase() } : undefined;
}

export function collectModules(statements) {
  const modules = [];
  let current;
  for (const statement of statements) {
    if (statement.kind === "Module") {
      const header = moduleHeader(statement);
      current = header ? { ...header, statements: [], statement } : undefined;
      if (current) modules.push(current);
      continue;
    }
    if (statement.kind === "EndModule") {
      current = undefined;
      continue;
    }
    if (current) current.statements.push(statement);
  }
  return modules;
}
