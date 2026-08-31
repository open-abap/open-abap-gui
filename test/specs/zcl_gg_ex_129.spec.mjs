import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_129 — composes a safe dynamic document", async ({page, host}) => {
  await openExample(page, host, 129);
  const document = page.getByRole("article", {name: "Dynamic document"});
  await expect(document.getByRole("heading", {name: "Dynamic & safe document"})).toBeVisible();
  await expect(document.getByRole("link", {name: "Open document"})).toHaveAttribute("href", "/safe/document");
  await expect(document.getByRole("table")).toContainText("Draft");
});

