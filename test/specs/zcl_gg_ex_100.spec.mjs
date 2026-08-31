import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_100 — runs PBO and PAI around edited input", async ({page, host}) => {
  await openExample(page, host, 100);
  await page.locator('[name="P_INPUT"]').fill("browser input");
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Apply", exact: true}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator("output")).toHaveText("accepted: browser input");
});

