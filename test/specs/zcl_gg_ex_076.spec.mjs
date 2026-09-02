import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_076 - derives values and rejects undeclared commands", async ({page, host}) => {
  await openExample(page, host, 76);
  await dispatch(page, {
    action: "SUBMIT",
    ucomm: "FORGED",
    values: [{name: "P_REQUIRED", value: "ok"}],
  });
  await expect(page.getByRole("alert")).toContainText("Undeclared selection command");
  await page.getByRole("button", {name: "Derive"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[name="P_DERIVED"]')).toHaveValue("derived by pushbutton");
  await page.locator('[name="P_REQUIRED"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
});
