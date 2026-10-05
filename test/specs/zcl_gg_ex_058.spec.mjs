import {test, expect, openExample, submit, expectPageKind, expectWorkbench} from "../fixtures.mjs";

const back = async (page) => {
  await page.locator(".wb-commandbar").getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
};

test("ZCL_GG_EX_058 — the module pool's transaction starts screen 100", async ({page, host}) => {
  await openExample(page, host, 58);
  await expectPageKind(page, "DYNPRO");
  await expect(page.locator(".wb-app-title")).toHaveText("Order 4711");
  await expect(page.locator('[data-screen="0100"]')).toContainText("Order 4711, Frankfurt to New York");

  // SET SCREEN 200 and LEAVE SCREEN go to the details.
  await submit(page, "Details");
  await expect(page.locator('[data-screen="0200"]')).toContainText("Two seats, economy class");

  await back(page);
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  // LEAVE TO SCREEN 0 on screen 100 ends the transaction.
  await back(page);
  await expectWorkbench(page);
});
