import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_13 — runs START and END-OF-SELECTION`, async ({page, host}) => {
  await openExample(page, host, 13);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["select", "done"]);
});
