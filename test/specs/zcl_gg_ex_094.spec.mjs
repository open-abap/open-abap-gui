import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_094 — print view is a separate representation", async ({page, host}) => {
  await openExample(page, host, 94);
  await submit(page, "Print view");
  await expect(page.locator(".gg-list-line").last()).toContainText("PRINT VIEW");
});
