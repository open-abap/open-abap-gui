import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_061 — Release is offered once the order is approved", async ({page, host}) => {
  await openExample(page, host, 61);
  const toolbar = page.locator(".wb-toolbar");
  await expect(toolbar.getByRole("button")).toHaveText(["Approve"]);

  await submit(page, "Approve");
  await expect(toolbar.getByRole("button")).toHaveText(["Release"]);
  await expect(page.locator(".gg-list-line").last()).toHaveText("Approved: X, released:");

  await submit(page, "Release");
  await expect(toolbar.getByRole("button")).toHaveCount(0);
  await expect(page.locator(".gg-list-line").last()).toHaveText("Approved: X, released: X");
});
