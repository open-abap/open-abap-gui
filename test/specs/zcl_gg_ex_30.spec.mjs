import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_30 — executes general selection validation`, async ({page, host}) => {
  await openExample(page, host, 30);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await dispatch(page, {
    action: "SUBMIT",
    values: [{name: "P_N", value: "-1"}],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toHaveText("must not be negative");
  await expect(page.locator('[name="P_N"]')).toHaveValue("-1");
});
