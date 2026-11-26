import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_124 — loads and lays out a picture", async ({page, host}) => {
  await openExample(page, host, 124);
  await expect(page.locator('[data-control-kind="PICTURE"]')).toHaveCount(1);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Picture loaded");
  // The host's own icon comes inside the page, so it also shows where no
  // server answers /assets, as in the browser preview.
  const picture = page.locator('[data-control-kind="PICTURE"] img');
  await expect(picture).toHaveAttribute("src", /^data:image\/svg\+xml;base64,/);
  expect(await picture.evaluate((image) => image.complete && image.naturalWidth > 0)).toBe(true);
  await submit(page, "Fit and center");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Fit and centered");
});
