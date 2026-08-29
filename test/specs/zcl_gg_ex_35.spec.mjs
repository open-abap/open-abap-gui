import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_35 — executes value-request handling`, async ({page, host}) => {
  await openExample(page, host, 35);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await dispatch(page, {action: "VALUE_HELP", target: "P_CARR"});
  await expectPageKind(page, "LIST");
  await expect(page.getByRole("button", {name: "Back"})).toBeVisible();
});
