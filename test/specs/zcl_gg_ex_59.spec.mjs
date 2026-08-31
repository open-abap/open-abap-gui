import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_59 — renders only the example-owned icon bar", async ({page, host}) => {
  await openExample(page, host, 59);
  await expectPageKind(page, "LIST");
  const toolbar = page.locator(".wb-toolbar");
  await expect(toolbar.getByRole("button")).toHaveCount(2);
  await expect(toolbar.getByRole("button").nth(0)).toHaveAccessibleName("Refresh");
  await expect(toolbar.getByRole("button").nth(1)).toHaveAccessibleName("Print");
  await expect(toolbar.locator(".wb-toolbar-separator")).toHaveCount(1);
  await toolbar.getByRole("button", {name: "Refresh"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "refreshed"]);
});

