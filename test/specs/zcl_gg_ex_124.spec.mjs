import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_124 — renders a safe picture source", async ({page, host}) => {
  await openExample(page, host, 124);
  const image = page.locator('[data-control-kind="PICTURE"] img');
  await expect(image).toHaveAttribute("src", "/assets/icons/refresh.svg");
  await expect(image).toHaveAttribute("alt", "Refresh icon fixture");
  await expect(page.getByRole("article", {name: "Picture control state"})).toContainText("State: loaded");
  await page.getByRole("article", {name: "Picture control state"}).getByRole("button", {name: "Fit and center"}).first().click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-control-kind="PICTURE"]')).toHaveAttribute("data-display-mode", "4");
  await expect.poll(() => image.evaluate((element) => element.naturalWidth)).toBeGreaterThan(0);
});

