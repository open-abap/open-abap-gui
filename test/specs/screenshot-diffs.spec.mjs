import {copyFile, mkdir, mkdtemp, readFile, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import {test, expect} from "playwright/test";

test("generates a visual report for changed, added, and removed screenshots", async ({page}) => {
  const root = await mkdtemp(join(tmpdir(), "open-abap-gui-diffs-"));
  const baseline = resolve(root, "baseline");
  const current = resolve(root, "current");
  const output = resolve(root, "report");
  await mkdir(baseline, {recursive: true});
  await mkdir(current, {recursive: true});
  await writeFile(resolve(current, "index.html"), "<!doctype html><title>fixture</title>", "utf8");

  try {
    await page.setViewportSize({width: 40, height: 30});
    await page.setContent('<style>html,body{margin:0;width:40px;height:30px;background:#146c2e}</style>');
    await page.screenshot({path: resolve(baseline, "changed.png")});
    await page.screenshot({path: resolve(baseline, "removed.png")});
    await page.screenshot({path: resolve(baseline, "unchanged.png")});
    await copyFile(resolve(baseline, "unchanged.png"), resolve(current, "unchanged.png"));

    await page.setContent('<style>html,body{margin:0;width:40px;height:30px;background:#b00020}</style>');
    await page.screenshot({path: resolve(current, "changed.png")});
    await page.screenshot({path: resolve(current, "added.png")});

    const originalArguments = process.argv.slice();
    process.argv[2] = baseline;
    process.argv[3] = current;
    process.argv[4] = output;
    process.argv[5] = "--content-region=5,4,20,10";
    try {
      await import(`../generate-screenshot-diffs.mjs?test=${Date.now()}`);
    } finally {
      process.argv.splice(0, process.argv.length, ...originalArguments);
    }

    const html = await readFile(resolve(output, "index.html"), "utf8");
    const summary = JSON.parse(await readFile(resolve(output, "summary.json"), "utf8"));
    expect(html).toContain("1 changed");
    expect(html).toContain("1 added");
    expect(html).toContain("1 removed");
    expect(html).toContain("1 unchanged");
    expect(html).toContain('width="40" height="30"');
    expect(html).toContain("Content region: 5,4,20,10");
    expect(html).toContain('href="../../main/screenshots/changed.png"');
    expect(html).toContain('href="../screenshots/changed.png"');
    expect(summary.contentRegion).toEqual({x: 5, y: 4, width: 20, height: 10});
    expect(summary.comparisons[0].dimensions).toEqual({width: 20, height: 10});
    await expect(readFile(resolve(output, "images", "changed.png"))).resolves.toBeTruthy();
    await expect(readFile(resolve(output, "images", "added.png"))).resolves.toBeTruthy();
    await expect(readFile(resolve(output, "images", "removed.png"))).resolves.toBeTruthy();
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});

test("only documented semantic mask regions are ignored", async ({page}) => {
  const root = await mkdtemp(join(tmpdir(), "open-abap-gui-masks-"));
  const baseline = resolve(root, "baseline");
  const current = resolve(root, "current");
  const output = resolve(root, "report");
  const masks = resolve(root, "masks.json");
  await mkdir(baseline, {recursive: true});
  await mkdir(current, {recursive: true});
  await writeFile(resolve(current, "index.html"), "<!doctype html><title>fixture</title>", "utf8");
  await writeFile(masks, JSON.stringify({
    version: 1,
    policy: "Test-only documented volatile region",
    regions: [{id: "volatile-corner", reason: "fixture clock", x: 0, y: 0, width: 5, height: 5}],
  }), "utf8");

  try {
    await page.setViewportSize({width: 40, height: 30});
    await page.setContent('<style>html,body{margin:0;width:40px;height:30px;background:#fff}#volatile{position:absolute;left:0;top:0;width:5px;height:5px;background:#146c2e}</style><div id="volatile"></div>');
    await page.screenshot({path: resolve(baseline, "masked.png")});
    await page.setContent('<style>html,body{margin:0;width:40px;height:30px;background:#fff}#volatile{position:absolute;left:0;top:0;width:5px;height:5px;background:#b00020}</style><div id="volatile"></div>');
    await page.screenshot({path: resolve(current, "masked.png")});

    const originalArguments = process.argv.slice();
    process.argv[2] = baseline;
    process.argv[3] = current;
    process.argv[4] = output;
    process.argv[5] = `--masks=${masks}`;
    try {
      await import(`../generate-screenshot-diffs.mjs?mask-test=${Date.now()}`);
    } finally {
      process.argv.splice(0, process.argv.length, ...originalArguments);
    }

    const summary = JSON.parse(await readFile(resolve(output, "summary.json"), "utf8"));
    expect(summary.unchanged).toBe(1);
    expect(summary.differences).toBe(0);
    expect(summary.masks.regions).toEqual([{id: "volatile-corner", reason: "fixture clock", x: 0, y: 0, width: 5, height: 5}]);
  } finally {
    await rm(root, {recursive: true, force: true});
  }
});
