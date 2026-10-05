import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_094 — Print is the list processor's, Total the program's", async ({page, host}) => {
  await page.addInitScript(() => {
    window.print = () => { window.__printed = (window.__printed ?? 0) + 1; };
  });
  await openExample(page, host, 94);
  const lines = page.locator(".gg-list-line");
  await expect(lines).toHaveCount(5);

  await page.locator(".wb-commandbar").getByRole("button", {name: "Print"}).click();
  await expect.poll(() => page.evaluate(() => window.__printed)).toBe(1);
  await expect(lines).toHaveCount(5);

  await submit(page, "Total");
  await expect(lines.last()).toContainText("Seats booked");
  await expect(lines.last()).toContainText("6");
});
