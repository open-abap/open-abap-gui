import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_49 — renders a PF event report`, async ({page, host}) => {
  await openExample(page, host, 49);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("body");
  await dispatch(page, {action: "PF", pf_key: 5});
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["body", "pf5"]);
});
