import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_131 — hosts an editor, a picture and a toolbar in one splitter", async ({page, host}) => {
  await openExample(page, host, 131);
  await expect(page.locator("textarea")).toHaveValue("Editor in cell 1");
  await expect(page.locator('[data-control-kind="PICTURE"]')).toHaveCount(1);
  await expect(page.getByRole("button", {name: "Apply"})).toBeVisible();
});
