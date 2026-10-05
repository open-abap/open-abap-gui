import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_020 — one airline, without intervals or multiple selection", async ({page, host}) => {
  await openExample(page, host, 20);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="S_CARR-LOW"]')).toHaveValue("LH");
  // NO INTERVALS hides the upper limit, NO-EXTENSION the multiple selection.
  await expect(page.locator('[name="S_CARR-HIGH"]')).toHaveCount(0);
  await expect(page.getByRole("button", {name: /multiple selection/i})).toHaveCount(0);

  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(2);
  await expect(page.locator(".gg-list-line").first()).toContainText("LH");
  await expect(page.locator(".gg-list-line").first()).toContainText("0400");
});
