import {test, expect, openExample, submit} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_115 — each screen sets its own status and title", async ({page, host}) => {
  await openExample(page, host, 115);
  await expect(page.getByRole("heading", {name: "Flights", exact: true})).toBeVisible();
  await expect(page.locator('.wb-toolbar [data-ucomm="DETAIL"]')).toBeEnabled();
  await expect(page.locator('.wb-commandbar button[title="Save"]')).toBeDisabled();

  await submit(page, "Details");
  await expect(page.getByRole("heading", {name: "Flight 0400"})).toBeVisible();
  await expect(page.locator('.wb-toolbar [data-ucomm="DETAIL"]')).toHaveCount(0);
  await expect(page.locator('.wb-commandbar button[title="Save"]')).toBeEnabled();

  await page.locator('[name="GV_SEATS"]').fill("150");
  await page.locator(".wb-commandbar").getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("load");
  await expect(out(page, "GV_STATE")).toHaveText("Flight 0400 saved with 00150 seats");

  await submit(page, "Back");
  await expect(page.getByRole("heading", {name: "Flights", exact: true})).toBeVisible();
});
