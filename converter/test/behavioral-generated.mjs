import assert from "node:assert/strict";
import fs from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { spawn } from "node:child_process";
import { isDeepStrictEqual } from "node:util";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot, repositoryTool } from "./repository.mjs";

const repository = repositoryRoot;
const tempRoot = path.join(repository, "converter", "behavior-validation");
const inputFolder = path.join(tempRoot, "input");
const outputFolder = path.join(tempRoot, "output");
const configPath = path.join(tempRoot, "abap_transpile.json");
const lintConfigPath = path.join(repository, "converter", "behavior-abaplint.jsonc");
const toolTempRoot = path.join(repository, "converter", ".tmp");
const examples = path.join(repository, "scaffold", "examples");

const comparableFields = [
  "lines", "render_lines", "model_events", "line_formats", "messages", "values", "states",
  "blocks", "elements", "memory_render_lines", "help_text", "help_name", "terminal",
  "dialog_suppressed", "settings", "status", "title", "submit", "transaction_call",
  "navigation", "selection_active", "unsupported", "page_kind",
];

async function readTextPool(name) {
  try {
    const xml = await fs.readFile(path.join(examples, name.replace(/\.prog\.abap$/, ".prog.xml")), "utf8");
    const matches = [...xml.matchAll(/<item>\s*<ID>([^<]*)<\/ID>\s*<KEY>([^<]*)<\/KEY>\s*<ENTRY>([^<]*)<\/ENTRY>/g)];
    return Object.fromEntries(matches.map((match) => [
      match[2],
      match[3].replaceAll("&amp;", "&").replaceAll("&lt;", "<").replaceAll("&gt;", ">"),
    ]));
  } catch {
    return undefined;
  }
}

