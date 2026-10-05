import {test, expect, openExample} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_109 — a tab sets the active tab and the subscreen it shows", async ({page, host}) => {
  await openExample(page, host, 109);
  await expect(page.getByRole("tab", {name: "Route"})).toHaveAttribute("aria-selected", "true");
  await expect(page.locator('[name="GV_FROM"]')).toHaveValue("Frankfurt");

  await page.getByRole("tab", {name: "Plane"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("tab", {name: "Plane"})).toHaveAttribute("aria-selected", "true");
  await expect(out(page, "GV_ACTIVE")).toHaveText("TAB_PLANE");
  await expect(page.locator('[name="GV_PLANE"]')).toHaveValue("A340-600");
  await expect(page.locator('[name="GV_FROM"]')).toHaveCount(0);
});
