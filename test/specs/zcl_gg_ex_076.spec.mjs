import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_076 - derives values and rejects undeclared commands", async ({page, host}) => {
  await openExample(page, host, 76);
  await dispatch(page, {
    action: "SUBMIT",
    ucomm: "FORGED",
    values: [{name: "P_REQ", value: "ok"}],
  });
  await expect(page.getByRole("alert")).toContainText("Undeclared selection command");
  await page.getByRole("button", {name: "Derive"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator('[name="P_DER"]')).toHaveValue("derived by pushbutton");
  await page.locator('[name="P_REQ"]').fill("ok");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("derived by pushbutton");
});