async function prepare() {
  await fs.rm(tempRoot, { recursive: true, force: true });
  await fs.rm(lintConfigPath, { force: true });
  await fs.mkdir(inputFolder, { recursive: true });
  await fs.mkdir(outputFolder, { recursive: true });

  const names = (await fs.readdir(examples))
    .filter((name) => /^zgg_ex_\d{3}\.prog\.abap$/.test(name) && Number(name.slice(7, 10)) <= 58)
    .sort();
  for (const [index, name] of names.entries()) {
    const source = await fs.readFile(path.join(examples, name), "utf8");
    const id = name.slice(7, 10);
    const className = `ZCL_BV_${id}`;
    const selectionMetadata = id === "019"
      ? { P_MODE: { fixedValues: [{ key: "A", text: "Add" }, { key: "D", text: "Delete" }] } }
      : ["020", "032"].includes(id)
        ? { S_CARR: { dataType: { rollname: "S_CARR_ID", typ: "C", length: 3 } } }
        : undefined;
    const guiStatusMetadata = id === "044"
      ? { LIST: {
        activeUcomm: ["PRI", "REFR", "DEL"],
        iconBar: [
          { ucomm: "REFR", label: "Refresh", icon: "refresh" },
          { ucomm: "PRI", label: "Print", icon: "printer", separator: true },
        ],
      } }
      : undefined;
    const result = await convertProgram({
      source,
      filename: name,
      className,
      transactionCode: `ZBV${id}`,
      mode: "partial",
      textPool: await readTextPool(name),
      ...(selectionMetadata ? { selectionMetadata } : {}),
      ...(guiStatusMetadata ? { guiStatusMetadata } : {}),
      ...(["020", "032"].includes(id) ? {
        ddicTypes: { ZSFLIGHT: { type: "zsflight", fields: { CARRID: { type: "c", length: 3 } } } },
      } : {}),
      ...(name === "zgg_ex_058.prog.abap" ? {
        dynproMetadata: {
          initialScreen: "0100",
          screens: [{ number: "0100", title: "ZCL_GG_EX_058" }, { number: "0200", title: "ZCL_GG_EX_058" }],
          flowLogic: [{ screen: "0100", pbo: [{ name: "STATUS_0100" }], pai: [{ name: "USER_COMMAND_0100" }] }],
          statuses: { "0100": { status: "SCREEN FLOW", activeUcomm: ["NEXT"] } },
        },
      } : {}),
    });
    if (!result.classSource) throw new Error(`converter produced no class for ${name}`);
    await fs.writeFile(path.join(inputFolder, `${className}.clas.abap`), result.classSource, "utf8");
  }

  const stateResult = await convertProgram({
    source: [
      "REPORT zstate_lifecycle.",
      "DATA gv_counter TYPE i VALUE 1.",
      "INITIALIZATION.",
      "  ADD 1 TO gv_counter.",
      "START-OF-SELECTION.",
      "  WRITE gv_counter.",
      "END-OF-SELECTION.",
      "  ADD 1 TO gv_counter.",
      "  WRITE / gv_counter.",
    ].join("\n"),
    filename: "zstate_lifecycle.prog.abap",
    className: "ZCL_BV_STATE",
    transactionCode: "ZBVSTATE",
  });
  if (!stateResult.classSource) throw new Error("converter produced no lifecycle state class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_STATE.clas.abap"), stateResult.classSource, "utf8");

  const resumeResult = await convertProgram({
    source: [
      "REPORT zresume_state.",
      "DATA gv_counter TYPE i VALUE 1.",
      "SELECTION-SCREEN BEGIN OF SCREEN 0500 AS WINDOW.",
      "PARAMETERS p_value TYPE c LENGTH 3.",
      "SELECTION-SCREEN END OF SCREEN 0500.",
      "START-OF-SELECTION.",
      "  ADD 1 TO gv_counter.",
      "  CALL SELECTION-SCREEN 0500.",
      "  ADD 1 TO gv_counter.",
      "  WRITE gv_counter.",
      "  WRITE / p_value.",
    ].join("\n"),
    filename: "zresume_state.prog.abap",
    className: "ZCL_BV_RESUME",
    transactionCode: "ZBVRESUME",
  });
  if (!resumeResult.classSource) throw new Error("converter produced no resumable state class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_RESUME.clas.abap"), resumeResult.classSource, "utf8");

  const dynproStateResult = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "regression_dynpro_state.prog.abap.txt"), "utf8"),
    filename: "zdynpro_state.prog.abap",
    className: "ZCL_BV_DSTATE",
    transactionCode: "ZBVDSTATE",
    dynproMetadata: {
      initialScreen: "0100",
      screens: [{ number: "0100", title: "State", elements: [{ kind: "output", name: "GV_COUNTER" }] }],
      flowLogic: [{ screen: "0100", pbo: [{ name: "STATUS_0100" }], pai: [{ name: "USER_COMMAND_0100" }] }],
      statuses: { "0100": { status: "STATE", activeUcomm: ["NEXT", "BACK"] } },
    },
  });
  if (!dynproStateResult.classSource) throw new Error("converter produced no dynpro state class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_DSTATE.clas.abap"), dynproStateResult.classSource, "utf8");

  const sqlResult = await convertProgram({
    source: [
      "REPORT zsql_behavior.",
      "DATA lt_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.",
      "START-OF-SELECTION.",
      "SELECT * FROM zsflight INTO TABLE @lt_flights ORDER BY carrid, connid, fldate.",
      "LOOP AT lt_flights INTO DATA(ls_flight).",
      "  WRITE / ls_flight-carrid.",
      "ENDLOOP.",
    ].join("\n"),
    filename: "zsql_behavior.prog.abap",
    className: "ZCL_BV_SQL",
    transactionCode: "ZBVSQL",
    ddicTypes: { ZSFLIGHT: { type: "zsflight" } },
  });
  if (!sqlResult.classSource) throw new Error("converter produced no Open SQL class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_SQL.clas.abap"), sqlResult.classSource, "utf8");

  const nestedComposite = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "composite_nested_includes.abap.txt"), "utf8"),
    filename: "zcomposite_nested.prog.abap",
    className: "ZCL_BV_CINCLUDE",
    transactionCode: "ZBVCINCLUDE",
    resolveInclude: async (name) => ({
      zcomposite_top: "DATA gv_total TYPE i.\nINCLUDE zcomposite_form.",
      zcomposite_form: "FORM add_value USING iv_value TYPE i CHANGING cv_total TYPE i.\n  ADD iv_value TO cv_total.\nENDFORM.",
    }[name]),
  });
  if (!nestedComposite.classSource) throw new Error("converter produced no nested-include composite class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_CINCLUDE.clas.abap"), nestedComposite.classSource, "utf8");

  const selectionComposite = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "composite_selection_form.abap.txt"), "utf8"),
    filename: "zcomposite_selection_form.prog.abap",
    className: "ZCL_BV_CSELECT",
    transactionCode: "ZBVCSELECT",
  });
  if (!selectionComposite.classSource) throw new Error("converter produced no selection composite class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_CSELECT.clas.abap"), selectionComposite.classSource, "utf8");

  const lifecycleOrderResult = await convertProgram({
    source: [
      "REPORT zlifecycle_order.",
      "LOAD-OF-PROGRAM.",
      "WRITE / 'load'.",
      "INITIALIZATION.",
      "WRITE / 'init'.",
      "START-OF-SELECTION.",
      "WRITE / 'start'.",
      "END-OF-SELECTION.",
      "WRITE / 'end'.",
    ].join("\n"),
    filename: "zlifecycle_order.prog.abap",
    className: "ZCL_BV_LORDER",
    transactionCode: "ZBVORDER",
  });
  if (!lifecycleOrderResult.classSource) throw new Error("converter produced no lifecycle-order class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_LORDER.clas.abap"), lifecycleOrderResult.classSource, "utf8");

  const terminalResult = await convertProgram({
    source: [
      "REPORT zterminal_effect.",
      "START-OF-SELECTION.",
      "WRITE 'before'.",
      "STOP.",
      "WRITE 'after'.",
    ].join("\n"),
    filename: "zterminal_effect.prog.abap",
    className: "ZCL_BV_TERMINAL",
    transactionCode: "ZBVTERM",
  });
  if (!terminalResult.classSource) throw new Error("converter produced no terminal-effect class");
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_TERMINAL.clas.abap"), terminalResult.classSource, "utf8");

  const dynamicWriteResult = await convertProgram({
    source: [
      "REPORT zdynamic_write_behavior.",
      "DATA gv_name TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "  gv_name = 'GV_VALUE'.",
      "  gv_value = 'dynamic'.",
      "  WRITE / (gv_name).",
    ].join("\n"),
    filename: "zdynamic_write_behavior.prog.abap",
    className: "ZCL_BV_DWRITE",
    transactionCode: "ZBVDWRITE",
  });
  if (!dynamicWriteResult.classSource || !dynamicWriteResult.supported) {
    throw new Error("converter produced no supported dynamic-WRITE class");
  }
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_DWRITE.clas.abap"), dynamicWriteResult.classSource, "utf8");

  const dynamicWriteExpressionResult = await convertProgram({
    source: [
      "REPORT zdynamic_write_expression_behavior.",
      "DATA gv_prefix TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "  gv_prefix = 'XGV_VALUE'.",
      "  gv_value = 'expression'.",
      "  WRITE / (gv_prefix+1(8)).",
    ].join("\n"),
    filename: "zdynamic_write_expression_behavior.prog.abap",
    className: "ZCL_BV_DWRITE_EXPR",
    transactionCode: "ZBVDWEXPR",
  });
  if (!dynamicWriteExpressionResult.classSource || !dynamicWriteExpressionResult.supported) {
    throw new Error("converter produced no supported dynamic-WRITE expression class");
  }
  await fs.writeFile(path.join(inputFolder, "ZCL_BV_DWRITE_EXPR.clas.abap"), dynamicWriteExpressionResult.classSource, "utf8");

  await fs.writeFile(configPath, JSON.stringify({
    input_folder: ["src", "scaffold", "converter/behavior-validation/input"],
    input_filter: [],
    exclude_filter: [],
    output_folder: "converter/behavior-validation/output",
    write_unit_tests: false,
    write_source_map: false,
    options: {
      setup: { filename: "../../../setup.mjs", preFunction: "setupDatabase" },
      ignoreSyntaxCheck: false,
      addFilenames: true,
      addCommonJS: true,
    },
    libs: [
      { url: "https://github.com/open-abap/open-abap-core" },
      { url: "https://github.com/open-abap/express-icf-shim" },
      { url: "https://github.com/open-abap/open-abap-bal" },
    ],
  }, null, 2), "utf8");

  const lintConfig = JSON.parse(await fs.readFile(path.join(repository, "abaplint.jsonc"), "utf8"));
  lintConfig.global.files = [
    "/../src/**/*.*",
    "/../scaffold/**/*.*",
    "/behavior-validation/input/*.clas.abap",
  ];
  await fs.writeFile(lintConfigPath, JSON.stringify(lintConfig, null, 2), "utf8");
  return names;
}

