import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_86 — MODIFY LINE keeps both fragments and hidden row identity", async ({page, host}) => {
  await openExample(page, host, 86);
  await submit(page, "Modify lines");
  await expect(page.locator(".gg-list-line")).toHaveCount(2);
  await expect(page.locator(".gg-list-line").nth(0).locator(".gg-list-fragment")).toHaveCount(2);
  await expect(page.locator(".gg-list-line").nth(0)).toHaveClass(/gg-list-line/);
  await expect(page.locator("[data-action-token]")).toHaveCount(2);
});

