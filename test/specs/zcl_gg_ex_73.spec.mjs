import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_73 - adds, reorders, and removes typed range rows", async ({page, host}) => {
  await openExample(page, host, 73);
  await page.getByRole("button", {name: "Add range"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-range-row")).toHaveCount(2);
  await page.locator('[name="S_MULTI-2-LOW"]').fill("LH");
  await page.getByRole("button", {name: "Move first up"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[name="S_MULTI-1-LOW"]')).toHaveValue("LH");
  await page.getByRole("button", {name: "Remove range"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-range-row")).toHaveCount(1);
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("I EQ LH");
});