function runCommand(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd: repository, stdio: "inherit", shell: true });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) reject(new Error(`${command} terminated by ${signal}`));
      else if (code !== 0) reject(new Error(`${command} exited with code ${code}`));
      else resolve();
    });
  });
}

function plain(value) {
  if (value === undefined || value === null) return value;
  if (value.constructor?.name === "Table") return value.array().map(plain);
  if (value.constructor?.name === "Structure") {
    return Object.fromEntries(Object.entries(value.value ?? {}).map(([key, item]) => [key, plain(item)]));
  }
  if (Object.hasOwn(value, "value") && (typeof value.value !== "object" || value.value === null)) return value.value;
  return value;
}

function normalize(result) {
  const value = plain(result);
  const normalized = {};
  for (const field of comparableFields) normalized[field] = value[field];
  normalized.title = "<generated-title>";
  normalized.values = normalized.values?.map((item) => ({
    ...item,
    name: item.name?.trimEnd(),
  }));
  normalized.states = normalized.states?.map((item) => ({
    ...item,
    name: item.name?.trimEnd(),
  }));
  return normalized;
}

function inputValues(entries, hostClass) {
  const table = hostClass.METHODS.RUN.parameters.IT_INPUT.type();
  for (const [name, value] of entries) {
    const row = table.cloneRow(table.rowType);
    row.get().name.set(name);
    row.get().value.set(value);
    table.append(row);
  }
  return table;
}

