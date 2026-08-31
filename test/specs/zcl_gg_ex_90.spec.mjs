import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_90 — preserves Unicode wide-list text and columns", async ({page, host}) => {
  await openExample(page, host, 90);
  await expect(page.locator(".gg-list")).toContainText("航空");
  await expect(page.locator(".gg-list")).toContainText("مرحبا");
  await expect(page.locator(".gg-list")).toContainText("logical column");
  await expect(page.locator(".gg-list")).toContainText("<wide>");
});

