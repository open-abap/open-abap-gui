import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_68 — toggles dependent visible/input/required state", async ({page, host}) => {
  await openExample(page, host, 68);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_DETAIL"]')).toBeHidden();
  await page.locator('[name="P_REQUIRED"]').fill("ready");
  await page.locator('input[type="checkbox"][name="P_SHOW"]').check();
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_SHOW", value: "X"},
      {name: "P_REQUIRED", value: "ready"},
    ],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_DETAIL"]')).toBeVisible();
  await expect(page.locator('[name="P_DETAIL"]')).toHaveAttribute("required", "");
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_SHOW", value: "X"},
      {name: "P_REQUIRED", value: "ready"},
    ],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("P_DETAIL");
  await page.locator('[name="P_DETAIL"]').fill("shown");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["ready", "shown"]);
});
