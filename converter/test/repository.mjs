import path from "node:path";
import { fileURLToPath } from "node:url";

export const testRoot = path.dirname(fileURLToPath(import.meta.url));
export const converterRoot = path.resolve(testRoot, "..");
export const repositoryRoot = path.resolve(converterRoot, "..");

export function repositoryTool(name) {
  const suffix = process.platform === "win32" ? ".cmd" : "";
  return path.join(repositoryRoot, "node_modules", ".bin", `${name}${suffix}`);
}
