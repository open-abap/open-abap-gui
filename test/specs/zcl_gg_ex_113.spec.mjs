import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_113 — records CANCEL as a dynpro message", async ({page, host}) => {
  await openExample(page, host, 113);
  await dispatch(page, {action: "SUBMIT", ucomm: "CANCEL"});
  await expect(page.getByRole("alert")).toContainText("Cancelled");
});

