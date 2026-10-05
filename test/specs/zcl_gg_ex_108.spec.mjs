import {test, expect, openExample, submit} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_108 — CALL SUBSCREEN shows one of two screens in the area", async ({page, host}) => {
  await openExample(page, host, 108);
  await expect(page.getByRole("region", {name: "Subscreen area SUB_DETAIL"})).toHaveCount(1);
  await expect(page.locator('[name="GV_CITY"]')).toHaveValue("London");
  await expect(page.locator('[name="GV_PHONE"]')).toHaveCount(0);

  await submit(page, "Contact");
  await expect(page.locator('[name="GV_CITY"]')).toHaveCount(0);
  await page.locator('[name="GV_PHONE"]').fill("555-1234");
  await submit(page, "Address");
  // The contact subscreen's field went through PAI and kept its value.
  await expect(out(page, "GV_SUMMARY")).toHaveText("Ada Lovelace, London, 555-1234");
  await expect(page.locator('[name="GV_CITY"]')).toHaveValue("London");
});
