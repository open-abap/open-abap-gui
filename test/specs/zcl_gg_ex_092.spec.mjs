import {test, expect, openExample} from "../fixtures.mjs";

const scrollTop = (page) => page.locator(".gg-work-area").evaluate((area) => area.scrollTop);

test("ZCL_GG_EX_092 — the list processor pages through the list window", async ({page, host}) => {
  await openExample(page, host, 92);
  const toolbar = page.locator(".wb-commandbar");
  const height = await page.locator(".gg-work-area").evaluate((area) => area.clientHeight);
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");

  await toolbar.getByRole("button", {name: "Next page"}).click();
  await expect.poll(() => scrollTop(page)).toBe(height);
  await toolbar.getByRole("button", {name: "Next page"}).click();
  await expect.poll(() => scrollTop(page)).toBe(2 * height);
  await toolbar.getByRole("button", {name: "Previous page"}).click();
  await expect.poll(() => scrollTop(page)).toBe(height);
  await toolbar.getByRole("button", {name: "Last page"}).click();
  await expect(page.locator(".gg-list-line").last()).toBeInViewport();
  await toolbar.getByRole("button", {name: "First page"}).click();
  await expect.poll(() => scrollTop(page)).toBe(0);

  // Paging never ran the program again.
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-id", pageId);
  await expect(page.locator(".gg-list-page")).toHaveCount(5);
});
