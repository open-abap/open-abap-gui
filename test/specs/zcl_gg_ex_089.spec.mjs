import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_089 — keeps fixed-width formatting deterministic", async ({page, host}) => {
  await openExample(page, host, 89);
  const line = page.locator(".gg-list-line");
  await expect(line).toContainText("42.50");
  await expect(line).toContainText("2026-08-30");
  await expect(line).toContainText("12345");
});
