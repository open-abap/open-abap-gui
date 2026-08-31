import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_101 — returns a field error and cursor", async ({page, host}) => {
  await openExample(page, host, 101);
  await dispatch(page, {
    action: "SUBMIT",
    ucomm: "VALIDATE",
    values: [{name: "P_GOOD", value: "valid sibling"}, {name: "P_BAD", value: ""}],
  });
  await expect(page.locator('[data-screen="0100"]')).toHaveAttribute("data-cursor-field", "P_BAD");
  await expect(page.getByRole("alert")).toContainText("P_BAD is invalid");
  await expect(page.locator('[name="P_BAD"]')).toHaveAttribute("autofocus", "");
});

