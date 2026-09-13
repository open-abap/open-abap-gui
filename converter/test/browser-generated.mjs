import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import {once} from "node:events";
import {spawn} from "node:child_process";
import {createServer} from "node:net";
import {chromium} from "playwright";
import {convertProgram} from "../src/api.mjs";
import {repositoryRoot, repositoryTool} from "./repository.mjs";

const repository = repositoryRoot;
const tempRoot = path.join(repository, "converter", "browser-validation");
const inputFolder = path.join(tempRoot, "input");
const outputFolder = path.join(tempRoot, "output");
const configPath = path.join(tempRoot, "abap_transpile.json");
const sourcePath = path.join(repository, "scaffold", "examples", "zgg_ex_058.prog.abap");

async function freePort() {
  const probe = createServer();
  await new Promise((resolve) => probe.listen(0, "127.0.0.1", resolve));
  const port = probe.address().port;
  await new Promise((resolve, reject) => probe.close((error) => error ? reject(error) : resolve()));
  return port;
}

function runCommand(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: repository,
      stdio: "inherit",
      shell: command.endsWith(".cmd"),
    });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) reject(new Error(`${command} terminated by ${signal}`));
      else if (code !== 0) reject(new Error(`${command} exited with code ${code}`));
      else resolve();
    });
  });
}

async function stopProcess(child) {
  if (!child || child.exitCode !== null || child.signalCode !== null) return;
  child.kill();
  await once(child, "close");
}

async function waitForHost(child, baseUrl) {
  const timeout = setTimeout(() => child.kill(), 15000);
  try {
    while (true) {
      if (child.exitCode !== null) throw new Error(`ABAP HTML host exited during startup (${child.exitCode})`);
      try {
        const response = await fetch(`${baseUrl}/`);
        if (response.ok) return;
      } catch {
        // The host is still starting.
      }
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
  } finally {
    clearTimeout(timeout);
  }
}

async function writeInputs() {
  await fs.rm(tempRoot, {recursive: true, force: true});
  await fs.mkdir(inputFolder, {recursive: true});
  await fs.mkdir(outputFolder, {recursive: true});

  const source = await fs.readFile(sourcePath, "utf8");
  const result = await convertProgram({
    source,
    filename: "zgg_ex_058.prog.abap",
    className: "ZCL_CV_BROWSER_058",
    transactionCode: "ZCVB058",
    mode: "partial",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{number: "0100", title: "ZCL_CV_BROWSER_058"}, {number: "0200", title: "ZCL_CV_BROWSER_058"}],
      flowLogic: [{screen: "0100", pbo: [{name: "STATUS_0100"}], pai: [{name: "USER_COMMAND_0100"}]}],
      statuses: {"0100": {status: "SCREEN FLOW", activeUcomm: ["NEXT"]}},
    },
  });
  assert.ok(result.classSource, "converter produced no generated browser dynpro class");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_BROWSER_058.clas.abap"), result.classSource, "utf8");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_BROWSER_TEST.clas.abap"), [
    "CLASS zcl_cv_browser_test DEFINITION PUBLIC FINAL CREATE PUBLIC.",
    "ENDCLASS.",
    "",
    "CLASS zcl_cv_browser_test IMPLEMENTATION.",
    "ENDCLASS.",
    "",
  ].join("\n"), "utf8");

  await fs.writeFile(path.join(inputFolder, "ZCL_CV_BROWSER_TEST.clas.testclasses.abap"), [
    "CLASS ltcl_cv_browser_058 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.",
    "  PRIVATE SECTION.",
    "    METHODS reaches_next_screen FOR TESTING.",
    "    METHODS leaves_to_zero FOR TESTING.",
    "ENDCLASS.",
    "",
    "CLASS ltcl_cv_browser_058 IMPLEMENTATION.",
    "  METHOD reaches_next_screen.",
    "    DATA(ls_result) = zcl_gg_host_dynpro=>run(",
    "      io_program = NEW zcl_cv_browser_058( )",
    "      iv_ucomm   = 'NEXT' ).",
    "    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0200' ).",
    "    cl_abap_unit_assert=>assert_equals( act = ls_result-terminal exp = 'LEAVE SCREEN' ).",
    "  ENDMETHOD.",
    "",
    "  METHOD leaves_to_zero.",
    "    DATA(ls_result) = zcl_gg_host_dynpro=>run(",
    "      io_program = NEW zcl_cv_browser_058( )",
    "      iv_ucomm   = 'BACK' ).",
    "    cl_abap_unit_assert=>assert_equals( act = ls_result-screen exp = '0000' ).",
    "    cl_abap_unit_assert=>assert_equals( act = ls_result-terminal exp = 'LEAVE TO SCREEN 0000' ).",
    "  ENDMETHOD.",
    "ENDCLASS.",
    "",
  ].join("\n"), "utf8");

  await fs.writeFile(configPath, JSON.stringify({
    input_folder: ["src", "scaffold", "converter/browser-validation/input"],
    input_filter: [],
    exclude_filter: [],
    output_folder: "converter/browser-validation/output",
    write_unit_tests: true,
    write_source_map: false,
    options: {
      setup: {filename: "../../../setup.mjs", preFunction: "setupDatabase"},
      ignoreSyntaxCheck: false,
      addFilenames: true,
      addCommonJS: true,
    },
    libs: [
      {url: "https://github.com/open-abap/open-abap-core"},
      {url: "https://github.com/open-abap/express-icf-shim"},
      {url: "https://github.com/open-abap/open-abap-bal"},
    ],
  }, null, 2), "utf8");
}

