import fs from "node:fs/promises";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {spawn} from "node:child_process";

const repository = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const config = JSON.parse(await fs.readFile(path.join(repository, "abap_transpile.json"), "utf8"));
config.write_source_map = false;
const configPath = path.join(repository, "build", "abap_transpile.test.json");
await fs.mkdir(path.dirname(configPath), {recursive: true});
await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf8");

// Run the package's Node entry point directly, avoiding platform-specific shell wrappers.
const cli = path.join(repository, "node_modules", "@abaplint", "transpiler-cli", "abap_transpile");
const child = spawn(process.execPath, [cli, configPath], {cwd: repository, stdio: "inherit"});
child.once("error", (error) => { throw error; });
child.once("exit", (code) => { process.exitCode = code ?? 1; });
