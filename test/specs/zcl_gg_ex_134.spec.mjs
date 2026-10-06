import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_134 — shows the editor text in the viewer", async ({page, host}) => {
  await openExample(page, host, 134);
  await expect(page.locator("textarea")).toHaveValue("Document text");
  await expect(page.frameLocator('iframe[title="HTML viewer"]').locator("p")).toHaveText("Document text");
});

test("edited text is transported to the viewer", async ({page, host}) => {
  await openExample(page, host, 134);
  await page.getByRole("textbox", {name: "Text editor", exact: true}).fill("Edited <text> & content");
  await submit(page, "Show in viewer");
  await expect(page.frameLocator('iframe[title="HTML viewer"]').locator("p")).toHaveText("Edited <text> & content");
});
