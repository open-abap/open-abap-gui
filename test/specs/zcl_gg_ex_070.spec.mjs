import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_070 — switches radio-driven blocks and validation", async ({page, host}) => {
  await openExample(page, host, 70);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_ALL_VALUE"]')).toBeVisible();
  await expect(page.locator('[name="P_ONE_VALUE"]')).toBeHidden();
  await page.locator('[name="P_REQUIRED"]').fill("ready");
  await page.locator('[name="gg-radio-G1"][value="P_ONE"]').check();
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_ONE", value: "X"},
      {name: "P_REQUIRED", value: "ready"},
    ],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_ALL_VALUE"]')).toBeHidden();
  await expect(page.locator('[name="P_ONE_VALUE"]')).toBeVisible();
  await expect(page.getByRole("alert")).toContainText("P_ONE_VALUE");
  await page.locator('[name="P_ONE_VALUE"]').fill("one");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("one");
});
