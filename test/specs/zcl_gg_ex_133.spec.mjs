import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_133 — rejects an empty editor value", async ({page, host}) => {
  await openExample(page, host, 133);
  await submit(page, "Check");
  await expect(page.getByRole("alert")).toContainText("Editor value is required");
});

test("editor text reaches PAI validation", async ({page, host}) => {
  await openExample(page, host, 133);
  await page.getByRole("textbox", {name: "Text editor", exact: true}).fill("Entered in the browser");
  await submit(page, "Check");
  await expect(page.getByRole("alert").filter({hasText: "Editor value is required"})).toHaveCount(0);
  await expect(page.getByRole("textbox", {name: "Text editor", exact: true})).toHaveValue("Entered in the browser");
});
