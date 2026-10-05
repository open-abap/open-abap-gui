import {test, expect, openExample, submit} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_111 — nested CALL SCREENs return to their callers in turn", async ({page, host}) => {
  await openExample(page, host, 111);
  await submit(page, "Call screen 200");
  await expect(page.locator('[data-screen="0200"]')).toHaveAttribute("data-modal", "true");
  await submit(page, "Call screen 300");
  await expect(page.locator('[data-screen="0300"]')).toHaveAttribute("data-modal", "true");

  await page.getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await page.getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await expect(out(page, "GV_TRAIL")).toHaveText("100 > 200 > 300 > back in 200 > back in 100");
});
