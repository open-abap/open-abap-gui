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
    await expect(page.locator(".wb-toolbar")).toHaveCount(0);
    await expect(page.locator(".wb-statusbar")).toBeVisible();
    const expectedTitle = {
      "/ZCL_GG_INTEGRATION_HTML_REPORT": "Selection",
      "/ZCL_GG_INTEGRATION_DYNPRO": "Flight input",
      "/ZCL_GG_DB_HELPER": "ZCL_GG_DB_HELPER",
    }[route];
    await expect(page.locator(".wb-app-title")).toHaveText(expectedTitle);
  });

  test(`Standard toolbar is disabled apart from back for ${route}`, async ({page, host}) => {
    await page.goto(`${host.baseUrl}${route}`);

    const commandButtons = page.locator(".wb-commandbar").getByRole("button");
    await expect(commandButtons).toHaveCount(11);
    for (const index of [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
      await expect(commandButtons.nth(index)).toBeDisabled();
    }
    const back = page.getByRole("button", {name: "Return to workbench"});
    await expect(back).toBeEnabled();

    await back.click();
    await page.waitForLoadState("networkidle");
    await expect(page.getByRole("navigation", {name: "Applications"})).toBeVisible();
    await expect(page.locator("[data-page-kind]")).toHaveCount(0);
  });
}

test("direct compatibility routes reject classes outside the allow-list", async ({request, host}) => {
  const response = await request.get(`${host.baseUrl}/ZCL_GG_TRANSACTION_REGISTRY`);

  expect(response.status()).toBe(404);
  expect(await response.json()).toEqual({valid: false, error: "Not found"});
});

for (const tcode of ["SE01", "SE09", "SE11", "SE16", "SE38"]) {
  test(`${tcode} uses the shared transaction chrome`, async ({page, host}) => {
    const response = await page.goto(`${host.baseUrl}/transaction?tcode=${tcode}`);

    expect(response?.status()).toBe(200);
    await expect(page.locator(".wb-brand")).toHaveText("open-abap");
    await expect(page.getByRole("menuitem", {name: "Applications"})).toBeVisible();
    await expect(page.locator(".wb-appbar")).toBeVisible();
    await expect(page.locator(".wb-appbar--dynpro")).toHaveCount(0);
    await expect(page.locator(".wb-app-title")).toHaveAttribute("class", "wb-app-title");
    await expect(page.locator(".wb-app-title")).not.toHaveAttribute("style", /.+/);
  });
}
