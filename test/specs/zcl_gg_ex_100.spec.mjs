import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_100 — PBO fills the screen, PAI brings the input back", async ({page, host}) => {
  await openExample(page, host, 100);
  await expect(out(page, "GV_UPPER")).toHaveText("INITIAL");
  await page.locator('[name="GV_INPUT"]').fill("browser input");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Apply"}).click();
  await page.waitForLoadState("load");
  await expect(out(page, "GV_OUTPUT")).toHaveText("accepted: browser input");
  await expect(out(page, "GV_UPPER")).toHaveText("BROWSER INPUT");
});