async function dispatch(page, request) {
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const response = await page.evaluate(async ({sessionId, pageId, request}) => {
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({session_id: sessionId, page_id: pageId, ...request}),
    });
    return {status: result.status, html: await result.text()};
  }, {sessionId, pageId, request});
  assert.equal(response.status, 200, response.html);
  await page.evaluate((html) => {
    document.open();
    document.write(html);
    document.close();
  }, response.html);
  await page.locator("[data-page-kind]").waitFor();
}

await writeInputs();
let serverProcess;
let browser;
try {
  await runCommand(repositoryTool("abap_transpile"), [path.relative(repository, configPath)]);
  await runCommand(process.execPath, [path.join(outputFolder, "index.mjs")]);

  const port = await freePort();
  serverProcess = spawn(process.execPath, ["test/start-server.mjs"], {
    cwd: repository,
    env: {
      ...process.env,
      OPEN_ABAP_GUI_PORT: String(port),
      OPEN_ABAP_GUI_OUTPUT: outputFolder,
    },
    stdio: "inherit",
  });
  const baseUrl = `http://127.0.0.1:${port}`;
  await waitForHost(serverProcess, baseUrl);

  browser = await chromium.launch({headless: true});
  const page = await browser.newPage();
  const response = await page.goto(`${baseUrl}/transaction?tcode=ZCVB058`);
  assert.equal(response?.status(), 200);
  await page.locator("[data-page-kind]").waitFor();
  assert.equal(await page.locator("[data-page-kind]").getAttribute("data-page-kind"), "DYNPRO");
  assert.equal(await page.locator(".wb-app-title").textContent(), "ZCL_CV_BROWSER_058");
  assert.equal(await page.locator('[data-screen="0100"]').count(), 1);

  await dispatch(page, {action: "SUBMIT", ucomm: "NEXT"});
  assert.equal(await page.locator('[data-screen="0200"]').count(), 1);
  await page.goto(`${baseUrl}/transaction?tcode=ZCVB058`);
  await page.locator("[data-page-kind]").waitFor();
  await dispatch(page, {action: "SUBMIT", ucomm: "BACK"});
  assert.equal(await page.locator('[data-screen="0000"]').count(), 1);
  console.log("generated converter dynpro 058 passed ABAP Unit and browser integration");
} finally {
  await browser?.close();
  await stopProcess(serverProcess);
}

await fs.rm(tempRoot, {recursive: true, force: true});
