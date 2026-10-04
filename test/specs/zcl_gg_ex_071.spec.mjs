import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_071 - refreshes dependent listbox choices", async ({page, host}) => {
  await openExample(page, host, 71);
  await expect(page.locator('[name="P_CON"] option')).toHaveText(["", "AA-1", "AA-2"]);
  await Promise.all([
    page.waitForNavigation({waitUntil: "load"}),
    page.locator('[name="P_CAR"]').selectOption("LH"),
  ]);
  // The carrier change clears P_CON; the empty value stays selected as a blank
  // entry ahead of the refreshed choices.
  await expect(page.locator('[name="P_CON"] option')).toHaveText(["", "LH-1", "LH-2"]);
  await expect(page.locator('[name="P_CON"]')).toHaveValue("");
  await page.locator('[name="P_CON"]').selectOption("LH-1");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["LH", "LH-1"]);
});
