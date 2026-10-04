import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_136 — checks and saves changed cells", async ({page, host}) => {
  await openExample(page, host, 136);
  const occupied = page.getByLabel("SEATSOCC row 1");
  await expect(occupied).toHaveValue("180");
  await occupied.fill("300");
  await page.getByRole("button", {name: "Save", exact: true}).click();
  await expect(page.locator('[data-control-kind="ALV_GRID"]').getByRole("alert")).toContainText("Flight LH 0400 has 280 seats");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Correct the marked cells first");
  await page.getByLabel("SEATSOCC row 1").fill("200");
  await page.getByRole("button", {name: "Save", exact: true}).click();
  await expect(page.locator('[data-control-kind="ALV_GRID"]').getByRole("alert")).toHaveCount(0);
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Saved, 570 seats occupied");
  await expect(page.getByLabel("SEATSOCC row 1")).toHaveValue("200");
});
