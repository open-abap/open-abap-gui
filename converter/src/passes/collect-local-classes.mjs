function className(statement) {
  return /^CLASS\s+([A-Z][A-Z0-9_]*)\s+(?:DEFINITION|IMPLEMENTATION)\b/i.exec(statement.text)?.[1]?.toUpperCase();
}

function methodName(statement) {
  return /^METHODS?\s+([^\s.]+)/i.exec(statement.text)?.[1]?.toUpperCase();
}

const structuralKinds = new Set([
  "ClassDefinition", "ClassImplementation", "EndClass", "Public", "Protected", "Private",
  "MethodDef", "MethodImplementation", "EndMethod",
]);

export function isLocalClassStructural(statement) {
  return Boolean(statement.localClassName && structuralKinds.has(statement.kind));
}

export function collectLocalClasses(ir, statements) {
  const classes = [];
  const byName = new Map();
  let current;
  let currentMethod;

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
        currentMethod = { name, statement, definition: undefined, statements: [] };
        current.methods.push(currentMethod);
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
      if (["Data", "DataBegin", "DataEnd", "Constant", "Static", "FieldSymbol", "Ranges", "Type", "TypeBegin", "TypeEnd"].includes(statement.kind)) {
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
        else current.methods.push({ name, statement: undefined, definition: statement, statements: [] });
      }
    }
  }

  ir.localClasses = classes.filter((item) => item.definitionStatement || item.implementationStatement);
  ir.localClassRenames ??= {};
  return ir.localClasses;
}
