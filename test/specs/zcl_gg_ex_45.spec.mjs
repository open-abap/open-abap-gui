import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_45 — renders the SET TITLEBAR title`, async ({page, host}) => {
  await openExample(page, host, 45);
  await expectPageKind(page, "LIST");
  await expect(page.getByRole("heading", {name: "MAIN"})).toBeVisible();
  await expect(page.locator(".gg-list-line")).toHaveText("body");
});
