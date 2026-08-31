import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_144 — renders SALV table semantics", async ({page, host}) => {
  await openExample(page, host, 144);
  await expect(page.getByRole("table", {name: "SALV table basics"})).toContainText("Lufthansa");
  await expect(page.getByText("Functions: sort, filter, export")).toBeVisible();
});

