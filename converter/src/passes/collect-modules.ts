import { Expressions } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import { isFormStart } from "../abap/statements.js";
import type { DynproModule, Statement } from "../types.js";

function moduleHeader(statement: Statement): Pick<DynproModule, "name" | "direction"> | undefined {
  const ast = statementAst(statement.text);
  const name = ast?.find(Expressions.FormName);
  const direction = ast?.words().split(" ").at(-1);
  if (!ast || !name || (direction !== "INPUT" && direction !== "OUTPUT")) return undefined;
  return { name: ast.source(name).toUpperCase(), direction };
}

// The comments right before a MODULE or FORM header describe that block, not
// the end of the one before it.
export function leadingComments(statements: Statement[]): Map<Statement, Statement[]> {
  const result = new Map<Statement, Statement[]>();
  let pending: Statement[] = [];
  for (const statement of statements) {
    if (statement.kind === "Comment") {
      pending.push(statement);
      continue;
    }
    if (pending.length && (statement.kind === "Module" || isFormStart(statement))) {
      result.set(statement, pending);
    }
    pending = [];
  }
  return result;
}

export function collectModules(statements: Statement[]): DynproModule[] {
  const modules: DynproModule[] = [];
  const comments = leadingComments(statements);
  let current: DynproModule | undefined;
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
