import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_146 — frames a SALV list with a header and a footer", async ({page, host}) => {
  await openExample(page, host, 146);
  await expect(page.locator(".gg-salv-top-of-list")).toContainText("Flight capacity report");
  await expect(page.locator(".gg-salv-top-of-list")).toContainText("Occupied seats:");
  await expect(page.locator(".gg-salv-top-of-list")).toContainText("550");
  await expect(page.locator(".gg-salv-end-of-list")).toHaveText("End of report");
});
