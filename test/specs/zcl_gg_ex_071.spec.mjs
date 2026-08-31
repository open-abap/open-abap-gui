import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_071 - refreshes dependent listbox choices", async ({page, host}) => {
  await openExample(page, host, 71);
  await dispatch(page, {
    action: "SUBMIT",
    values: [
      {name: "P_CARRIER", value: "LH"},
      {name: "P_CONNECTION", value: ""},
      {name: "P_REQUIRED", value: "ok"},
    ],
  });
  await expect(page.getByRole("alert")).toContainText("P_CONNECTION");
  await expect(page.locator('[name="P_CONNECTION"] option')).toHaveText(["LH-1", "LH-2"]);
  await page.locator('[name="P_CONNECTION"]').selectOption("LH-1");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["LH", "LH-1"]);
});
