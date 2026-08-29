import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_37 — executes selection exit handling`, async ({page, host}) => {
  await openExample(page, host, 37);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);
  await dispatch(page, {action: "EXIT", ucomm: "ECAN"});
  await expectPageKind(page, "TERMINAL");
  await expect(page.locator(".gg-terminal")).toHaveText("LEAVE PROGRAM");
  await expect(page.locator("form")).toHaveCount(0);
});