function mismatch(actual, expected) {
  return Object.fromEntries(comparableFields
    .filter((field) => !isDeepStrictEqual(actual[field], expected[field]))
    .map((field) => [field, { actual: describe(field, actual[field]), expected: describe(field, expected[field]) }]));
}

function describe(field, value) {
  if (Array.isArray(value)) {
    if (field === "render_lines") return value.map((item) => item.text);
    if (field === "lines") return value;
    if (field === "values") return value.map((item) => ({ name: item.name?.trim(), value: item.value, ranges: item.ranges }));
    if (field === "elements" || field === "states") {
      return value.map((item) => ({
        kind: item.kind,
        name: item.name,
        text: item.text,
        screen: item.screen,
        modif_id: item.modif_id,
        group1: item.group1,
        visible: item.visible,
        enabled: item.enabled,
        input: item.input,
        output: item.output,
      }));
    }
    if (field === "blocks") return value.map((item) => ({ block: item.block, depth: item.depth }));
    return { length: value.length };
  }
  if (value && typeof value === "object") {
    if (field === "status") return {
      status: value.status?.trim(),
      active_ucomm: value.active_ucomm?.map((item) => item.trim()),
      excluded_ucomm: value.excluded_ucomm?.map((item) => item.trim()),
      active_pf_keys: value.active_pf_keys,
      icon_bar: value.icon_bar?.map((item) => ({ ucomm: item.ucomm?.trim(), label: item.label, icon: item.icon, separator: item.separator })),
    };
    if (field === "navigation") return {
      kind: value.kind,
      target: value.target?.trim(),
      continuation: value.continuation,
      modal: value.modal,
    };
    if (field === "status") return value;
    return Object.keys(value);
  }
  return value;
}

