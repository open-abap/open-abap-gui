import {test, expect, openExample} from "../fixtures.mjs";

const baselineCases = [
  {name: "shell", target: ".wb-content", open: async (page, host) => { await page.goto(`${host.baseUrl}/`); }},
  {name: "selection", example: 80},
  {name: "classic-list", example: 87},
  {name: "dynpro", example: 99},
  {name: "table-control", example: 106},
  {name: "modal-dialog", example: 110},
  {name: "modeless-dialog", example: 155},
  {name: "splitter", example: 118},
  {name: "editor", example: 122},
  {name: "toolbar", example: 125},
  {name: "calendar", example: 126},
  {name: "dynamic-document", example: 129},
  {name: "tree", example: 140},
  {name: "alv-grid", example: 135},
  {name: "alv-tree", example: 143},
  {name: "salv-fallback", example: 144},
  {name: "graphics-fallback", example: 149},
];

test("PLAN10 - fixed viewport visual baselines cover every shared renderer", async ({page, host}) => {
  await page.setViewportSize({width: 1299, height: 1009});
  await page.emulateMedia({reducedMotion: "reduce"});

  for (const baseline of baselineCases) {
    if (baseline.example) await openExample(page, host, baseline.example);
    else await baseline.open(page, host);
    await page.evaluate(() => document.fonts?.ready);
    // Chromium's rasterization differs slightly between the local Linux image
    // used to create the baselines and the GitHub-hosted Ubuntu runner. The
    // The modeless and splitter examples contain native textareas, so allow
    // their bounded platform-specific rendering difference while keeping
    // other baselines at a tighter threshold.
    const maxDiffPixelRatio = ["modeless-dialog", "splitter"].includes(baseline.name) ? 0.03 : 0.005;
    await expect(page.locator(baseline.target || ".wb-runtime-content")).toHaveScreenshot(`${baseline.name}.png`, {
      animations: "disabled",
      caret: "hide",
      scale: "css",
      maxDiffPixelRatio,
    });
  }
});
