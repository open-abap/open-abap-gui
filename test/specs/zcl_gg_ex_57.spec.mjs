import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_57 — renders terminal LEAVE PROGRAM navigation`, async ({page, host}) => {
  await openExample(page, host, 57);
  await expectPageKind(page, "TERMINAL");
  await expect(page.locator(".gg-terminal")).toContainText("LEAVE PROGRAM");
  await expect(page.locator("form")).toHaveCount(0);
});
