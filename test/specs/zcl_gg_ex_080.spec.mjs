import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_080 - runs field, block, radio, and range validation in order", async ({page, host}) => {
  await openExample(page, host, 80);
  await page.locator('[name="P_FIELD"]').fill("good");
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("FIELD>BLOCK>RADIO>END");
});
