import { Expressions } from "@abaplint/core";
import { statementAst } from "../abap/ast.js";
import type { LocalClass, LocalClassMethod, ReportIR, Statement } from "../types.js";

function className(statement: Statement): string | undefined {
  return statementAst(statement.text)?.sourceOf(Expressions.ClassName)?.toUpperCase();
}

function methodName(statement: Statement): string | undefined {
  return statementAst(statement.text)?.sourceOf(Expressions.MethodName)?.toUpperCase();
}

const structuralKinds = new Set([
  "ClassDefinition", "ClassImplementation", "EndClass", "Public", "Protected", "Private",
  "MethodDef", "MethodImplementation", "EndMethod",
]);

export function isLocalClassStructural(statement: Statement): boolean {
  return Boolean(statement.localClassName && structuralKinds.has(statement.kind));
}

export function collectLocalClasses(ir: ReportIR, statements: Statement[]): LocalClass[] {
  const classes: LocalClass[] = [];
  const byName = new Map<string, LocalClass>();
  let current: LocalClass | undefined;
  let currentMethod: LocalClassMethod | undefined;

  for (const statement of statements) {
    if (statement.kind === "ClassDefinition") {
      const name = className(statement);
      if (!name) continue;
      current = byName.get(name) ?? {
        name,
        definition: [],
        methods: [],
        definitionStatement: undefined,
        implementationStatement: undefined,
      };
      current.definitionStatement = statement;
      current.definitionHeader = statement.text;
      byName.set(name, current);
      if (!classes.includes(current)) classes.push(current);
      statement.localClassName = name;
      statement.localClassPart = "definition";
      currentMethod = undefined;
      continue;
    }
    if (statement.kind === "ClassImplementation") {
      const name = className(statement);
      if (!name) continue;
      current = byName.get(name) ?? {
        name,
        definition: [],
        methods: [],
        definitionStatement: undefined,
        implementationStatement: undefined,
      };
      current.implementationStatement = statement;
      current.implementationHeader = statement.text;
      byName.set(name, current);
      if (!classes.includes(current)) classes.push(current);
      statement.localClassName = name;
      statement.localClassPart = "implementation";
      currentMethod = undefined;
      continue;
    }
    if (!current) continue;

    statement.localClassName = current.name;
    if (statement.kind === "EndClass") {
      statement.localClassPart = currentMethod ? "method-end-class" : "class-end";
      currentMethod = undefined;
      current = undefined;
      continue;
    }
    if (statement.kind === "MethodImplementation") {
      const name = methodName(statement);
      currentMethod = current.methods.find((item) => item.name === name && !item.statement);
      if (currentMethod) currentMethod.statement = statement;
      else {
        const created: LocalClassMethod = { name: name!, statement, definition: undefined, statements: [] };
        currentMethod = created;
        current.methods.push(created);
      }
      statement.localClassPart = "method";
      continue;
    }
    if (statement.kind === "EndMethod") {
      statement.localClassPart = "method-end";
      currentMethod = undefined;
      continue;
    }
    if (currentMethod) {
      statement.localClassPart = "method-body";
      if (["Data", "DataBegin", "DataEnd", "Constant", "ConstantBegin", "ConstantEnd", "Static", "StaticBegin", "StaticEnd", "FieldSymbol", "Ranges", "Type", "TypeBegin", "TypeEnd", "IncludeType"].includes(statement.kind)) {
        statement.scope = "local";
      }
      currentMethod.statements.push(statement);
    } else if (current.implementationStatement) {
      statement.localClassPart = "implementation-body";
    } else {
      statement.localClassPart = "definition-body";
      current.definition.push(statement);
      if (statement.kind === "MethodDef") {
        const name = methodName(statement);
        const method = current.methods.find((item) => item.name === name && !item.definition);
        if (method) method.definition = statement;
        else current.methods.push({ name: name!, statement: undefined, definition: statement, statements: [] });
      }
    }
  }

  ir.localClasses = classes.filter((item) => item.definitionStatement || item.implementationStatement);
  ir.localClassRenames ??= {};
  return ir.localClasses;
}
