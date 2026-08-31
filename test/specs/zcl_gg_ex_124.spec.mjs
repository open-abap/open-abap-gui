import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_124 — renders a safe picture source", async ({page, host}) => {
  await openExample(page, host, 124);
  await expect(page.locator('[data-control-kind="PICTURE"] img')).toHaveAttribute("src", "/assets/icons/refresh.svg");
  await expect(page.locator('[data-control-kind="PICTURE"] img')).toHaveAttribute("alt", "Picture");
});

