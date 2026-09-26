import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_161 — renders each chained checkbox parameter on its own line", async ({page, host}) => {
  await openExample(page, host, 161);
  await expectPageKind(page, "SELECTION");
  const clean = page.getByRole("checkbox", {name: "Clean up"});
  const tsave = page.getByRole("checkbox", {name: "Test save"});
  await expect(clean).toBeChecked();
  await expect(tsave).not.toBeChecked();

  const cleanBox = await clean.boundingBox();
  const tsaveBox = await tsave.boundingBox();
  expect(tsaveBox.y).toBeGreaterThanOrEqual(cleanBox.y + cleanBox.height);
  expect(tsaveBox.x).toBe(cleanBox.x);

  await tsave.check();
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["P_CLEAN=X", "P_TSAVE=X"]);
});
