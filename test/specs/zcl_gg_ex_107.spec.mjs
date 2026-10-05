import {test, expect, openExample} from "../fixtures.mjs";

const firstFlight = (page) => page.locator("[data-table-control] tbody tr").first();
const topLine = (page) => page.locator("#gg-dynpro-control-n-GV_TOP_LINE");

test("ZCL_GG_EX_107 — the table control's scroll bar moves TOP_LINE", async ({page, host}) => {
  await openExample(page, host, 107);
  await expect(topLine(page)).toHaveText("1");
  await expect(firstFlight(page)).toContainText("0401");
  const scroll = page.getByRole("group", {name: "Scroll TC_FLIGHTS"});
  await expect(scroll.getByRole("button", {name: "First lines"})).toBeDisabled();

  await scroll.getByRole("button", {name: "Next lines"}).click();
  await page.waitForLoadState("load");
  await expect(topLine(page)).toHaveText("6");
  await expect(firstFlight(page)).toContainText("0406");
});

test("ZCL_GG_EX_107 — the page functions page by sy-loopc lines", async ({page, host}) => {
  await openExample(page, host, 107);
  await page.getByRole("button", {name: "Next page"}).click();
  await page.waitForLoadState("load");
  await expect(topLine(page)).toHaveText("6");
  await page.getByRole("button", {name: "Last page"}).click();
  await page.waitForLoadState("load");
  await expect(topLine(page)).toHaveText("8");
  await expect(firstFlight(page)).toContainText("0408");
  await page.getByRole("button", {name: "First page"}).click();
  await page.waitForLoadState("load");
  await expect(topLine(page)).toHaveText("1");
});
