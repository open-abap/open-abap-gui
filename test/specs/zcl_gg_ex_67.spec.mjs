import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_67 — renders typed parameter definitions and values", async ({page, host}) => {
  await openExample(page, host, 67);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_DATE"]')).toHaveValue("20260830");
  await expect(page.locator('[name="P_TIME"]')).toHaveValue("123456");
  await expect(page.locator('[name="P_INT"]')).toHaveValue("42");
  await expect(page.locator('[name="P_DEC"]')).toHaveValue("123.45");
  await expect(page.locator('[name="P_CHAR"]')).toHaveAttribute("required", "");
  await page.locator('[name="P_CHAR"]').fill("typed value");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText([
    "20260830",
    "123456",
    "42",
    "123.45",
    "typed value",
  ]);
});
