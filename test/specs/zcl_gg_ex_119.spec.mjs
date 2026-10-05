import {test, expect, openExample, submit} from "../fixtures.mjs";

test("ZCL_GG_EX_119 — splits an editor and a viewer with an easy splitter", async ({page, host}) => {
  await openExample(page, host, 119);
  await expect(page.locator("textarea")).toHaveValue("Easy splitter content");
  await expect(page.frameLocator('iframe[title="HTML viewer"]').locator("body")).toContainText("Easy splitter viewer");
  await submit(page, "Move sash");
  await expect(page.locator("#gg-dynpro-control-n-GV_STATE")).toHaveText("Sash at 70 %");
});
