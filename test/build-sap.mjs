import {spawnSync} from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

// Builds a copy of src and framework that installs into a real SAP system.
// The SAP-named classes, interfaces and DDIC objects in src clash with the
// system's own, so abaplint renames them (the "rename" patterns in
// abaplint.jsonc) together with every reference to them. The type pools and
// the function group stay SAP's: they are dropped from the copy. The output
// folder is an abapGit repository with everything under src/, framework/ as
// src/framework/, and a package per folder: push it to a branch and pull it
// into a local package.

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const config = JSON.parse(fs.readFileSync(path.join(repository, "abaplint.jsonc"), "utf8"));
const output = path.join(repository, config.rename.output);
// Repository folder -> folder in the copy.
const layout = [
  {from: "src", to: "src"},
  {from: "framework", to: "src/framework"},
];

// SAP already ships these under the same names, and nothing in them refers to
// a renamed object.
const sapOwned = [
  "src/ddic/pools",
  "src/dd/sdydo.type.abap",
  "src/fugr",
];

// Not ABAP objects. They stay in the repository but outside abapGit's starting
// folder, so they create no package: the icon notices must travel with the
// icons that zcl_gg_host_icons embeds.
const outsideSrc = [
  {from: "src/framework/assets", to: "assets"},
];

const configPath = path.join(output, ".abaplint-sap.json");

function runAbaplint(extraArgs) {
  const result = spawnSync("npx", ["abaplint", path.basename(configPath), ...extraArgs], {
    cwd: output,
    stdio: ["ignore", "pipe", "inherit"],
    shell: true,
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });
  const summary = result.stdout.split("\n").filter(line => line.trim() !== "" && !/^(rm|write|update|Renaming|Clone:) /.test(line));
  console.log(summary.join("\n"));
  return {status: result.status ?? 1, stdout: result.stdout};
}

function walk(folder) {
  return fs.readdirSync(folder, {withFileTypes: true}).flatMap(entry => {
    const full = path.join(folder, entry.name);
    return entry.isDirectory() ? walk(full) : [full];
  });
}

// Same matching as abaplint's rename: the first pattern whose type and name
// match wins.
function renamedName(type, name) {
  for (const pattern of config.rename.patterns) {
    if (!type.match(pattern.type)) {
      continue;
    }
    const regex = new RegExp(pattern.oldName, "i");
    if (regex.test(name)) {
      return name.replace(regex, pattern.newName);
    }
  }
  return undefined;
}

// Old name -> new name, upper case, for every object the patterns rename.
function renamedObjects() {
  const renamed = new Map();
  for (const file of layout.flatMap(folder => walk(path.join(repository, folder.from)))) {
    const match = /^([a-z0-9_]+)\.(clas|intf|tabl|ttyp|dtel)\.(abap|xml)$/.exec(path.basename(file));
    const newName = match && renamedName(match[2].toUpperCase(), match[1]);
    if (newName) {
      renamed.set(match[1].toUpperCase(), newName.toUpperCase());
    }
  }
  return renamed;
}

// Where a DDIC object names another object.
const ddicReference = /<(ROLLNAME|ROWTYPE|REFTYPE|PRECFIELD|DOMNAME|CHECKTABLE)>([A-Z0-9_]+)<\/\1>/g;

