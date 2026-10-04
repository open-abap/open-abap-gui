import {test, expect, openExample, submit, dispatch} from "../fixtures.mjs";

// The host keeps one list level per request, so the drill-down from the
// detail list to the subdetail list is not reachable yet.
test("ZCL_GG_EX_083 — drills down from the basic list and back", async ({page, host}) => {
  await openExample(page, host, 83);
  await submit(page, "Select line 1");
  await expect(page.locator(".gg-list-line")).toContainText(["Basic list", "Detail list"]);
  await dispatch(page, {action: "BACK"});
  await expect(page.locator(".gg-list-line")).toHaveText("Basic list");
});
