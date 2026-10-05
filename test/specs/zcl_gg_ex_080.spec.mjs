import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_080 - runs field, radio, block, and range validation before AT SELECTION-SCREEN", async ({page, host}) => {
  await openExample(page, host, 80);
  await page.locator('[name="P_FLD"]').fill("bad");
  await page.locator('[name="P_REQ"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toContainText("Field validation failed");
  await page.locator('[name="P_FLD"]').fill("good");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(/^FIELD>.*RADIO.*>SCREEN$/);
  await expect(page.locator(".gg-list-line")).toHaveText(/BLOCK/);
  await expect(page.locator(".gg-list-line")).toHaveText(/END/);
});
