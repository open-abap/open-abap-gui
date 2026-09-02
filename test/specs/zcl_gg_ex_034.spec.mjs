import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_034 — executes radio-group validation`, async ({page, host}) => {
  await openExample(page, host, 34);
  await expectPageKind(page, "SELECTION");
  await dispatch(page, {
    action: "SUBMIT",
    values: [{name: "P_ONE", value: "X"}],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toHaveText("key required for single mode");
  await expect(page.locator('[data-abap-name="P_ONE"]')).toBeChecked();
});
