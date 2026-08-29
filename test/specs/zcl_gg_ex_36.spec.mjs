import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_36 — executes help-request handling`, async ({page, host}) => {
  await openExample(page, host, 36);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await dispatch(page, {action: "HELP", target: "P_CARR"});
  await expectPageKind(page, "LIST");
  await expect(page.getByRole("button", {name: "Back"})).toBeVisible();
});
