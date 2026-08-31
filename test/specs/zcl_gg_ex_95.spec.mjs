import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_95 — download command prepares escaped CSV output", async ({page, host}) => {
  await openExample(page, host, 95);
  await submit(page, "Download");
  await expect(page.locator(".gg-list-line").last()).toContainText("flights.csv");
  await expect(page.locator(".gg-list")).toContainText("Alpha, Inc.");
});

