import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_42 — preserves DISPLAY LIKE message text`, async ({page, host}) => {
  await openExample(page, host, 42);
  await expectPageKind(page, "MESSAGE");
  await expect(page.getByRole("alert")).toContainText("looks like an error");
});
