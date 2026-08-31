import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_114 — renders error and warning message semantics", async ({page, host}) => {
  await openExample(page, host, 114);
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Action", exact: true}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.getByRole("alert")).toContainText("Enter a message value");
  await page.locator('[name="P_MESSAGE"]').fill("ready");
  await page.locator('[data-screen="0100"]').getByRole("button", {name: "Action", exact: true}).click();
  await page.waitForLoadState("networkidle");
  await expect(page.locator(".gg-warning")).toContainText("Warning accepted");
});

