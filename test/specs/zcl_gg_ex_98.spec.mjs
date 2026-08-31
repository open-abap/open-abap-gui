import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_98 — filters, sorts, and refreshes a composite flight list", async ({page, host}) => {
  await openExample(page, host, 98);
  await submit(page, "Filter");
  await expect(page.locator(".gg-list-status")).toHaveText("FILTERED");
  await submit(page, "Sort");
  await expect(page.locator(".gg-list-status")).toHaveText("SORTED");
  await submit(page, "Refresh");
  await expect(page.locator(".gg-list-status")).toHaveText("FLIGHTS");
});

