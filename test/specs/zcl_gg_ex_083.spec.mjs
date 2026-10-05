import {test, expect, openExample} from "../fixtures.mjs";

const lines = (page) => page.locator(".gg-list-line");
const choose = async (page, text) => {
  await page.locator(".gg-list-line", {hasText: text}).getByRole("button").dblclick();
  await page.waitForLoadState("load");
};
const back = async (page) => {
  await page.locator(".wb-commandbar").getByRole("button", {name: "Back", exact: true}).click();
  await page.waitForLoadState("load");
};

test("ZCL_GG_EX_083 — drills down through three list levels and back", async ({page, host}) => {
  await openExample(page, host, 83);
  await expect(lines(page).first()).toHaveText("Airlines");
  await expect(lines(page)).toContainText(["LH Lufthansa", "UA United Airlines"]);

  await choose(page, "LH Lufthansa");
  await expect(lines(page).first()).toHaveText("Flights of LH");
  await expect(page.locator(".gg-list")).not.toContainText("United Airlines");
  await expect(lines(page).filter({hasText: "Frankfurt"})).toHaveCount(2);

  await choose(page, "0400");
  await expect(lines(page).first()).toHaveText("Bookings of LH 0400");
  await expect(page.locator(".gg-list")).toContainText("Ada Lovelace");
  await expect(page.locator(".gg-list")).not.toContainText("Alan Turing");
  // sy-listi and sy-lilli name the list and the line the event came from.
  await expect(lines(page).last()).toHaveText("Chosen in list 1, line 3");

  await back(page);
  await expect(lines(page).first()).toHaveText("Flights of LH");
  await choose(page, "0402");
  await expect(page.locator(".gg-list")).toContainText("Alan Turing");

  await back(page);
  await back(page);
  await expect(lines(page).first()).toHaveText("Airlines");
  await choose(page, "UA United Airlines");
  await expect(lines(page).first()).toHaveText("Flights of UA");
});
