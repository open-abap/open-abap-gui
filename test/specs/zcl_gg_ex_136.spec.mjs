import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_136 — accepts editable ALV data", async ({page, host}) => {
  await openExample(page, host, 136);
  await expect(page.getByLabel("Seats for LH400")).toHaveValue("180");
  await page.getByRole("button", {name: "Save changed data"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line").last()).toContainText("changed data accepted");
});

