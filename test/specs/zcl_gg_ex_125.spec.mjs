import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_125 — renders enabled and disabled toolbar buttons", async ({page, host}) => {
  await openExample(page, host, 125);
  const toolbar = page.locator('[role="toolbar"]').last();
  await expect(toolbar.getByRole("button", {name: "Run"})).toBeEnabled();
  await expect(toolbar.getByRole("button", {name: "Disabled"})).toBeDisabled();
});

