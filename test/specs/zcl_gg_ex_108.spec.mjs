import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_108 — renders a subscreen area", async ({page, host}) => {
  await openExample(page, host, 108);
  await expect(page.getByRole("region", {name: "Subscreen area SUB_AREA"})).toHaveCount(1);
  await expect(page.locator('[name="P_PARENT"]')).toHaveValue("parent");
});

