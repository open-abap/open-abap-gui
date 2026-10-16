import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_012 — applies INITIALIZATION values`, async ({page, host}) => {
  await openExample(page, host, 12);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_DATE"]')).toHaveAttribute("data-abap-value", "20260101");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(1);
  // DATE = USER uses the Node host's locale, as in example 067.
  const expectedDate = new Intl.DateTimeFormat("default", {
    day: "2-digit", month: "2-digit", year: "numeric",
  }).format(new Date(2026, 0, 1));
  await expect(page.locator(".gg-list-line")).toHaveText([expectedDate]);
});
