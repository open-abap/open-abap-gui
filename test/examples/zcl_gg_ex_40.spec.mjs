import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_40 — renders a message-class response`, async ({page, host}) => {
  await openExample(page, host, 40);
  await expectPageKind(page, "MESSAGE");
  await expect(page.locator(".gg-message")).toHaveCount(1);
});
