import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_132 — refreshes control snapshots on the server", async ({page, host}) => {
  await openExample(page, host, 132);
  await page.getByRole("button", {name: "Refresh controls"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toHaveText("control refresh 1");
});

