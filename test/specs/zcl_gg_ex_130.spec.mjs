import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_130 — renders a document with an event link", async ({page, host}) => {
  await openExample(page, host, 130);
  await expect(page.locator("body")).toContainText("Document events");
  await expect(page.getByRole("link", {name: "Open document"})).toBeVisible();
});
