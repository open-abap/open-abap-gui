import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_115 — assigns status and PF5 by screen", async ({page, host}) => {
  await openExample(page, host, 115);
  // Status names are internal, so assert the swap through the commands each one activates.
  // "STATUS 0100" activates ACTION and offers it on the icon bar; SAVE stays inactive.
  await expect(page.locator('.wb-toolbar [data-ucomm="ACTION"]')).toBeEnabled();
  await expect(page.locator('.wb-commandbar button[title="Save"]')).toBeDisabled();
  await dispatch(page, {action: "SUBMIT", ucomm: "NEXT"});
  await expect(page.locator('[data-screen="0200"]')).toHaveCount(1);
  // "STATUS-0200" replaces it: SAVE becomes active and ACTION is excluded, icon bar included.
  await expect(page.locator('.wb-toolbar [data-ucomm="ACTION"]')).toHaveCount(0);
  await expect(page.locator('.wb-commandbar button[title="Save"]')).toBeEnabled();
});

