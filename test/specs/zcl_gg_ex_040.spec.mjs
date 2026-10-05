import {test, expect, openExample, submit, expectPageKind, statusMessage} from "../fixtures.mjs";

test(`ZCL_GG_EX_040 — renders a message-class response`, async ({page, host}) => {
  await openExample(page, host, 40);
  await expectPageKind(page, "MESSAGE");
  await expect(statusMessage(page)).toHaveText("alpha beta");
  await expect(page.locator("main")).not.toContainText("alpha beta");
});
