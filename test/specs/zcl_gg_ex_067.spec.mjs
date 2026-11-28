import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_067 — renders typed parameter definitions and values", async ({page, host}) => {
  await openExample(page, host, 67);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_DATE"]')).toHaveValue("30.08.2026");
  await expect(page.locator('[name="P_TIME"]')).toHaveValue("12:34:56");
  for (const name of ["P_DATE", "P_TIME"]) {
    const font = await page.locator(`[name="${name}"]`).evaluate((field) => getComputedStyle(field).fontFamily);
    expect(font).toMatch(/monospace/);
  }
  await expect(page.locator('[name="P_INT"]')).toHaveValue("42");
  await expect(page.locator('[name="P_DEC"]')).toHaveValue("123.45");
  await expect(page.locator('[name="P_CHAR"]')).toHaveAttribute("required", "");
  await page.locator('[name="P_CHAR"]').fill("typed value ");
  await submit(page);
  await expectPageKind(page, "LIST");
  // DATE = USER uses the Node host's locale; the host inherits our environment.
  const expectedDate = new Intl.DateTimeFormat("default", {
    day: "2-digit", month: "2-digit", year: "numeric",
  }).format(new Date(2026, 7, 30));
  await expect(page.locator(".gg-list-line")).toHaveText([
    expectedDate,
    "12:34:56",
    "42",
    "123.45",
    "typed value ",
  ]);
});

test("ZCL_GG_EX_067 — rejects input a numeric parameter cannot hold and keeps the screen", async ({page, host}) => {
  await openExample(page, host, 67);
  await page.locator('[name="P_CHAR"]').fill("typed value");
  await page.locator('[name="P_INT"]').fill("abc");
  const [response] = await Promise.all([
    page.waitForResponse((candidate) => candidate.request().method() === "POST"),
    submit(page),
  ]);
  expect(response.status()).toBe(200);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toHaveText("P_INT is a numeric field and only accepts a number.");
  await expect(page.locator('[name="P_INT"]')).toHaveValue("abc");
  await expect(page.locator('[name="P_CHAR"]')).toHaveValue("typed value");

  await page.locator('[name="P_INT"]').fill("7");
  await page.locator('[name="P_DEC"]').fill("1,5x");
  await submit(page);
  await expectPageKind(page, "SELECTION");
  await expect(page.getByRole("alert")).toHaveText("P_DEC is a numeric field and only accepts a number.");
  await expect(page.locator('[name="P_DEC"]')).toHaveValue("1,5x");

  await page.locator('[name="P_DEC"]').fill("1.5");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line").nth(2)).toHaveText("7");
  await expect(page.locator(".gg-list-line").nth(3)).toHaveText("1.50");
});
