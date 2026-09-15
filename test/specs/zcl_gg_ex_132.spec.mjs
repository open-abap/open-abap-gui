import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_132 — refreshes control snapshots on the server", async ({page, host}) => {
  await openExample(page, host, 132);
  await page.locator('button[name="gg_action"][value="COMMAND:REFRESH"][title="Refresh server control state"]').click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toHaveText("control refresh 1");
});

test("ZCL_GG_EX_132 — keeps control state and deterministic timer ticks server-owned", async ({page, host}) => {
  await openExample(page, host, 132);
  await expect(page.locator('[data-control-kind="TEXTEDIT"]')).toHaveCount(1);
  await expect(page.locator('.gg-control-toolbar')).toHaveCount(1);
  await expect(page.locator(".gg-list-status")).toHaveText("CONTROL FRAMEWORK");

  await page.locator('button[name="gg_action"][value="COMMAND:VISIBLE"]').click();
  await page.waitForLoadState("load");
  await expect(page.locator('textarea[data-control-kind="TEXTEDIT"]')).toBeHidden();

  await page.locator('button[name="gg_action"][value="COMMAND:RUN_TIMER"]').click();
  await page.waitForLoadState("load");
  await page.locator('button[name="gg_action"][value="COMMAND:TICK_TIMER"]').click();
  await page.waitForLoadState("load");
  await expect(page.locator("body")).toContainText("Deterministic timer tick 1");
});

