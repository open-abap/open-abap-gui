import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_041 — renders an abort message`, async ({page, host}) => {
  await openExample(page, host, 41);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator(".gg-error")).toHaveText("giving up");
});
