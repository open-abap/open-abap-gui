import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_112 — distinguishes scheduled and immediate screen transfer", async ({page, host}) => {
  await openExample(page, host, 112);
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Set next", exact: true}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await dispatch(page, {action: "SUBMIT", ucomm: "JUMP"});
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
});

