import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_83 — drills down through three list levels and back", async ({page, host}) => {
  await openExample(page, host, 83);
  await submit(page, "Select line 1");
  await expect(page.locator(".gg-list-line")).toContainText(["Basic list", "Detail list"]);
  await submit(page, "Select line 2");
  await expect(page.locator(".gg-list-line").last()).toHaveText("Subdetail list");
  await dispatch(page, {action: "BACK"});
  await expect(page.locator(".gg-list-line").last()).toHaveText("Detail list");
  await dispatch(page, {action: "BACK"});
  await expect(page.locator(".gg-list-line")).toHaveText("Basic list");
});

