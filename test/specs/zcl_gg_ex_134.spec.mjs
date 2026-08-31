import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_134 — combines tree, editor, and viewer controls", async ({page, host}) => {
  await openExample(page, host, 134);
  await expect(page.getByRole("tree")).toBeVisible();
  await expect(page.locator("textarea")).toHaveValue("Document editor");
  await expect(page.getByTitle("HTML viewer")).toHaveAttribute("srcdoc", /Document viewer/);
});

