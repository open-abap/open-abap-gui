import path from "node:path";
import { Config, MemoryFile, Registry } from "@abaplint/core";
import { SyntaxLogic } from "@abaplint/core/build/src/abap/5_syntax/syntax.js";
import { declarationInfo } from "./collect-declarations.mjs";

// An inline DATA( ) outside a FORM, method or module declares a program global,
// just like a classic DATA statement. The generated class has no program scope,
// so the variable is lifted to a class attribute: its type comes from the
// abaplint syntax check, and the statement is rewritten to use the attribute.

const REFERENCE_CONSTRUCTORS = new Set(["NEW", "REF", "CAST"]);
const TYPED_CONSTRUCTORS = new Set(["VALUE", "CONV", "CORRESPONDING", "EXACT", "REDUCE", "FILTER", "COND", "SWITCH", ...REFERENCE_CONSTRUCTORS]);

function includeXML(filename) {
  const name = path.basename(filename).replace(/\.prog\.abap$/i, "").toUpperCase();
  return `<?xml version="1.0" encoding="utf-8"?><abapGit version="v1.0.0" serializer="LCL_OBJECT_PROG" serializer_version="v1.0.0"><asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0"><asx:values><PROGDIR><NAME>${name}</NAME><SUBC>I</SUBC></PROGDIR></asx:values></asx:abap></abapGit>`;
}

// Unknown global types are void instead of errors, as the converter runs
// without the DDIC and the other repository objects the report uses.
function syntaxConfig(config) {
  const raw = config.get();
  return new Config(JSON.stringify({ ...raw, syntax: { ...raw.syntax, errorNamespace: "^$" } }));
}

function programVariables(units, config) {
  const root = units[0];
  if (!root || !/\.prog\.abap$/i.test(root.filename)) return [];
  const registry = new Registry(syntaxConfig(config));
  for (const [index, unit] of units.entries()) {
    registry.addFile(new MemoryFile(unit.filename, unit.source));
    if (index > 0) registry.addFile(new MemoryFile(unit.filename.replace(/\.abap$/i, ".xml"), includeXML(unit.filename)));
  }
  registry.parse();
  const program = registry.getObject("PROG", path.basename(root.filename).replace(/\.prog\.abap$/i, "").toUpperCase());
  if (!program) return [];
  const scope = new SyntaxLogic(registry, program).run().spaghetti.getTop().getFirstChild()?.getFirstChild();
  if (scope?.getIdentifier().stype !== "_program") return [];
  return Object.entries(scope.getData().vars)
    .filter(([, variable]) => variable.getMeta().includes("inline"))
    .map(([name, variable]) => ({ name, variable }));
}

// The explicit type of the constructor expression assigned to the inline
// declaration, e.g. VALUE ty_rows( ) or NEW zcl_worker( ).
function constructorType(text, name) {
  const match = new RegExp(`\\bDATA\\s*\\(\\s*${name}\\s*\\)\\s*=\\s*([A-Z]+)\\s+([A-Z_/][A-Z0-9_/=>-]*)\\s*\\(`, "i").exec(text);
  if (!match || !TYPED_CONSTRUCTORS.has(match[1].toUpperCase())) return undefined;
  return REFERENCE_CONSTRUCTORS.has(match[1].toUpperCase()) ? `REF TO ${match[2].toLowerCase()}` : match[2].toLowerCase();
}

// The type as ABAP source, or undefined when it cannot be written down safely.
function typeSource(variable, text, name) {
  const type = variable.getType();
  if (type.constructor.name === "VoidType") return constructorType(text, name);
  if (["UnknownType", "AnyType", "GenericObjectReferenceType"].includes(type.constructor.name)) return undefined;
  const qualified = type.getQualifiedName?.();
  if (qualified && /^[A-Z_/][A-Z0-9_/=>-]*$/i.test(qualified)) return qualified.toLowerCase();
  const abap = type.toABAP?.();
  if (!abap || /todo/i.test(abap)) return undefined;
  return abap;
}

function contains(span, row, column) {
  const afterStart = row > span.start.line || (row === span.start.line && column >= span.start.column);
  const beforeEnd = row < span.end.line || (row === span.end.line && column <= span.end.column);
  return afterStart && beforeEnd;
}

// Replaces DATA(name) with name, outside string literals and templates.
function useAttribute(text, name) {
  const pattern = new RegExp(`\\bDATA\\s*\\(\\s*(${name})\\s*\\)`, "gi");
  return text.split(/('(?:[^']|'')*'|`(?:[^`]|``)*`|\|(?:[^|\\]|\\.)*\|)/).map((part, index) => index % 2 ? part : part.replace(pattern, "$1")).join("");
}

export function liftInlineDeclarations(parsedUnits, config, globalStatements) {
  const candidates = globalStatements.filter((statement) => /\bDATA\s*\(/i.test(statement.text));
  if (!candidates.length) return [];
  let variables;
  try {
    variables = programVariables(parsedUnits, config);
  } catch {
    return [];
  }
  const declarations = [];
  for (const { name, variable } of variables) {
    const row = variable.getStart().getRow();
    const column = variable.getStart().getCol();
    const statement = candidates.find((item) => item.filename === variable.getFilename() && contains(item.span, row, column));
    if (!statement) continue;
    const type = typeSource(variable, statement.text, name);
    if (!type) continue;
    statement.text = useAttribute(statement.text, name);
    const raw = `DATA ${name.toLowerCase()} TYPE ${type}.`;
    declarations.push({ ...declarationInfo({ kind: "Data", text: raw }), statement, inline: true });
  }
  return declarations;
}
