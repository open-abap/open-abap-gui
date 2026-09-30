import {test, expect, openExample, dispatch, expectPageKind, expectWorkbench} from "../fixtures.mjs";

test(`ZCL_GG_EX_058 — round-trips dynpro screen navigation`, async ({page, host}) => {
  await openExample(page, host, 58);
  await expectPageKind(page, "DYNPRO");
  await expect(page.locator(".wb-app-title")).toHaveText("ZCL_GG_EX_058");
  await expect(page.locator('[data-screen="0100"]')).toHaveCount(1);
  await expect(page.locator('[data-screen="0000"]')).toHaveCount(0);
  // Screen 0100 declares no controls, so the renderer must not emit any button of its own.
  await expect(page.locator("#gg-dynpro-form button")).toHaveCount(0);
  // LEAVE TO SCREEN 0 on the first screen ends the transaction.
  await dispatch(page, {action: "SUBMIT", ucomm: "BACK"});
  await expectWorkbench(page);
});
