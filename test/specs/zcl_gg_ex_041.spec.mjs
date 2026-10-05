import {test, expect, openExample, submit, expectPageKind, statusMessage} from "../fixtures.mjs";

test(`ZCL_GG_EX_041 — renders an abort message`, async ({page, host}) => {
  await openExample(page, host, 41);
  await expectPageKind(page, "SELECTION");
  await expect(statusMessage(page)).toHaveText("giving up");
  await expect(statusMessage(page)).toHaveClass(/wb-status-error/);
  await expect(statusMessage(page)).toHaveAttribute("role", "alert");
});
