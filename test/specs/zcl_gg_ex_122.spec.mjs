import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_122 — keeps multiline editor text intact", async ({page, host}) => {
  await openExample(page, host, 122);
  const editor = page.locator("textarea");
  await expect(page.getByRole("toolbar", {name: "Text editor tools"})).toBeVisible();
  const status = page.getByRole("status", {name: "Text editor status"});
  await expect(status).toHaveAttribute("data-modified", "1");
  await expect(status).toContainText("Li 2, Co 1");
  await expect(status).toContainText("Ln 1 - Ln 3 of 3 lines");
  await expect(editor).toHaveAttribute("data-wordwrap-position", "72");
  await expect(editor).toHaveAttribute("data-fixed-font", "1");
  await expect(editor).toHaveAttribute("data-cursor-line", "2");
  await expect(editor).toHaveAttribute("data-protected-from", "1");
  await expect(page.locator("textarea")).toHaveValue("First line\nSecond line\nUnicode: 航空 🚀");
});

test("ZCL_GG_EX_122 - clear and restore stay server-owned", async ({page, host}) => {
  await openExample(page, host, 122);
  const editor = page.locator("textarea");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Clear text"}).click();
  await page.waitForLoadState("load");
  await expect(editor).toHaveValue("");
  await page.locator(".wb-toolbar").getByRole("button", {name: "Restore text"}).click();
  await page.waitForLoadState("load");
  await expect(editor).toHaveValue(/First line/);
  await expect(page.locator(".gg-list-line").last()).toContainText("server-owned stream state");
});

