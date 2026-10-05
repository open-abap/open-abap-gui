import path from "node:path";

if (process.argv[2] === "--check") {
  if (!process.argv[3]) throw new Error("--check requires a transpiled output folder");
  const {checkBehavior} = await import("./generated-behavior.mjs");
  await checkBehavior(path.resolve(process.argv[3]));
} else {
  const {runGeneratedValidation} = await import("./generated-validation.mjs");
  await runGeneratedValidation({transpile: false, behavior: true});
}
