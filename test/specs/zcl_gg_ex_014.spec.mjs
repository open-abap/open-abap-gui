import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

// STOP leaves START-OF-SELECTION and goes on to END-OF-SELECTION; the list
// shows what both wrote.
test(`ZCL_GG_EX_014 — STOP goes on to END-OF-SELECTION`, async ({page, host}) => {
  await openExample(page, host, 14);
  await expectPageKind(page, "LIST");
  await expect(page.locator("[data-navigation-kind]")).toHaveCount(0);
  await expect(page.locator(".gg-list")).toContainText("before");
  await expect(page.locator(".gg-list")).toContainText("end");
});
