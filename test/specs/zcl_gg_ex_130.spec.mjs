import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_130 — dispatches document events through the host", async ({page, host}) => {
  await openExample(page, host, 130);
  await page.getByRole("button", {name: "Open document"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-line").last()).toHaveText("event OPEN_DOC dispatched by the server");
});

