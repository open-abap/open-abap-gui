import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_99 — renders the basic dynpro control gallery", async ({page, host}) => {
  await openExample(page, host, 99);
  await expectPageKind(page, "DYNPRO");
  const screen = page.locator('[data-screen="0100"]');
  await expect(screen.locator('[data-abap-name="P_INPUT"]')).toHaveValue("input");
  await expect(screen.locator("output")).toHaveText("output");
  await expect(screen.getByText("Text control")).toBeVisible();
  await expect(screen.getByRole("button", {name: "Apply", exact: true})).toBeVisible();
  await expect(screen.locator('[name="P_CHECK"]')).toBeChecked();
  await expect(screen.locator('[name="gg-radio-G1"][value="P_RADIO_A"]')).toBeChecked();
  await expect(screen.locator('[name="P_LIST"] option')).toHaveCount(2);
});

