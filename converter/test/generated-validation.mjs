import fs from "node:fs/promises";
import path from "node:path";
import {Config} from "@abaplint/core";
import {repositoryRoot, runNode} from "./repository.mjs";
import {prepareTranspileFixtures, checkRenamedSubmitTarget} from "./generated-transpile.mjs";
import {prepareBehaviorFixtures} from "./generated-behavior.mjs";

// Compile the union once; runtime probes keep independent ABAP globals.
export async function runGeneratedValidation({transpile = true, behavior = true} = {}) {
  if (!transpile && !behavior) return;
  const tempRoot = path.join(repositoryRoot, "converter", "transpile-validation");
  const inputFolder = path.join(tempRoot, "input");
  const helperFolder = path.join(tempRoot, "helpers");
  const behaviorFolder = path.join(tempRoot, "behavior");
  const outputFolder = path.join(tempRoot, "output");
  const configPath = path.join(tempRoot, "abap_transpile.json");
  const lintConfigPath = path.join(repositoryRoot, "converter", "abaplint-validation.jsonc");
  const toolTempRoot = path.join(repositoryRoot, "converter", ".tmp");
  const relative = (filename) => path.relative(repositoryRoot, filename).replaceAll("\\", "/");

  try {
    await fs.rm(tempRoot, {recursive: true, force: true});
    for (const folder of [inputFolder, helperFolder, behaviorFolder, outputFolder]) {
      await fs.mkdir(folder, {recursive: true});
    }
    if (transpile) await prepareTranspileFixtures({inputFolder, helperFolder});
    if (behavior) await prepareBehaviorFixtures({inputFolder: behaviorFolder});

    const config = JSON.parse(await fs.readFile(path.join(repositoryRoot, "abap_transpile.json"), "utf8"));
    config.input_folder = [config.input_folder].flat().concat(
      transpile ? [relative(inputFolder), relative(helperFolder)] : [],
      behavior ? [relative(behaviorFolder)] : [],
    );
    config.output_folder = relative(outputFolder);
    config.write_unit_tests = false;
    config.write_source_map = false;
    config.options.setup.filename = "../../../setup.mjs";
    await fs.writeFile(configPath, JSON.stringify(config, null, 2), "utf8");

    const lintConfig = JSON.parse(await fs.readFile(path.join(repositoryRoot, "abaplint.jsonc"), "utf8"));
    // abaplint resolves patterns against the config directory, unlike the transpiler.
    lintConfig.global.files = lintConfig.global.files.map((pattern) => `/..${pattern}`);
    if (transpile) lintConfig.global.files.push("/transpile-validation/input/*.clas.*", "/transpile-validation/helpers/*.clas.abap");
    if (behavior) lintConfig.global.files.push("/transpile-validation/behavior/*.clas.abap");
    if (transpile) {
      // Helpers retain syntax checks and their original formatting exemption.
      const ruleDefaults = Config.getDefault().get().rules;
      for (const [name, value] of Object.entries(lintConfig.rules)) {
        if (name === "check_syntax" || value === false) continue;
        const rule = value === true ? {...ruleDefaults[name]} : value;
        rule.exclude = [...(rule.exclude ?? []), "transpile-validation[\\\\/]helpers[\\\\/]"];
        lintConfig.rules[name] = rule;
      }
    }
    await fs.writeFile(lintConfigPath, JSON.stringify(lintConfig, null, 2), "utf8");

    console.log("\n=== generated converter validation: shared lint and transpile ===");
    await runNode([path.join(repositoryRoot, "node_modules", "@abaplint", "cli", "abaplint"), lintConfigPath]);
    await runNode([path.join(repositoryRoot, "node_modules", "@abaplint", "transpiler-cli", "abap_transpile"), configPath]);
    if (transpile) {
      console.log("generated converter classes passed the open-abap transpiler");
      await checkRenamedSubmitTarget({tempRoot, outputFolder});
    }
    if (behavior) await runNode([path.join(repositoryRoot, "converter", "test", "behavioral-generated.mjs"), "--check", outputFolder]);

    await fs.rm(tempRoot, {recursive: true, force: true});
    await fs.rm(lintConfigPath, {force: true});
    await fs.rm(toolTempRoot, {recursive: true, force: true});
  } catch (error) {
    console.error(`validation artifacts retained in ${tempRoot}`);
    throw error;
  }
}
