import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_107 — exposes table scrolling metadata", async ({page, host}) => {
  await openExample(page, host, 107);
  const table = page.locator('[data-table-control]');
  await expect(table).toHaveAttribute("data-hscroll", "true");
  await expect(table).toHaveAttribute("data-vscroll", "true");
});

