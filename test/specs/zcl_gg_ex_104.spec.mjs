import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_104 — validates a CHAIN of fields", async ({page, host}) => {
  await openExample(page, host, 104);
  await dispatch(page, {
    action: "SUBMIT",
    ucomm: "CHECK",
    values: [{name: "P_LEFT", value: "left"}, {name: "P_RIGHT", value: "different"}],
  });
  await expect(page.getByRole("alert")).toContainText("CHAIN values must match");
  await expect(page.locator('[name="P_RIGHT"]')).toHaveAttribute("aria-invalid", "true");
});

