import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_91 — emits automatic pages with header and footer events", async ({page, host}) => {
  await openExample(page, host, 91);
  await expect(page.locator(".gg-list-page")).toHaveCount(5);
  await expect(page.locator(".gg-list")).toContainText("header page 1");
  await expect(page.locator(".gg-list")).toContainText("footer page 1");
});

