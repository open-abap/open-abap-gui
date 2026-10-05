function moduleHeader(statement) {
  const match = /^MODULE\s+([A-Z][A-Z0-9_]*)\s+(INPUT|OUTPUT)\.?/i.exec(statement.text.trim());
  return match ? { name: match[1].toUpperCase(), direction: match[2].toUpperCase() } : undefined;
}

// The comments right before a MODULE or FORM header describe that block, not
// the end of the one before it.
export function leadingComments(statements) {
  const result = new Map();
  let pending = [];
  for (const statement of statements) {
    if (statement.kind === "Comment") {
      pending.push(statement);
      continue;
    }
    if (pending.length && (statement.kind === "Module" || statement.kind === "Form" || /^FORM\s+/i.test(statement.text))) {
      result.set(statement, pending);
    }
    pending = [];
  }
  return result;
}

export function collectModules(statements) {
  const modules = [];
  const comments = leadingComments(statements);
  let current;
  for (const statement of statements) {
    if (statement.kind === "Module") {
      const header = moduleHeader(statement);
      current = header ? { ...header, statements: [...(comments.get(statement) ?? [])], statement } : undefined;
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
