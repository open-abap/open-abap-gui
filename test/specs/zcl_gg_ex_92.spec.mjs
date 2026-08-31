import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_92 — pages through server-owned list data", async ({page, host}) => {
  await openExample(page, host, 92);
  await expect(page.locator(".gg-list-status")).toHaveText("PAGE 1");
  await submit(page, "Next");
  await expect(page.locator(".gg-list-status")).toHaveText("PAGE 2");
  await expect(page.locator(".gg-list")).toContainText("Flight 4");
  await submit(page, "Last");
  await expect(page.locator(".gg-list-status")).toHaveText("PAGE 4");
});

