import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_064 — exposes title, cursor, status, and action feedback", async ({page, host}) => {
  await openExample(page, host, 64);
  await expectPageKind(page, "DYNPRO");
  await expect(page.getByRole("heading", {name: "Feedback 64 - next action"})).toBeVisible();
  // The SHELL64 status is never named on the page; it shows up as the command it activates.
  await expect(page.locator('.wb-toolbar [data-ucomm="NEXT64"]')).toBeEnabled();
  await expect(page.locator('.gg-dynpro[data-cursor-field="P_ACTION"]')).toHaveCount(1);
  await page.locator('[name="P_ACTION"]').fill("go");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Next action"}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[name="P_ACTION"]')).toHaveValue("accepted");
});
