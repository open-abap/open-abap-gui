import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_051 — exposes CALL SELECTION-SCREEN`, async ({page, host}) => {
  await openExample(page, host, 51);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "CALL_SELECTION_SCREEN");
  await expect(page.getByText("Transition target: 0500")).toBeVisible();
  await page.getByRole("button", {name: "Screen 0500"}).click();
  await page.waitForLoadState("networkidle");
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_B"]')).toBeVisible();
  await page.locator('[name="P_B"]').fill("X");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("X");
});
