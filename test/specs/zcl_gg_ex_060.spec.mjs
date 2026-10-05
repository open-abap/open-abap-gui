import {test, expect, openExample, submit} from "../fixtures.mjs";

const carriers = (page) => page.locator(".gg-list-line").evaluateAll((lines) => lines.map((line) => line.textContent.trim().slice(0, 2)));

test("ZCL_GG_EX_060 — the program's own functions show their text", async ({page, host}) => {
  await openExample(page, host, 60);
  const toolbar = page.locator(".wb-toolbar");
  await expect(toolbar.getByRole("button")).toHaveText(["By airline", "By free seats"]);
  // A function without an icon shows only its text.
  await expect(toolbar.locator("svg")).toHaveCount(0);

  await submit(page, "By airline");
  await expect.poll(() => carriers(page)).toEqual(["AA", "LH", "UA"]);
  await submit(page, "By free seats");
  await expect.poll(() => carriers(page)).toEqual(["LH", "UA", "AA"]);
});