// The syntax check alone misses a stale reference when a dependency defines an
// object of the old name (open-abap-core has lvc_fname, for one), so look for
// the old names in DDIC references and where ABAP can only mean a type, class
// or interface. Several old DDIC names (program, file_table) are also common
// variable names, so a plain word search is too noisy.
function staleReferences(renamed) {
  const names = [...renamed.keys()].join("|");
  const inAbap = [
    String.raw`\b(${names})\s*(=>|~)`,
    String.raw`\b(TYPE|REF\s+TO|TABLE\s+OF|RANGE\s+OF|LINE\s+OF|INHERITING\s+FROM|INTERFACES|INTERFACE|CLASS|NEW|CAST|VALUE|CONV|REF|CORRESPONDING)\s+(${names})(?![\w-])`,
    String.raw`\b(RAISING|FRIENDS)\s+([\w\s]*\s)?(${names})(?![\w-])`,
  ].map(source => new RegExp(source, "i"));
  const inDdic = new RegExp(String.raw`^(${names})$`, "i");
  const hits = [];
  for (const file of walk(output)) {
    const lines = fs.readFileSync(file, "utf8").split("\n");
    lines.forEach((line, index) => {
      let stale = false;
      if (file.endsWith(".abap")) {
        const code = line.startsWith("*") ? "" : line.replace(/".*$/, "").replace(/'[^']*'|`[^`]*`|\|[^|]*\|/g, "");
        stale = inAbap.some(regex => regex.test(code));
      } else if (/\.(tabl|ttyp|dtel)\.xml$/.test(file)) {
        stale = [...line.matchAll(ddicReference)].some(match => inDdic.test(match[2]));
      }
      if (stale) {
        hits.push(`${path.relative(output, file)}:${index + 1}: ${line.trim()}`);
      }
    });
  }
  return hits;
}

function folders(folder) {
  return [folder, ...fs.readdirSync(folder, {withFileTypes: true})
    .filter(entry => entry.isDirectory())
    .flatMap(entry => folders(path.join(folder, entry.name)))];
}

// abapGit creates a package for every folder; with PREFIX folder logic its name
// is the parent's plus the folder name, so only the description is needed.
function writePackages() {
  for (const folder of folders(path.join(output, "src"))) {
    const relative = path.relative(output, folder).split(path.sep).join("/");
    fs.writeFileSync(path.join(folder, "package.devc.xml"), `<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="LCL_OBJECT_DEVC" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
   <DEVC>
    <CTEXT>open-abap-gui ${relative}</CTEXT>
   </DEVC>
  </asx:values>
 </asx:abap>
</abapGit>
`, "utf8");
  }
}

function tooLongNames() {
  return walk(output)
    .map(file => path.basename(file).replace(/\..*$/, ""))
    .filter((name, index, all) => name.length > 30 && all.indexOf(name) === index);
}

// Rename inline inside a copy laid out as the output: the repository stays
// untouched, and framework/ is already in src/framework/. abaplint takes its
// base folder from the config's location.
fs.rmSync(output, {recursive: true, force: true});
for (const folder of layout) {
  fs.cpSync(path.join(repository, folder.from), path.join(output, folder.to), {recursive: true});
}
config.global.files = ["/src/**/*.*"];
config.rename.output = "";
config.rules = {
  parser_error: true,
  check_syntax: true,
  unknown_types: true,
};
fs.writeFileSync(configPath, JSON.stringify(config, null, 2), "utf8");

let status = 1;
try {
  // abaplint applies the renames only when it finds no issues.
  const rename = runAbaplint(["--rename"]);
  if (rename.status !== 0 || !rename.stdout.includes("Renames applied")) {
    console.error("build:sap: abaplint did not apply the renames");
  } else {
    // The renamed copy must still compile on its own: a reference the rename
    // missed now points at an object that no longer exists.
    console.log("build:sap: checking the renamed copy");
    status = runAbaplint([]).status;
    const stale = staleReferences(renamedObjects());
    if (stale.length > 0) {
      console.error(`build:sap: references to old names remain:\n${stale.join("\n")}`);
      status = 1;
    }
    const long = tooLongNames();
    if (long.length > 0) {
      console.error(`build:sap: names longer than 30 characters: ${long.join(", ")}`);
      status = 1;
    }
  }
} finally {
  fs.rmSync(configPath, {force: true});
}

if (status === 0) {
  for (const relative of sapOwned) {
    fs.rmSync(path.join(output, relative), {recursive: true, force: true});
  }
  for (const folder of outsideSrc) {
    fs.renameSync(path.join(output, folder.from), path.join(output, folder.to));
  }
  writePackages();

  // PREFIX keeps the subpackages under the root package's name, so folder
  // names such as salv or tree never collide with SAP's own packages.
  fs.writeFileSync(path.join(output, ".abapgit.xml"), `<?xml version="1.0" encoding="utf-8"?>
<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
 <asx:values>
  <DATA>
   <MASTER_LANGUAGE>E</MASTER_LANGUAGE>
   <STARTING_FOLDER>/src/</STARTING_FOLDER>
   <FOLDER_LOGIC>PREFIX</FOLDER_LOGIC>
   <IGNORE>
    <item>/.gitignore</item>
    <item>/LICENSE</item>
    <item>/README.md</item>
   </IGNORE>
  </DATA>
 </asx:values>
</asx:abap>
`, "utf8");

  console.log(`build:sap: wrote ${path.relative(repository, output)}`);
}

process.exitCode = status;
