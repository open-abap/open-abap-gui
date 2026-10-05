import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_129 — renders a dynamic document with escaped text", async ({page, host}) => {
  await openExample(page, host, 129);
  await expect(page.locator("body")).toContainText("Dynamic & safe document");
  await expect(page.locator("body")).toContainText("Text with <markup> & attributes stays text.");
  await expect(page.getByRole("link", {name: "Open document"})).toBeVisible();
});
