import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_51 — exposes CALL SELECTION-SCREEN`, async ({page, host}) => {
  await openExample(page, host, 51);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator("[data-navigation-kind]")).toHaveAttribute("data-navigation-kind", "CALL_SELECTION_SCREEN");
  await expect(page.getByText("Transition target: 0500")).toBeVisible();
});
