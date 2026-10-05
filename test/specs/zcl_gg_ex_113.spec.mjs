import {test, expect, openExample, submit, expectWorkbench} from "../fixtures.mjs";

const out = (page, name) => page.locator(`#gg-dynpro-control-n-${name}`);

test("ZCL_GG_EX_113 — Back needs the required field, as any normal function", async ({page, host}) => {
  await openExample(page, host, 113);
  await submit(page, "Back");
  await expect(page.getByRole("alert")).toContainText("Fill in all required entry fields");
  await expect(page.locator('[data-screen="0100"]')).toHaveAttribute("data-cursor-field", "GV_CUSTOMER");
  await expect(page.locator('[name="GV_CUSTOMER"]')).toBeEditable();
});

test("ZCL_GG_EX_113 — Save runs PAI with the field filled", async ({page, host}) => {
  await openExample(page, host, 113);
  await page.locator('[name="GV_CUSTOMER"]').fill("Ada");
  await page.locator(".wb-commandbar").getByRole("button", {name: "Save"}).click();
  await page.waitForLoadState("load");
  await expect(out(page, "GV_STATE")).toHaveText("Booked for Ada");
  await submit(page, "Back");
  await expectWorkbench(page);
});

for (const name of ["Cancel", "Exit"]) {
  test(`ZCL_GG_EX_113 — ${name} is of type E and leaves with the field empty`, async ({page, host}) => {
    await openExample(page, host, 113);
    await submit(page, name);
    await expectWorkbench(page);
  });
}
