import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_019 — the listbox offers the domain's fixed values", async ({page, host}) => {
  await openExample(page, host, 19);
  await expectPageKind(page, "SELECTION");
  const mode = page.getByLabel("Mode");
  await expect(mode.locator("option")).toHaveText(["Add", "Delete"]);
  await expect(mode).toHaveValue("A");

  await mode.selectOption("D");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["Mode D: the rows are deleted"]);
});
