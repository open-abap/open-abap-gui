import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_133 — rejects an empty editor value", async ({page, host}) => {
  await openExample(page, host, 133);
  await submit(page, "Check");
  await expect(page.getByRole("alert")).toContainText("Editor value is required");
});
