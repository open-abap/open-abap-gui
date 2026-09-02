import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_093 — find and find-next announce deterministic matches", async ({page, host}) => {
  await openExample(page, host, 93);
  await page.locator(".wb-toolbar").getByRole("button", {name: "Find", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toHaveText("Found LH at row 1");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Find next", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toHaveText("Found LH at row 2");
});
