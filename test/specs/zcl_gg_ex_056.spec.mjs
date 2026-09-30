import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test(`ZCL_GG_EX_056 — runs the called transaction and resumes after it`, async ({page, host}) => {
  await openExample(page, host, 56);
  // CALL TRANSACTION 'SE38' AND SKIP FIRST SCREEN: SE38 runs, and its first
  // screen stays because Enter without a program does not leave it.
  await expectPageKind(page, "DYNPRO");
  await expect(page.locator('[name="P_PROGRAM"]')).toBeVisible();
  await dispatch(page, {action: "BACK", ucomm: "BACK"});
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveText("back");
});
