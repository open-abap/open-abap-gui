import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_102 — provides value help for an input", async ({page, host}) => {
  await openExample(page, host, 102);
  await page.getByRole("button", {name: "Value help for P_VALUE"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("region", {name: "Value help"})).toContainText("AA");
});

