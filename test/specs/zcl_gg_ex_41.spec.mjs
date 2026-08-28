import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_41 — renders an abort message`, async ({page, host}) => {
  await openExample(page, host, 41);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("giving up");
});
