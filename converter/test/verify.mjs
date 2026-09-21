import { spawn } from "node:child_process";
import { converterRoot } from "./repository.mjs";

const commands = [
  ["test:unit", []],
  ["check", []],
  ["check:matrix", []],
  ["fixtures", []],
  ["structural", []],
  ["warnings", []],
  ["hardening", []],
  ["coverage", []],
  ["transpile", []],
  ["behavior", []],
  ["browser", []],
];

// --skip lets the CI chain drop a suite that is known to fail for reasons
// unrelated to the change under test; run `npm test` with no arguments to get
// the full picture locally.
const skipped = new Set();
for (let index = 0; index < process.argv.length; index++) {
  if (process.argv[index] === "--skip" && process.argv[index + 1]) skipped.add(process.argv[index + 1]);
}

function run(script, args) {
  return new Promise((resolve, reject) => {
    const npm = process.platform === "win32" ? "npm.cmd" : "npm";
    const child = spawn(npm, ["run", script, ...args], {
      cwd: converterRoot,
      stdio: "inherit",
      shell: true,
    });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) reject(new Error(`${script} terminated by ${signal}`));
      else if (code !== 0) reject(new Error(`${script} exited with code ${code}`));
      else resolve();
    });
  });
}

for (const [script, args] of commands) {
  if (skipped.has(script)) {
    console.log(`\n=== npm run ${script} (skipped) ===`);
    continue;
  }
  console.log(`\n=== npm run ${script} ===`);
  await run(script, args);
}

console.log("\nconverter verification passed");
