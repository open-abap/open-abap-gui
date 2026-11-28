import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawn } from "node:child_process";

export const testRoot = path.dirname(fileURLToPath(import.meta.url));
export const converterRoot = path.resolve(testRoot, "..");
export const repositoryRoot = path.resolve(converterRoot, "..");

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
