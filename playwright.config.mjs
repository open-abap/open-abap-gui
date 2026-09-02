import {defineConfig} from "playwright/test";

export default defineConfig({
  testDir: "./test",
  testMatch: "**/*.spec.mjs",
  // Spec files run in parallel, tests inside one file stay ordered. Each worker
  // owns its own ABAP host on its own port, so workers never share server state.
  fullyParallel: false,
  workers: "50%",
  reporter: "list",
});
