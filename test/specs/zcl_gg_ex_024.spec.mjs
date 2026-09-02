import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_024 — executes a selection pushbutton report`, async ({page, host}) => {
  await openExample(page, host, 24);
  await expectPageKind(page, "SELECTION");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
});
