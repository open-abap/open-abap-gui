import { ArtifactsRules, Config, Edits, MemoryFile, Registry } from "@abaplint/core";

// Lowering writes each statement on one line. The quick fixes of these
// abaplint rules give a call with several parameters one line per parameter,
// aligned, and drop a chain colon that chains nothing, as the repository's
// lint configuration asks.
const RULES = ["line_break_multiple_parameters", "align_parameters", "unnecessary_chaining", "indentation"];
const MAX_EDITS = 500;

function ruleInstances() {
  return ArtifactsRules.getRules()
    .filter((rule) => RULES.includes(rule.getMetadata().key))
    .map((rule) => {
      rule.setConfig(rule.getConfig());
      return rule;
    });
}

export function applyStyleFixes(source, className) {
  const filename = `${className.toLowerCase()}.clas.abap`;
  const registry = new Registry(Config.getDefault());
  registry.addFile(new MemoryFile(filename, source));
  const rules = ruleInstances();
  for (let count = 0; count < MAX_EDITS; count++) {
    registry.parse();
    const object = registry.getFirstObject();
    const fix = rules
      .flatMap((rule) => {
        rule.initialize(registry);
        return rule.run(object);
      })
      .map((issue) => issue.getDefaultFix())
      .find(Boolean);
    if (!fix) break;
    Edits.applyEditSingle(registry, fix);
  }
  // The line-break fix leaves the blank before the new line behind.
  return (registry.getFileByName(filename)?.getRaw() ?? source).replace(/[ \t]+$/gm, "");
}
