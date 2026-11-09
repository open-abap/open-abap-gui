import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

// The grid sits on the default screen, so it takes the content area of the
// window, whatever the dynpro was designed with, and follows each resize.
async function gridAndContent(page) {
  return page.evaluate(() => {
    const main = document.querySelector("#gg-main-content");
    const area = main.getBoundingClientRect();
    const grid = document.querySelector('[data-control-kind="ALV_GRID"]').getBoundingClientRect();
    return {
      content: {
        left: Math.round(area.left + main.clientLeft),
        top: Math.round(area.top + main.clientTop),
        width: main.clientWidth,
        height: main.clientHeight,
      },
      grid: {left: Math.round(grid.left), top: Math.round(grid.top), width: Math.round(grid.width), height: Math.round(grid.height)},
      overflow: {x: main.scrollWidth - main.clientWidth, y: main.scrollHeight - main.clientHeight},
    };
  });
}

async function expectGridFillsContent(page) {
  const {content} = await gridAndContent(page);
  await expect.poll(async () => {
    const {grid, overflow} = await gridAndContent(page);
    return {grid, overflow};
  }).toEqual({grid: content, overflow: {x: 0, y: 0}});
}

test("ZCL_GG_EX_215 — a grid on the default screen fills the content area as the window is resized", async ({page, host}) => {
  await page.setViewportSize({width: 1440, height: 900});
  await openExample(page, host, 215);
  await expectPageKind(page, "DYNPRO");
  const grid = page.locator('[data-control-kind="ALV_GRID"]');
  await expect(grid.locator("tbody tr")).toHaveCount(40);
  await expectGridFillsContent(page);

  for (const viewport of [{width: 1024, height: 700}, {width: 800, height: 600}, {width: 1440, height: 900}]) {
    await page.setViewportSize(viewport);
    await expectGridFillsContent(page);
  }
});

test("ZCL_GG_EX_215 — rows beyond the window scroll inside the grid", async ({page, host}) => {
  await page.setViewportSize({width: 800, height: 600});
  await openExample(page, host, 215);
  const lastRow = page.locator('[data-control-kind="ALV_GRID"] tbody tr').last();
  await lastRow.scrollIntoViewIfNeeded();
  await expect(lastRow).toBeInViewport();
  await expect(lastRow).toContainText("Customer 40");
  const {overflow} = await gridAndContent(page);
  expect(overflow).toEqual({x: 0, y: 0});
});
