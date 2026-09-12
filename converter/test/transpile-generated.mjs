import fs from "node:fs/promises";
import path from "node:path";
import { spawn } from "node:child_process";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot, repositoryTool } from "./repository.mjs";

const repository = repositoryRoot;
const tempRoot = path.join(repository, "converter", "transpile-validation");
const inputFolder = path.join(tempRoot, "input");
const outputFolder = path.join(tempRoot, "output");
const configPath = path.join(tempRoot, "abap_transpile.json");
const lintConfigPath = path.join(repository, "converter", "abaplint-validation.jsonc");
const toolTempRoot = path.join(repository, "converter", ".tmp");
const examples = path.join(repository, "scaffold", "examples");

async function prepare() {
  await fs.rm(tempRoot, { recursive: true, force: true });
  await fs.rm(lintConfigPath, { force: true });
  await fs.mkdir(inputFolder, { recursive: true });
  await fs.mkdir(outputFolder, { recursive: true });

  const names = (await fs.readdir(examples))
    .filter((name) => name.endsWith(".prog.abap"))
    .sort();
  for (const [index, name] of names.entries()) {
    const source = await fs.readFile(path.join(examples, name), "utf8");
    const className = `ZCL_CV_${String(index + 1).padStart(3, "0")}`;
    const input = {
      source,
      filename: name,
      className,
      transactionCode: `ZCV${String(index + 1).padStart(3, "0")}`,
      mode: "partial",
    };
    if (name === "zgg_ex_058.prog.abap") input.dynproMetadata = {
      initialScreen: "0100",
      screens: [{ number: "0100", title: "Main" }, { number: "0200", title: "Next" }],
      flowLogic: [{ screen: "0100", pai: [{ name: "USER_COMMAND_0100" }] }],
    };
    const result = await convertProgram(input);
    if (!result.classSource) throw new Error(`converter produced no class for ${name}`);
    await fs.writeFile(path.join(inputFolder, `${className}.clas.abap`), result.classSource, "utf8");
  }

  const routine = await convertProgram({
    source: [
      "REPORT zcv_form.",
      "DATA gv_result TYPE i.",
      "FORM add USING iv_left TYPE i CHANGING cv_result TYPE i.",
      "  cv_result = iv_left.",
      "ENDFORM.",
      "START-OF-SELECTION.",
      "PERFORM add USING 1 CHANGING gv_result.",
    ].join("\n"),
    filename: "zcv_form.prog.abap",
    className: "ZCL_CV_FORM",
    transactionCode: "ZCVFORM",
  });
  if (!routine.classSource || !routine.supported) throw new Error("FORM/PERFORM semantic validation fixture was not converted");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_FORM.clas.abap"), routine.classSource, "utf8");

  const declarationShapes = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "regression_declaration_shapes.abap.txt"), "utf8"),
    filename: "regression_declaration_shapes.prog.abap",
    className: "ZCL_CV_DECL",
    transactionCode: "ZCVDECL",
  });
  if (!declarationShapes.classSource || !declarationShapes.supported) throw new Error("structured declaration validation fixture was not converted");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_DECL.clas.abap"), declarationShapes.classSource, "utf8");

  const exceptionBlock = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "regression_exception_block.abap.txt"), "utf8"),
    filename: "regression_exception_block.prog.abap",
    className: "ZCL_CV_EXC",
    transactionCode: "ZCVEXC",
  });
  if (!exceptionBlock.classSource || !exceptionBlock.supported) throw new Error("exception-block validation fixture was not converted");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_EXC.clas.abap"), exceptionBlock.classSource, "utf8");

  const dynamicWriteSupported = await convertProgram({
    source: [
      "REPORT zcv_dynamic_write_supported.",
      "DATA gv_name TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "  gv_name = 'GV_VALUE'.",
      "  gv_value = 'dynamic'.",
      "  WRITE / (gv_name).",
    ].join("\n"),
    filename: "zcv_dynamic_write_supported.prog.abap",
    className: "ZCL_CV_DWRITE_SAFE",
    transactionCode: "ZCVDWSAFE",
  });
  if (!dynamicWriteSupported.classSource || !dynamicWriteSupported.supported) throw new Error("supported dynamic-WRITE lowering was not converted");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_DWRITE_SAFE.clas.abap"), dynamicWriteSupported.classSource, "utf8");

  const dynamicWriteExpression = await convertProgram({
    source: [
      "REPORT zcv_dynamic_write_expression.",
      "DATA gv_prefix TYPE string.",
      "DATA gv_value TYPE string.",
      "START-OF-SELECTION.",
      "  gv_prefix = 'XGV_VALUE'.",
      "  gv_value = 'expression'.",
      "  WRITE / (gv_prefix+1(8)).",
    ].join("\n"),
    filename: "zcv_dynamic_write_expression.prog.abap",
    className: "ZCL_CV_DWRITE_EXPR",
    transactionCode: "ZCVDWEXPR",
  });
  if (!dynamicWriteExpression.classSource || !dynamicWriteExpression.supported) throw new Error("supported dynamic-WRITE expression lowering was not converted");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_DWRITE_EXPR.clas.abap"), dynamicWriteExpression.classSource, "utf8");

  const dynamicWrite = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "regression_dynamic_write.abap.txt"), "utf8"),
    filename: "regression_dynamic_write.prog.abap",
    className: "ZCL_CV_DWRITE",
    transactionCode: "ZCVDWRITE",
  });
  if (!dynamicWrite.classSource || !dynamicWrite.supported) throw new Error("dynamic-WRITE substring fixture was not converted");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_DWRITE.clas.abap"), dynamicWrite.classSource, "utf8");

  const dynamicWriteCall = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "regression_dynamic_write_call.abap.txt"), "utf8"),
    filename: "regression_dynamic_write_call.prog.abap",
    className: "ZCL_CV_DWRITE_CALL",
    transactionCode: "ZCVDWCALL",
    mode: "partial",
  });
  if (!dynamicWriteCall.classSource || dynamicWriteCall.supported) throw new Error("dynamic-WRITE call fixture was not marked partial");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_DWRITE_CALL.clas.abap"), dynamicWriteCall.classSource, "utf8");

  const dynamicWriteFallback = await convertProgram({
    source: await fs.readFile(path.join(repository, "converter", "test", "fixtures", "regression_dynamic_write_fallback.abap.txt"), "utf8"),
    filename: "regression_dynamic_write_fallback.prog.abap",
    className: "ZCL_CV_DWRITE_FALLBACK",
    transactionCode: "ZCVDWFALL",
    mode: "partial",
  });
  if (!dynamicWriteFallback.classSource || dynamicWriteFallback.supported) throw new Error("dynamic-WRITE fallback fixture was not marked partial");
  await fs.writeFile(path.join(inputFolder, "ZCL_CV_DWRITE_FALLBACK.clas.abap"), dynamicWriteFallback.classSource, "utf8");

  await fs.writeFile(configPath, JSON.stringify({
    input_folder: ["src", "scaffold", "converter/transpile-validation/input"],
    input_filter: [],
    exclude_filter: [],
    output_folder: "converter/transpile-validation/output",
    write_unit_tests: false,
    write_source_map: false,
    options: {
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
    "/transpile-validation/input/*.clas.abap",
  ];
  await fs.writeFile(lintConfigPath, JSON.stringify(lintConfig, null, 2), "utf8");
}

function runCommand(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: repository,
      stdio: "inherit",
      shell: true,
    });
    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) reject(new Error(`transpiler terminated by ${signal}`));
      else if (code !== 0) reject(new Error(`transpiler exited with code ${code}`));
      else resolve();
    });
  });
}

try {
  await prepare();
  await runCommand(repositoryTool("abaplint"), [path.relative(repository, lintConfigPath)]);
  await runCommand(repositoryTool("abap_transpile"), [path.relative(repository, configPath)]);
  console.log("generated converter classes passed the open-abap transpiler");
  await fs.rm(tempRoot, { recursive: true, force: true });
  await fs.rm(lintConfigPath, { force: true });
  await fs.rm(toolTempRoot, { recursive: true, force: true });
} catch (error) {
  console.error(error.message);
  console.error(`validation artifacts retained in ${tempRoot}`);
  process.exitCode = 1;
}
