import {test, expect, openExample, dispatch, submit, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_81 - focuses the failing field while retaining siblings", async ({page, host}) => {
  await openExample(page, host, 81);
  await page.locator('[name="P_GOOD"]').fill("kept");
  await page.locator('[name="P_BAD"]').fill("bad");
  await submit(page);
  await expectPageKind(page, "SELECTION");
  await expect(page.locator('[name="P_GOOD"]')).toHaveValue("kept");
  await expect(page.locator('[name="P_BAD"]')).toHaveAttribute("autofocus", "");
  await page.locator('[name="P_BAD"]').fill("fixed");
  await submit(page);
  await expectPageKind(page, "LIST");
});

