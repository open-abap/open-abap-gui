import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_39 — renders a free-text message`, async ({page, host}) => {
  await openExample(page, host, 39);
  await expectPageKind(page, "MESSAGE");
  await expect(page.getByRole("alert")).toContainText("free text");
});
