import {spawnSync} from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

// Builds a copy of src, framework and examples that installs into a real SAP
// system. The SAP-named classes, interfaces and DDIC objects in src clash with
// the system's own, so abaplint renames them (the "rename" patterns in
// abaplint.jsonc) together with every reference to them. The type pools and
// the function group stay SAP's: they move to deps/, outside abapGit's starting
// folder, where the output's abaplint.jsonc finds them as a dependency. The output
// folder is an abapGit repository with everything under src/ (src/ as
// src/standard/, framework/ as src/framework/, examples/ as src/examples/) and
// a package per folder: push it to a branch and pull it into a local package.
// Its .abapgit.xml and abaplint.jsonc are checked in; the script writes only
// src/, deps/ and assets/, including the package and object XML files abapGit needs.

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const config = JSON.parse(fs.readFileSync(path.join(repository, "abaplint.jsonc"), "utf8"));
const output = path.join(repository, config.rename.output);
// Repository folder -> folder in the copy.
const layout = [
  {from: "src", to: "src/standard"},
  {from: "framework", to: "src/framework"},
  {from: "examples", to: "src/examples"},
];

// SAP already ships these under the same names, and nothing in them refers to
// a renamed object. The tables keep their names because examples declare work
// areas for them with TABLES, which are named after the table. Each moves from
// src/standard/ to deps/.
const sapOwned = [
  "src/standard/ddic/pools",
  "src/standard/fugr",
  "src/standard/ddic/sscrfields.tabl.xml",
  "src/standard/ddic/varid.tabl.xml",
  "src/standard/ddic/varit.tabl.xml",
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
    fs.writeFileSync(path.join(folder, "package.devc.xml"), `\uFEFF<?xml version="1.0" encoding="utf-8"?>
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

// abapGit reads an object's properties from its XML file, which most classes
// and every interface in the repository go without: abaplint needs only the
// source. Each one missing gets the minimal file abapGit itself writes.
function abapGitXml(serializer, body) {
  return `\uFEFF<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="${serializer}" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
${body}
  </asx:values>
 </asx:abap>
</abapGit>
`;
}

function writeObjectXml() {
  let written = 0;
  for (const folder of folders(path.join(output, "src"))) {
    for (const file of fs.readdirSync(folder)) {
      const match = /^([^.]+)\.(clas|intf)\.abap$/.exec(file);
      if (match === null) {
        continue;
      }
      const [, name, type] = match;
      const xml = path.join(folder, `${name}.${type}.xml`);
      if (fs.existsSync(xml)) {
        continue;
      }
      const upper = name.replaceAll("#", "/").toUpperCase();
      if (type === "intf") {
        fs.writeFileSync(xml, abapGitXml("LCL_OBJECT_INTF", `   <VSEOINTERF>
    <CLSNAME>${upper}</CLSNAME>
    <LANGU>E</LANGU>
    <DESCRIPT>${upper}</DESCRIPT>
    <EXPOSURE>2</EXPOSURE>
    <STATE>1</STATE>
    <UNICODE>X</UNICODE>
   </VSEOINTERF>`), "utf8");
      } else {
        // Every exception class is named CX_ or ZCX_, see the rename patterns.
        const category = /^z?cx_/.test(name) ? "\n    <CATEGORY>40</CATEGORY>" : "";
        const tests = fs.existsSync(path.join(folder, `${name}.clas.testclasses.abap`))
          ? "\n    <WITH_UNIT_TESTS>X</WITH_UNIT_TESTS>" : "";
        fs.writeFileSync(xml, abapGitXml("LCL_OBJECT_CLAS", `   <VSEOCLASS>
    <CLSNAME>${upper}</CLSNAME>
    <LANGU>E</LANGU>
    <DESCRIPT>${upper}</DESCRIPT>${category}
    <STATE>1</STATE>
    <CLSCCINCL>X</CLSCCINCL>
    <FIXPT>X</FIXPT>
    <UNICODE>X</UNICODE>${tests}
   </VSEOCLASS>`), "utf8");
      }
      written += 1;
    }
  }
  return written;
}

// Rename inline inside a copy laid out as the output: the repository stays
// untouched, and framework/ is already in src/framework/. abaplint takes its
// base folder from the config's location. Only the generated folders are
// cleared: .abapgit.xml and abaplint.jsonc in the output are checked in.
for (const folder of ["src", "deps", ...outsideSrc.map(f => f.to)]) {
  fs.rmSync(path.join(output, folder), {recursive: true, force: true});
}
for (const folder of layout) {
  fs.cpSync(path.join(repository, folder.from), path.join(output, folder.to), {recursive: true});
}
config.global.files = ["/src/**/*.*"];
config.rename.output = "";
// allowed_object_naming catches names SAP rejects: too long, or a table with
// an underscore in its second or third character. Each rule keeps its settings
// from abaplint.jsonc, such as the examples it excludes.
config.rules = Object.fromEntries(
  ["parser_error", "check_syntax", "unknown_types", "allowed_object_naming"]
    .map(rule => [rule, config.rules[rule] ?? true]));
fs.writeFileSync(configPath, JSON.stringify(config, null, 2), "utf8");

let status = 1;
try {
  // abaplint applies the renames only when it finds no issues.
  const rename = runAbaplint(["--rename"]);
  if (rename.status !== 0 || !rename.stdout.includes("Renames applied")) {
    console.error("build:sap: abaplint did not apply the renames");
  } else {
    // The renamed copy must still compile, and its new names must be ones SAP
    // accepts.
    console.log("build:sap: checking the renamed copy");
    status = runAbaplint([]).status;
  }
} finally {
  fs.rmSync(configPath, {force: true});
}

if (status === 0) {
  for (const relative of sapOwned) {
    const target = path.join(output, "deps", path.relative("src/standard", relative));
    fs.mkdirSync(path.dirname(target), {recursive: true});
    fs.renameSync(path.join(output, relative), target);
  }
  for (const folder of outsideSrc) {
    fs.renameSync(path.join(output, folder.from), path.join(output, folder.to));
  }
  writePackages();
  console.log(`build:sap: wrote ${writeObjectXml()} missing class and interface XML files`);

  console.log(`build:sap: wrote ${path.relative(repository, output)}`);
}

process.exitCode = status;
