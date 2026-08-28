'use strict';
/*
 * Regression test for open-abap-gui
 *
 * Downstream projects consume the ABAP source in this repository as a transpiler
 * library, so a change here can break them without anything failing locally.
 *
 * This script clones a consumer (abapGit by default), points its open-abap-gui
 * library at this checkout instead of https://github.com/open-abap/open-abap-gui,
 * and runs the consumer unit tests. If they fail, the consumer is tested once more
 * with the upstream open-abap-gui, to tell a regression apart from a failure that
 * is already there.
 *
 * Run from the root of this repository: node .github/regression/run.js
 *
 * Environment, to test another consumer:
 *   REGRESSION_REPO    "owner/repo" to clone, default abapGit/abapGit
 *   REGRESSION_BRANCH  branch to clone, default main
 *   REGRESSION_CONFIG  transpiler config in the consumer, default test/abap_transpile.json
 *   REGRESSION_UNIT    command running the unit tests, default "npm run unit"
 *
 * Exit code 0 = no regression, 1 = regression or setup failure
 */

const fs = require("fs");
const path = require("path");
const childProcess = require("child_process");

const LIB = "open-abap-gui";
const REPO = process.env.REGRESSION_REPO || "abapGit/abapGit";
const BRANCH = process.env.REGRESSION_BRANCH || "main";
const CONFIG = process.env.REGRESSION_CONFIG || "test/abap_transpile.json";
const UNIT = process.env.REGRESSION_UNIT || "npm run unit";
const WORK = "regression-work";
const LIB_FOLDER = "regression-lib";
const TAIL_LINES = 60;
const GIT_BASH = "C:\\Program Files\\Git\\bin\\bash.exe";
// abapGit's build script uses POSIX rm; use Git Bash for the default unit
// command on Windows when it is available.
const UNIT_SHELL = process.platform === "win32" && UNIT === "npm run unit" &&
  fs.existsSync(GIT_BASH) ? GIT_BASH : true;

function run(command, cwd, logfile, shell = true) {
  console.log("\n$ " + command + "    [" + cwd + "]");
  const res = childProcess.spawnSync(command, {
    cwd: cwd,
    shell: shell,
    encoding: "utf-8",
    maxBuffer: 256 * 1024 * 1024,
  });
  const output = (res.stdout || "") + (res.stderr || "");
  console.log(output);
  if (logfile !== undefined) {
    fs.writeFileSync(logfile, output);
  }
  return {ok: res.status === 0, output: output};
}

function tail(text, lines) {
  const split = text.replace(/\r/g, "").trimEnd().split("\n");
  const cut = split.slice(Math.max(0, split.length - lines));
  return (split.length > cut.length ? "[...]\n" : "") + cut.join("\n");
}

// point the open-abap-gui library of the consumer at "folder", relative to the consumer root
function useLocalLib(configFile, folder) {
  const config = JSON.parse(fs.readFileSync(configFile, "utf-8"));
  const found = (config.libs || []).filter(l => (l.url || "").includes(LIB));
  if (found.length !== 1) {
    throw new Error("Expected exactly one " + LIB + " library in " + CONFIG + ", found " + found.length);
  }
  delete found[0].url;
  found[0].folder = "/" + folder;
  fs.writeFileSync(configFile, JSON.stringify(config, null, 2) + "\n");
  console.log("Using " + LIB + " from " + folder + " instead of upstream");
}

function report(icon, headline, details) {
  let body = "## Regression: " + REPO + "\n\n";
  body += "`" + UNIT + "` in [" + REPO + "](https://github.com/" + REPO + ")";
  body += " (branch `" + BRANCH + "`), with " + LIB + " from this checkout";
  if (process.env.GITHUB_SHA !== undefined) {
    body += " (" + process.env.GITHUB_SHA.substring(0, 7) + ")";
  }
  body += "\n\n" + icon + " **" + headline + "**\n";
  if (details !== undefined && details !== "") {
    body += "\n<details><summary>Last " + TAIL_LINES + " lines</summary>\n\n";
    body += "```\n" + details + "\n```\n\n</details>\n";
  }

  fs.writeFileSync(path.join(WORK, "summary.md"), body);
  if (process.env.GITHUB_STEP_SUMMARY !== undefined) {
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, body);
  }
  console.log("\n" + body);
}

function main() {
  if (fs.existsSync("abap_transpile.json") === false || fs.existsSync("src") === false) {
    throw new Error("Run this from the root of the " + LIB + " repository");
  }

  fs.rmSync(WORK, {recursive: true, force: true});
  fs.mkdirSync(WORK, {recursive: true});

  const clone = path.join(WORK, REPO.split("/")[1]);
  const cloned = run("git clone --quiet --depth=1 --branch " + BRANCH +
    " https://github.com/" + REPO + ".git " + clone, ".");
  if (cloned.ok === false) {
    report(":red_circle:", "Unable to clone " + REPO, tail(cloned.output, TAIL_LINES));
    return 1;
  }

  // the transpiler resolves lib folders relative to the consumer root, so copy the
  // sources in, this keeps the lib path independent of where the checkout lives
  fs.cpSync("src", path.join(clone, LIB_FOLDER, "src"), {recursive: true});

  const install = run("npm install", clone, path.join(WORK, "install.log"));
  if (install.ok === false) {
    report(":red_circle:", "Unable to install dependencies of " + REPO, tail(install.output, TAIL_LINES));
    return 1;
  }

  const configFile = path.join(clone, CONFIG);
  const upstream = fs.readFileSync(configFile, "utf-8");
  useLocalLib(configFile, LIB_FOLDER);

  const local = run(UNIT, clone, path.join(WORK, "unit-local.log"), UNIT_SHELL);
  if (local.ok) {
    report(":green_circle:", REPO + " unit tests pass");
    return 0;
  }

  // failed, check whether the upstream open-abap-gui fails in the same way
  console.log("\nFailed, running again with the upstream " + LIB + " for comparison");
  fs.writeFileSync(configFile, upstream);
  const reference = run(UNIT, clone, path.join(WORK, "unit-upstream.log"), UNIT_SHELL);
  if (reference.ok) {
    report(":red_circle:", "Regression, " + REPO + " unit tests fail with this branch, but pass with " +
      LIB + " main", tail(local.output, TAIL_LINES));
    return 1;
  }

  report(":yellow_circle:", REPO + " unit tests fail with this branch, but also with " + LIB +
    " main, so the failure is not caused by this branch", tail(local.output, TAIL_LINES));
  return 0;
}

process.exitCode = main();
