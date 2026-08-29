import {test, expect} from "../fixtures.mjs";

for (const route of [
  "/ZCL_GG_INTEGRATION_HTML_REPORT",
  "/ZCL_GG_INTEGRATION_DYNPRO",
  "/ZCL_GG_DB_HELPER",
]) {
  test(`HTTP handler renders shared shell for ${route}`, async ({page, host}) => {
    const response = await page.goto(`${host.baseUrl}${route}`);

    expect(response?.status()).toBe(200);
    await expect(page.getByRole("menubar", {name: "Main menu"})).toBeVisible();
    await expect(page.locator(".wb-commandbar")).toBeVisible();
    await expect(page.locator(".wb-appbar")).toBeVisible();
    await expect(page.locator(".wb-toolbar")).toBeVisible();
    await expect(page.locator(".wb-statusbar")).toBeVisible();
    const expectedTitle = {
      "/ZCL_GG_INTEGRATION_HTML_REPORT": "Selection",
      "/ZCL_GG_INTEGRATION_DYNPRO": "Flight input",
      "/ZCL_GG_DB_HELPER": "ZCL_GG_DB_HELPER",
    }[route];
    await expect(page.locator(".wb-app-title")).toHaveText(expectedTitle);
  });
}
