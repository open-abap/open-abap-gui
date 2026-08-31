import {test, expect, openExample} from "../fixtures.mjs";

test("ZCL_GG_EX_128 — sandboxes HTML viewer content", async ({page, host}) => {
  await openExample(page, host, 128);
  const viewer = page.getByTitle("HTML viewer");
  await expect(viewer).toHaveAttribute("sandbox", "");
  await expect(viewer).toHaveAttribute("srcdoc", /Sandboxed viewer/);
});

