import {test, expect, openExample, submit, dispatch, expectPageKind, statusMessage} from "../fixtures.mjs";

// Each MESSAGE replaces the one before it in the status bar, as on SAP; the
// last one wears its DISPLAY LIKE colour.
test("ZCL_GG_EX_096 — the last message replaces the earlier one in the status bar", async ({page, host}) => {
  await openExample(page, host, 96);
  await expect(statusMessage(page)).toHaveText("Review the selection");
  await expect(statusMessage(page)).toHaveClass(/wb-status-warning/);
  await expect(statusMessage(page)).toHaveAttribute("role", "alert");
  await expect(page.getByText("Saved successfully")).toHaveCount(0);
  await expect(page.locator(".gg-message, .gg-message-region")).toHaveCount(0);
});
