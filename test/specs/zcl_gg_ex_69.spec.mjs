import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_69 — retains a disabled field group and rejects forged values", async ({page, host}) => {
  await openExample(page, host, 69);
  await expectPageKind(page, "SELECTION");
  await page.locator('[name="P_GROUP_A"]').fill("saved-a");
  await page.locator('[name="P_GROUP_B"]').fill("saved-b");
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_ENABLE", value: "X"},
      {name: "P_GROUP_A", value: "saved-a"},
      {name: "P_GROUP_B", value: "saved-b"},
    ],
  });
  await expect(page.getByRole("alert")).toContainText("P_REQUIRED");
  await page.locator('input[type="checkbox"][name="P_ENABLE"]').uncheck();
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_ENABLE", value: ""},
      {name: "P_GROUP_A", value: "saved-a"},
      {name: "P_GROUP_B", value: "saved-b"},
    ],
  });
  await expect(page.locator('[name="P_GROUP_A"]')).toBeDisabled();
  await expect(page.locator('[name="P_GROUP_A"]')).toHaveValue("saved-a");

  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_ENABLE", value: ""},
      {name: "P_GROUP_A", value: "forged"},
      {name: "P_GROUP_B", value: "saved-b"},
    ],
  });
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("Disabled Group A");
  await expect(page.locator('[name="P_GROUP_A"]')).toHaveValue("saved-a");

  await page.locator('[name="P_REQUIRED"]').fill("ready");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["saved-a", "saved-b"]);
});
