import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_146 — renders SALV header and layout", async ({page, host}) => {
  await openExample(page, host, 146);
  await expect(page.locator(".gg-salv-layout header")).toContainText("Flight capacity report");
  await expect(page.locator(".gg-salv-grid")).toContainText("2026-08-30");
});

