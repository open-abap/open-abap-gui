import { execFileSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { classNameFromFilename } from "./config.mjs";

const INCLUDE_SUFFIXES = [".prog.abap", ".incl.abap"];
const CLASS_SUFFIX = ".clas.abap";

function posix(value) {
  return String(value).replaceAll("\\", "/");
}

// Enough of glob for the lib `files` patterns abap_transpile documents
// ("/src/**", "/src/**/*.abap", "/src/{a,b}/**"); node's own fs.glob is still
// experimental on the node versions this package supports.
function globToRegExp(pattern) {
  let source = "";
  for (let index = 0; index < pattern.length; index++) {
    const char = pattern[index];
    if (char === "*" && pattern[index + 1] === "*") {
      index++;
      if (pattern[index + 1] === "/") {
        index++;
        source += "(?:.*/)?";
      } else {
        source += ".*";
      }
    } else if (char === "*") source += "[^/]*";
    else if (char === "?") source += "[^/]";
    else if (char === "{") source += "(?:";
    else if (char === "}") source += ")";
    else if (char === ",") source += "|";
    else source += char.replace(/[.+^$()|[\]\\]/g, "\\$&");
  }
  return new RegExp(`^${source}$`, "i");
}

function listFiles(directory, found = []) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.name === ".git") continue;
    const child = path.join(directory, entry.name);
    if (entry.isDirectory()) listFiles(child, found);
    else if (entry.isFile()) found.push(child);
  }
  return found;
}

// A resolved include's path feeds the source hash in the generated class
// header, so the clone lives at a path derived from the url rather than a
// random mkdtemp one: otherwise every run would emit a different class.
function cloneLibrary(url) {
  const name = crypto.createHash("sha256").update(url, "utf8").digest("hex").slice(0, 16);
  const directory = path.join(os.tmpdir(), "open-abap-gui-convert", name);
  fs.rmSync(directory, { recursive: true, force: true, maxRetries: 3 });
  fs.mkdirSync(directory, { recursive: true });
  try {
    // stdout goes to stderr too, so a --check summary on stdout stays JSON.
    execFileSync("git", ["clone", "--quiet", "--depth", "1", "--", url, "."], { cwd: directory, stdio: ["ignore", 2, 2] });
  } catch (error) {
    fs.rmSync(directory, { recursive: true, force: true, maxRetries: 3 });
    throw new Error(`unable to clone lib ${url}: ${error.message}`);
  }
  return directory;
}

/**
 * Make the libs an abap_transpile.json lists available as include search
 * paths, the way abap_transpile does: a lib whose `folder` exists (relative to
 * the working directory) is read from there, otherwise `url` is shallow-cloned
 * into a temporary folder. `files` selects the lib's sources (default
 * "/src/**") and `exclude_filter` drops some of them.
 *
 * Libs are dependencies, never conversion input: their programs are not
 * converted, only searched for INCLUDEs. Clones have to outlive the conversion
 * that reads them, so the caller removes them with the returned cleanup().
 */
export function loadLibraries(config, { log = () => {} } = {}) {
  const clones = [];
  const cleanup = () => {
    for (const directory of clones.splice(0)) fs.rmSync(directory, { recursive: true, force: true, maxRetries: 3 });
  };
  const folders = [];
  const classNames = new Set();
  try {
    for (const lib of config.libs ?? []) {
      const folder = lib.folder === undefined ? undefined : path.join(config.root, lib.folder);
      let directory;
      if (folder !== undefined && fs.existsSync(folder)) {
        log(`From folder: ${folder}`);
        directory = folder;
      } else if (lib.url === undefined) {
        throw new Error(`lib folder not found: ${folder}`);
      } else {
        log(`Clone: ${lib.url}`);
        directory = cloneLibrary(lib.url);
        clones.push(directory);
      }

      const patterns = lib.files.map((pattern) => globToRegExp(posix(pattern).replace(/^\/+/, "")));
      let count = 0;
      for (const filename of listFiles(directory)) {
        const relative = posix(path.relative(directory, filename));
        if (!patterns.some((pattern) => pattern.test(relative))) continue;
        if (lib.excludeFilters.some((filter) => filter.test(posix(filename)))) continue;
        count++;
        const lower = filename.toLowerCase();
        const parent = path.dirname(filename);
        if (INCLUDE_SUFFIXES.some((suffix) => lower.endsWith(suffix)) && !folders.includes(parent)) folders.push(parent);
        if (lower.endsWith(CLASS_SUFFIX)) classNames.add(classNameFromFilename(filename));
      }
      log(`\t${count} files added from lib`);
    }
  } catch (error) {
    cleanup();
    throw error;
  }
  return { folders: folders.sort(), classNames: [...classNames].sort(), cleanup };
}
