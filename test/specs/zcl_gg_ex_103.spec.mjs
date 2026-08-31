import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_103 — applies dynamic visibility and required state", async ({page, host}) => {
  await openExample(page, host, 103);
  await expect(page.locator('[name="P_DEP"]')).toBeHidden();
  await dispatch(page, {
    action: "SUBMIT",
    values: [{name: "P_ENABLE", value: "X"}, {name: "P_DEP", value: "retained"}],
  });
  await expect(page.locator('[name="P_DEP"]')).toBeVisible();
  await expect(page.locator('[name="P_DEP"]')).toBeEnabled();
  await expect(page.locator('[name="P_DEP"]')).toHaveAttribute("required", "");
});

