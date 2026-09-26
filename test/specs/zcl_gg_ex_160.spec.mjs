import {test, expect, openExample, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_160 — renders each sibling selection block in its own frame", async ({page, host}) => {
  await openExample(page, host, 160);
  await expectPageKind(page, "SELECTION");
  const frames = page.locator("fieldset");
  await expect(frames).toHaveCount(2);
  await expect(frames.nth(0).locator("legend")).toHaveText("Run limits");
  await expect(frames.nth(0).locator('[name="P_MAXRUN"]')).toHaveValue("20");
  await expect(frames.nth(0).locator('[name="P_BKDEF"]')).toHaveCount(0);
  await expect(frames.nth(1).locator("legend")).toHaveText("Background defaults");
  await expect(frames.nth(1).locator('[name="P_BKDEF"]')).toHaveValue("4");
  await frames.nth(1).locator('[name="P_BKDEF"]').fill("6");
  await submit(page);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText(["20", "6"]);
});
