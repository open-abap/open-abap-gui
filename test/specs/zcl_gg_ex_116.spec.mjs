import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_116 — enters the flight row editor and saves", async ({page, host}) => {
  await openExample(page, host, 116);
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Edit rows", exact: true}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.locator('[data-table-control] tbody tr')).toHaveCount(2);
  await page.locator('[data-screen="0200"]').getByRole("button", {name: "Save", exact: true}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.getByRole("alert")).toContainText("Flight saved");
});

