import {test, expect, openExample, submit} from "../fixtures.mjs";

// A served page carries exactly the sprite symbols it refers to: every
// <use href="#wb-icon-…"> finds its symbol, and no symbol goes unused.
async function expectSpriteMatchesReferences(page) {
  const sprite = await page.evaluate(() => {
    const defined = [...document.querySelectorAll(".wb-icon-sprite symbol")].map((symbol) => symbol.id);
    const referenced = [...new Set([...document.documentElement.outerHTML.matchAll(/#(wb-icon-[a-z0-9-]+)/g)]
      .map((match) => match[1]))];
    return {defined, referenced};
  });
  expect(sprite.referenced.length).toBeGreaterThan(0);
  expect([...new Set(sprite.defined)].sort()).toEqual([...sprite.referenced].sort());
}

test("the workbench carries only the icons it shows", async ({page, host}) => {
  await page.goto(`${host.baseUrl}/`);
  await expectSpriteMatchesReferences(page);
});

test("selection tabs keep their icons after the sprite is pruned", async ({page, host}) => {
  await openExample(page, host, 169);
  await expectSpriteMatchesReferences(page);
  const tabs = page.getByRole("tab");
  await expect(tabs).toHaveCount(3);
  for (const symbol of ["map-pin", "settings", "file-alert"]) {
    const icon = page.locator(`[role="tab"] use[href="#wb-icon-${symbol}"]`);
    await expect(icon).toHaveCount(1);
    // The symbol draws: the icon has a size and is not the placeholder.
    const box = await icon.locator("xpath=..").boundingBox();
    expect(box.width).toBeGreaterThan(0);
  }
  await expect(page.locator('use[href="#wb-icon-square-dashed"]')).toHaveCount(0);
});

test("a list page carries only the icons it shows", async ({page, host}) => {
  await openExample(page, host, 171);
  await submit(page);
  await expectSpriteMatchesReferences(page);
});
