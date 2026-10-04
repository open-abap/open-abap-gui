import {test, expect, openExample, submit} from "../fixtures.mjs";

const seconds = async (page) =>
  Number((await page.locator("#gg-dynpro-control-n-GV_SECONDS").textContent()).trim());
const state = (page) => page.locator("#gg-dynpro-control-n-GV_STATE");

test("ZCL_GG_EX_152 — the timer raises FINISHED every second while it runs", async ({page, host}) => {
  await openExample(page, host, 152);
  await expect(state(page)).toHaveText("Timer stopped");
  await expect(page.locator('[data-control-kind="TIMER"]')).toHaveAttribute("data-running", "false");

  await submit(page, "Start");
  await expect(state(page)).toHaveText("Timer running");
  await expect(page.locator('[data-control-kind="TIMER"]')).toHaveAttribute("data-interval", "1");
  await expect.poll(() => seconds(page), {timeout: 10_000}).toBeGreaterThanOrEqual(2);

  // A click that meets the timer's own round trip is dropped, as the page is
  // already being replaced; the user clicks again.
  await expect(async () => {
    await submit(page, "Stop");
    await expect(state(page)).toHaveText("Timer stopped", {timeout: 500});
  }).toPass({timeout: 10_000});
  await expect(page.locator('[data-control-kind="TIMER"]')).toHaveAttribute("data-running", "false");
  const stopped = await seconds(page);
  await page.waitForTimeout(1_500);
  expect(await seconds(page)).toBe(stopped);

  await submit(page, "Reset");
  expect(await seconds(page)).toBe(0);
});