async function loadClass(name) {
  const module = await import(pathToFileURL(path.join(outputFolder, `${name.toLowerCase()}.clas.mjs`)).href);
  return module[name.toLowerCase()];
}

const names = await prepare();
try {
  await runCommand(repositoryTool("abaplint"), [path.relative(repository, lintConfigPath)]);
  await runCommand(repositoryTool("abap_transpile"), [path.relative(repository, configPath)]);
  await import(pathToFileURL(path.join(outputFolder, "init.mjs")).href);
  const { zcl_gg_host } = await import(pathToFileURL(path.join(outputFolder, "zcl_gg_host.clas.mjs")).href);
  const { zcl_gg_host_dynpro } = await import(pathToFileURL(path.join(outputFolder, "zcl_gg_host_dynpro.clas.mjs")).href);
  const failures = [];

  for (const name of names) {
    const id = name.slice(7, 10);
    if (id === "058") continue;
    const [generated, handWritten] = await Promise.all([
      loadClass(`zcl_bv_${id}`),
      loadClass(`zcl_gg_ex_${id}`),
    ]);
    if (!generated || !handWritten) throw new Error(`class module missing for example ${id}`);
    const expectedReport = new abap.Classes[`ZCL_GG_EX_${id}`]();
    const expected = normalize(await zcl_gg_host.run({ io_report: expectedReport, rs_result: 1 }));
    const actual = normalize(await zcl_gg_host.run({ io_report: new abap.Classes[`ZCL_BV_${id}`](), rs_result: 1 }));
    try {
      assert.deepEqual(actual, expected);
    } catch (error) {
      failures.push({ example: id, message: error.message.split("\n")[0], mismatch: mismatch(actual, expected) });
    }
  }

  const stateResult = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_STATE(),
    rs_result: 1,
  }));
  assert.deepEqual(stateResult.lines, ["2", "3"]);

  const resumable = new abap.Classes.ZCL_BV_RESUME();
  const paused = await zcl_gg_host.run({
    io_report: resumable,
    rs_result: 1,
    iv_pause_at_navigation: abap.builtin.abap_true,
  });
  const pausedView = plain(paused);
  assert.equal(pausedView.navigation.kind, "CALL_SELECTION_SCREEN");
  assert.equal(pausedView.navigation.target.trim(), "0500");
  const resumed = normalize(await zcl_gg_host.run({
    io_report: resumable,
    rs_result: 1,
    it_input: inputValues([["P_VALUE", "OK"]], zcl_gg_host),
    is_resume_navigation: paused.get().navigation,
    is_resume_submit: paused.get().submit,
  }));
  assert.deepEqual(resumed.lines, ["3", "OK"]);

  const dynproState = new abap.Classes.ZCL_BV_DSTATE();
  const firstDynproState = plain(await zcl_gg_host_dynpro.run({
    io_program: dynproState,
    iv_ucomm: "NEXT",
  }));
  assert.equal(firstDynproState.values.find((item) => item.name.trim() === "GV_COUNTER")?.value.trim(), "3");
  const secondDynproState = plain(await zcl_gg_host_dynpro.run({
    io_program: dynproState,
    iv_ucomm: "BACK",
  }));
  assert.equal(secondDynproState.values.find((item) => item.name.trim() === "GV_COUNTER")?.value.trim(), "4");

  const nestedComposite = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_CINCLUDE(),
    rs_result: 1,
  }));
  assert.deepEqual(nestedComposite.lines, ["1"]);
  const selectionComposite = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_CSELECT(),
    rs_result: 1,
  }));
  assert.deepEqual(selectionComposite.lines, ["ABAP"]);
  const lifecycleOrder = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_LORDER(),
    rs_result: 1,
  }));
  assert.deepEqual(lifecycleOrder.lines, ["load", "init", "start", "end"]);
  const terminal = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_TERMINAL(),
    rs_result: 1,
  }));
  assert.deepEqual(terminal.lines, ["before"]);

  const dynamicWrite = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_DWRITE(),
    rs_result: 1,
  }));
  assert.deepEqual(dynamicWrite.lines, ["dynamic"]);

  const dynamicWriteExpression = normalize(await zcl_gg_host.run({
    io_report: new abap.Classes.ZCL_BV_DWRITE_EXPR(),
    rs_result: 1,
  }));
  assert.deepEqual(dynamicWriteExpression.lines, ["expression"]);

  const dbSystem = abap.builtin.sy.get().dbsys;
  const previousDbSystem = dbSystem.get();
  dbSystem.set("sqlite");
  await abap.Classes.ZCL_GG_DB_HELPER.create();
  try {
    await abap.Classes.ZCL_GG_DB_HELPER.reset();
    const sqlResult = normalize(await zcl_gg_host.run({
      io_report: new abap.Classes.ZCL_BV_SQL(),
      rs_result: 1,
    }));
    assert.deepEqual(sqlResult.lines, ["AA", "AA", "LH", "LH", "SQ"]);
  } finally {
    await abap.Classes.ZCL_GG_DB_HELPER.destroy();
    dbSystem.set(previousDbSystem);
  }

  const scenarios = [
    { id: "031", name: "user input", options: (hostClass) => ({ it_input: inputValues([["P_CARR", "lh"]], hostClass) }) },
    { id: "030", name: "validation failure", options: (hostClass) => ({ it_input: inputValues([["P_N", "-1"]], hostClass) }) },
    { id: "044", name: "interactive user command", options: () => ({ iv_user_command: "REFR" }) },
    { id: "049", name: "interactive PF action", options: () => ({ iv_pf_key: 5 }) },
  ];
  for (const scenario of scenarios) {
    const generated = new abap.Classes[`ZCL_BV_${scenario.id}`]();
    const handWritten = new abap.Classes[`ZCL_GG_EX_${scenario.id}`]();
    const expected = normalize(await zcl_gg_host.run({ io_report: handWritten, rs_result: 1, ...scenario.options(zcl_gg_host) }));
    const actual = normalize(await zcl_gg_host.run({ io_report: generated, rs_result: 1, ...scenario.options(zcl_gg_host) }));
    const differences = mismatch(actual, expected);
    if (Object.keys(differences).length) failures.push({ example: scenario.id, scenario: scenario.name, mismatch: differences });
  }

  const generatedDynpro = new abap.Classes.ZCL_BV_058();
  const handWrittenDynpro = new abap.Classes.ZCL_GG_EX_058();
  for (const ucomm of ["NEXT", "BACK"]) {
    const expected = await zcl_gg_host_dynpro.run({ io_program: handWrittenDynpro, iv_ucomm: ucomm });
    const actual = await zcl_gg_host_dynpro.run({ io_program: generatedDynpro, iv_ucomm: ucomm });
    for (const field of ["screen", "terminal", "terminal_state", "status", "screens", "flow"]) {
      const expectedValue = plain(expected[field]);
      const actualValue = plain(actual[field]);
      if (!isDeepStrictEqual(actualValue, expectedValue)) {
        failures.push({ example: "058", path: `${ucomm}.${field}`, actual: actualValue, expected: expectedValue });
      }
    }
  }

  if (failures.length) {
    throw new Error(`behavioral parity failed for ${failures.length} fixture(s):\n${JSON.stringify(
      failures.map(({ example, mismatch: differences }) => ({ example, mismatch: differences })),
      null,
      2,
    )}`);
  }
  console.log(`behavioral parity passed for ${names.length - 1} report fixtures and dynpro transitions for 058`);
} finally {
  await fs.rm(tempRoot, { recursive: true, force: true });
  await fs.rm(lintConfigPath, { force: true });
  await fs.rm(toolTempRoot, { recursive: true, force: true });
}
