import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_075 - writes the general and detail values", async ({page, host}) => {
  await openExample(page, host, 75);
  await expectPageKind(page, "SELECTION");
  await page.locator('[name="P_GEN"]').fill("general");
  await page.locator('[name="P_DET"]').fill("details");
  await page.locator('[name="P_REQ"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["general", "details"]);
});
