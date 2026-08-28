import assert from "node:assert/strict";
import {readdir, readFile} from "node:fs/promises";
import path from "node:path";
import {fileURLToPath} from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../src");

async function filesUnder(directory) {
  const entries = await readdir(directory, {withFileTypes: true});
  const result = [];
  for (const entry of entries) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) result.push(...await filesUnder(full));
    else if (entry.name.endsWith(".clas.abap")) result.push(full);
  }
  return result;
}

function family(file) {
  const relative = path.relative(root, file).replaceAll("\\", "/");
  if (relative.startsWith("salv/")) return "SALV";
  if (relative.startsWith("tree/")) return "TREE";
  if (relative.startsWith("graphics/")) return "GRAPHICS";
  if (relative.startsWith("dd/")) return "DOCUMENT";
  if (relative.startsWith("dragdrop/")) return "DRAGDROP";
  if (relative.startsWith("alv/")) return "ALV SUPPORT";
  if (/cl_gui_|cl_abap_browser|cl_progress_indicator/.test(relative)) return "GUI CORE";
  return "OTHER";
}

function methodKind(name, body) {
  const upperName = name.toUpperCase();
  if (/^RETURN\.?\s*$/i.test(body.trim())) return "intentional no-op";
  if (/(RENDER|HTML|DISPLAY|SHOW_DATA|SHOW_URL|REFRESH_HTML)/.test(upperName)) return "render";
  if (/(EVENT|DISPATCH|COMMAND|SELECT|FOCUS|DRAG|DROP|TIMER|REGISTER|RAISE)/.test(upperName)) return "event";
  return "model";
}

const records = [];
for (const file of (await filesUnder(root)).sort()) {
  const source = await readFile(file, "utf8");
  const classMatch = source.match(/^CLASS\s+(\S+)\s+DEFINITION\b/im);
  assert.ok(classMatch, `missing class definition: ${file}`);
  const methods = [];
  const definitions = [...source.matchAll(/^\s{4,8}(?:CLASS-)?METHODS\s+([a-z0-9_~]+)\b/gim)];
  for (const definition of definitions) {
    const name = definition[1];
    const start = source.indexOf(`METHOD ${name}.`, definition.index);
    const end = start < 0 ? -1 : source.indexOf("\n  ENDMETHOD.", start);
    const body = start < 0 || end < 0 ? "" : source.slice(start + name.length + 8, end);
    methods.push({name, kind: methodKind(name, body)});
  }
  records.push({
    className: classMatch[1],
    family: family(file),
    file: path.relative(process.cwd(), file).replaceAll("\\", "/"),
    methods,
  });
}

assert.equal(records.length, 115, "update this inventory when a GUI class is added or removed");
assert.ok(records.every((record) => record.methods.every((method) => method.kind)), "every method needs a capability kind");
const methodCount = records.reduce((count, record) => count + record.methods.length, 0);
console.log(`GUI inventory: ${records.length} classes, ${methodCount} methods classified`);
for (const record of records) {
  console.log(`| ${record.className} | ${record.family} | ${record.methods.map((method) => `${method.name}: ${method.kind}`).join(", ")} | ${record.file} |`);
}
