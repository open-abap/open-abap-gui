import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_53 — renders terminal SUBMIT navigation`, async ({page, host}) => {
  await openExample(page, host, 53);
  await expectPageKind(page, "TERMINAL");
  await expect(page.locator(".gg-terminal")).toContainText("SUBMIT ZGG_EX_01");
});
