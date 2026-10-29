import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn } from "node:child_process";

export const testRoot = path.dirname(fileURLToPath(import.meta.url));
export const converterRoot = path.resolve(testRoot, "..");
export const repositoryRoot = path.resolve(converterRoot, "..");
export const examplesFolder = path.join(repositoryRoot, "examples");

// The .prog.abap files of the repository's example programs, sorted. An
// include (SUBC I) is no program of its own; its program converts it.
export async function examplePrograms() {
  const names = [];
  for (const name of (await fs.readdir(examplesFolder)).filter((item) => item.endsWith(".prog.abap")).sort()) {
    const xml = await fs.readFile(path.join(examplesFolder, name.replace(/\.prog\.abap$/, ".prog.xml")), "utf8").catch(() => "");
    if (!/<SUBC>\s*I\s*<\/SUBC>/i.test(xml)) names.push(name);
  }
  return names;
}

export function isMain(url) {
  return Boolean(process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === url);
}

export function runNode(args, {cwd = repositoryRoot} = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, args, {cwd, stdio: "inherit"});
    child.once("error", reject);
    child.once("close", (code, signal) => {
      if (signal) reject(new Error(`${args[0]} terminated by ${signal}`));
      else if (code !== 0) reject(new Error(`${args[0]} exited with code ${code}`));
      else resolve();
    });
  });
}

export function repositoryTool(name) {
  const suffix = process.platform === "win32" ? ".cmd" : "";
  return path.join(repositoryRoot, "node_modules", ".bin", `${name}${suffix}`);
}
