import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_139 — dispatches an ALV toolbar event", async ({page, host}) => {
  await openExample(page, host, 139);
  await page.getByRole("button", {name: "Application toolbar event"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line").last()).toContainText("event delivered");
});

