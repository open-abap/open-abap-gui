import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_042 — preserves DISPLAY LIKE message text`, async ({page, host}) => {
  await openExample(page, host, 42);
  await expectPageKind(page, "MESSAGE");
  await expect(page.locator(".gg-error")).toHaveText("looks like an error");
});
