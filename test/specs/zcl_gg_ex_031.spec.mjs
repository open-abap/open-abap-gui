import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_031 — executes field-level selection validation`, async ({page, host}) => {
  await openExample(page, host, 31);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await dispatch(page, {
    action: "SUBMIT",
    values: [{name: "P_CARR", value: "lh"}],
  });
  await expectPageKind(page, "LIST");
  await expect(page.getByRole("button", {name: "Back"})).toBeVisible();
});
