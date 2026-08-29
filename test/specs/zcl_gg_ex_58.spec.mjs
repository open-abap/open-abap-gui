import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_58 — round-trips dynpro screen navigation`, async ({page, host}) => {
  await openExample(page, host, 58);
  await expectPageKind(page, "DYNPRO");
  await expect(page.locator(".wb-app-title")).toHaveText("ZCL_GG_EX_58");
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await expect(page.locator('[data-screen="0000"]')).toHaveCount(0);
  await submit(page, "Back");
  await expect(page.locator('[data-screen="0000"]')).toHaveCount(1);
});
