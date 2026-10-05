import {test, expect, openExample, submit, expectPageKind, expectFramesClearOfTheirTitles} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_099 — renders the basic dynpro controls", async ({page, host}) => {
  await openExample(page, host, 99);
  await expectPageKind(page, "DYNPRO");
  await expect(page.getByRole("group", {name: "All basic dynpro controls"})).toBeVisible();
  await expect(page.locator('[name="GV_INPUT"]')).toHaveValue("input");
  await expect(out(page, "GV_OUTPUT")).toHaveText("output");
  await expect(page.getByLabel("Enabled")).toBeChecked();
  await expect(page.getByLabel("Alpha", {exact: true})).toBeChecked();
  await expect(page.locator('[name="GV_LIST"] option')).toHaveText(["Alpha", "Beta"]);
  await expectFramesClearOfTheirTitles(page);
});

test("ZCL_GG_EX_099 — PAI reads every control back", async ({page, host}) => {
  await openExample(page, host, 99);
  await page.locator('[name="GV_INPUT"]').fill("typed");
  await page.getByLabel("Enabled").uncheck();
  await page.getByLabel("Beta", {exact: true}).check();
  await page.locator('[name="GV_LIST"]').selectOption("B");
  await submit(page, "Apply");
  await expect(out(page, "GV_OUTPUT")).toHaveText("typed, unchecked, Beta, B");
  await expect(page.getByLabel("Beta", {exact: true})).toBeChecked();
});
