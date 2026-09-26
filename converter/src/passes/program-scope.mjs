import fs from "node:fs";
import path from "node:path";
import { Config, MemoryFile, Registry } from "@abaplint/core";
import { SyntaxLogic } from "@abaplint/core/build/src/abap/5_syntax/syntax.js";

// The abaplint syntax check of the report, run once per conversion and shared
// by the passes that need resolved types. Dictionary objects serialized by
// abapGit (data elements, domains, structures, table types) are added when the
// report refers to them, so a data element resolves to its built-in type.

const DICTIONARY_FILE = /^(.+)\.(dtel|doma|tabl|ttyp)\.xml$/i;
// The XML elements through which one dictionary object names another.
const DICTIONARY_REFERENCE = /<(?:ROLLNAME|DOMNAME|ROWTYPE|PRECFIELD|REFNAME)>([^<]+)</g;

const indexes = new WeakMap();

function includeXML(filename) {
  const name = path.basename(filename).replace(/\.prog\.abap$/i, "").toUpperCase();
  return `<?xml version="1.0" encoding="utf-8"?><abapGit version="v1.0.0" serializer="LCL_OBJECT_PROG" serializer_version="v1.0.0"><asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0"><asx:values><PROGDIR><NAME>${name}</NAME><SUBC>I</SUBC></PROGDIR></asx:values></asx:abap></abapGit>`;
}

// Unknown global types are void instead of errors, as the converter runs
// without most of the repository objects the report uses.
function syntaxConfig(config) {
  const raw = config.get();
  return new Config(JSON.stringify({ ...raw, syntax: { ...raw.syntax, errorNamespace: "^$" } }));
}

/**
 * Index dictionary files by object name. Accepts file names or
 * `{ filename, source }` entries; anything that is not a dictionary object is
 * ignored. The index of a given array is built once, and a file is read only
 * when a report refers to it, so a batch shares both across its programs.
 */
export function dictionaryIndex(files) {
  if (!files || typeof files !== "object") return new Map();
  if (indexes.has(files)) return indexes.get(files);
  const index = new Map();
  for (const file of files) {
    const entry = typeof file === "string" ? { filename: file } : { ...file };
    const basename = path.basename(String(entry.filename ?? ""));
    const match = DICTIONARY_FILE.exec(basename);
    if (!match) continue;
    // abapGit writes a namespace /ABC/ as #abc#.
    const name = match[1].replaceAll("#", "/").toUpperCase();
    if (!index.has(name)) index.set(name, []);
    index.get(name).push({ ...entry, basename: basename.toLowerCase() });
  }
  indexes.set(files, index);
  return index;
}

function entrySource(entry) {
  if (entry.source === undefined) {
    try {
      entry.source = fs.readFileSync(entry.filename, "utf8");
    } catch {
      entry.source = null;
    }
  }
  return typeof entry.source === "string" ? entry.source.replace(/^\uFEFF/, "") : undefined;
}

// The dictionary objects named in the sources, and the objects those name in
// turn: a data element brings its domain, a structure its components' types.
function dictionaryClosure(index, sources) {
  if (!index.size) return [];
  const pending = [...new Set(sources.flatMap((source) => source.toUpperCase().match(/[A-Z0-9_/]+/g) ?? []))];
  const seen = new Set();
  const files = [];
  while (pending.length) {
    const name = pending.pop();
    if (seen.has(name)) continue;
    seen.add(name);
    for (const entry of index.get(name) ?? []) {
      const source = entrySource(entry);
      if (source === undefined) continue;
      files.push({ basename: entry.basename, source });
      for (const match of source.matchAll(DICTIONARY_REFERENCE)) pending.push(match[1].trim().toUpperCase());
    }
  }
  return files;
}

function buildProgramScope(units, config, dictionary) {
  const root = units[0];
  if (!root || !/\.prog\.abap$/i.test(root.filename)) return undefined;
  const registry = new Registry(syntaxConfig(config));
  for (const [index, unit] of units.entries()) {
    registry.addFile(new MemoryFile(unit.filename, unit.source));
    if (index > 0) registry.addFile(new MemoryFile(unit.filename.replace(/\.abap$/i, ".xml"), includeXML(unit.filename)));
  }
  for (const file of dictionaryClosure(dictionary, units.map((unit) => unit.source))) {
    registry.addFile(new MemoryFile(file.basename, file.source));
  }
  registry.parse();
  const program = registry.getObject("PROG", path.basename(root.filename).replace(/\.prog\.abap$/i, "").toUpperCase());
  if (!program) return undefined;
  const scope = new SyntaxLogic(registry, program).run().spaghetti.getTop().getFirstChild()?.getFirstChild();
  if (scope?.getIdentifier().stype !== "_program") return undefined;
  return { registry, scope };
}

/**
 * A getter for the report's program scope, `{ registry, scope }`, computed on
 * first use. It returns undefined when the input is not a program or the
 * syntax check cannot run, and callers then keep their unresolved defaults.
 */
export function lazyProgramScope(units, config, dictionary = new Map()) {
  let computed = false;
  let result;
  return () => {
    if (!computed) {
      computed = true;
      try {
        result = buildProgramScope(units, config, dictionary);
      } catch {
        result = undefined;
      }
    }
    return result;
  };
}
