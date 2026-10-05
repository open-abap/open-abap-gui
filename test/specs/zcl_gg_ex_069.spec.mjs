import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_069 — the checkbox locks and unlocks the field group", async ({page, host}) => {
  await openExample(page, host, 69);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_GRP_A"]')).toBeEditable();
  await page.locator('[name="P_GRP_A"]').fill("saved-a");
  await page.locator('[name="P_GRP_B"]').fill("saved-b");
  await page.locator('[name="P_REQ"]').fill("ready");
  await Promise.all([
    page.waitForNavigation({waitUntil: "load"}),
    page.locator('input[type="checkbox"][name="P_ENABLE"]').uncheck(),
  ]);
  await expect(page.locator('[name="P_GRP_A"]')).not.toBeEditable();
  await expect(page.locator('[name="P_GRP_B"]')).not.toBeEditable();
  await expect(page.locator('[name="P_GRP_A"]')).toHaveValue("saved-a");
  await Promise.all([
    page.waitForNavigation({waitUntil: "load"}),
    page.locator('input[type="checkbox"][name="P_ENABLE"]').check(),
  ]);
  await expect(page.locator('[name="P_GRP_A"]')).toBeEditable();
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["saved-a", "saved-b"]);
});
