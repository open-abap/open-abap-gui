import {spawnSync} from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

// Lints src and framework without the examples. The regular lint compiles
// everything together, so only this run notices when the framework starts to
// name an example class again.

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const configPath = path.join(repository, "build", "abaplint-framework.json");

const config = JSON.parse(fs.readFileSync(path.join(repository, "abaplint.jsonc"), "utf8"));
config.global.files = ["/../src/**/*.*", "/../framework/**/*.*"];
fs.mkdirSync(path.dirname(configPath), {recursive: true});
fs.writeFileSync(configPath, JSON.stringify(config, null, 2), "utf8");

const result = spawnSync("npx", ["abaplint", path.relative(repository, configPath)], {
  cwd: repository,
  stdio: "inherit",
  shell: true,
});
process.exitCode = result.status ?? 1;
