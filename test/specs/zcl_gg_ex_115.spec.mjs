import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_115 — assigns status and PF5 by screen", async ({page, host}) => {
  await openExample(page, host, 115);
  await expect(page.locator(".gg-dynpro-status")).toHaveText("STATUS 0100");
  await dispatch(page, {action: "SUBMIT", ucomm: "NEXT"});
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  await expect(page.locator(".gg-dynpro-status")).toHaveText("STATUS-0200");
});

