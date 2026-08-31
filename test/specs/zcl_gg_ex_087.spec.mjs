import {test, expect, openExample, submit, dispatch, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_087 — formats individual fragments", async ({page, host}) => {
  await openExample(page, host, 87);
  await expect(page.locator(".gg-color-heading.gg-intensified")).toHaveCount(1);
  await expect(page.locator(".gg-color-positive.gg-hotspot")).toHaveCount(1);
  await expect(page.locator(".gg-color-negative.gg-inverse")).toHaveCount(1);
  await expect(page.locator('[title="Heading & <safe>"]')).toHaveCount(1);
});
