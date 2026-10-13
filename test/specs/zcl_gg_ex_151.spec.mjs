import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

const viewer = (page) => page.frameLocator('iframe[title="HTML viewer"]');

test("ZCL_GG_EX_151 — shows the program's HTML in the viewer", async ({page, host}) => {
  await openExample(page, host, 151);
  await expectPageKind(page, "DYNPRO");
  await expect(viewer(page).locator("h1")).toHaveText("Flights");
  await expect(viewer(page).locator("tr")).toHaveCount(4);
  // Forms are needed for the sapevent anchors, scripts never run.
  await expect(page.locator('iframe[title="HTML viewer"]')).toHaveAttribute(
    "sandbox", "allow-forms allow-top-navigation-by-user-activation");
});

test("ZCL_GG_EX_151 — a SAPEVENT link raises sapevent with action and getdata", async ({page, host}) => {
  await openExample(page, host, 151);
  await viewer(page).getByRole("button", {name: "UA 0941"}).click();
  await page.waitForLoadState("load");
  await expect(viewer(page).locator("h1")).toHaveText("Flight UA 0941");
  await expect(viewer(page).locator("p").first()).toHaveText("Frankfurt to San Francisco, 210 seats occupied.");

  await viewer(page).getByRole("button", {name: "Back to the flights"}).click();
  await page.waitForLoadState("load");
  await expect(viewer(page).locator("h1")).toHaveText("Flights");
});

test("ZCL_GG_EX_151 — a SAPEVENT form raises sapevent with its fields as postdata", async ({page, host}) => {
  await openExample(page, host, 151);
  await viewer(page).getByRole("button", {name: "UA 0941"}).click();
  await page.waitForLoadState("load");
  const seats = () => viewer(page).locator("p").first();

  // The form's own action.
  await viewer(page).getByLabel("Seats").fill("5");
  await viewer(page).getByRole("button", {name: "Book"}).click();
  await page.waitForLoadState("load");
  await expect(seats()).toHaveText("Frankfurt to San Francisco, 215 seats occupied.");

  // A submit button's formaction overrides the form's action.
  await viewer(page).getByLabel("Seats").fill("3");
  await viewer(page).getByRole("button", {name: "Release"}).click();
  await page.waitForLoadState("load");
  await expect(seats()).toHaveText("Frankfurt to San Francisco, 212 seats occupied.");
});
