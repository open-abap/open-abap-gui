import {test, expect, openExample, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_62 — changes the status after Next", async ({page, host}) => {
  await openExample(page, host, 62);
  await expect(page.locator(".gg-list-status")).toHaveText("SHELL62");
  await expect(page.locator(".wb-toolbar").getByRole("button", {name: "Next"})).toBeEnabled();
  await expect(page.locator(".wb-toolbar").getByRole("button", {name: "Done"})).toBeDisabled();
  await dispatch(page, {action: "COMMAND", ucomm: "NEXT"});
  await expect(page.locator(".gg-list-status")).toHaveText("SHELL62-DONE");
  await expect(page.locator(".gg-list-line")).toHaveText(["initial", "advanced"]);
  await expect(page.locator(".wb-toolbar").getByRole("button", {name: "Next"})).toBeDisabled();
  await expect(page.locator(".wb-toolbar").getByRole("button", {name: "Done"})).toBeEnabled();
});

