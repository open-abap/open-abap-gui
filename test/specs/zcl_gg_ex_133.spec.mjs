import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_133 — associates validation with a control id", async ({page, host}) => {
  await openExample(page, host, 133);
  const message = page.getByRole("alert");
  await expect(message).toHaveAttribute("data-control-id", /GUI-/);
  await expect(message).toHaveText("Editor value is required");
});

