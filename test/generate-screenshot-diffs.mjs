import {mkdir, readdir, readFile, rm, writeFile} from "node:fs/promises";
import {basename, resolve} from "node:path";
import {pathToFileURL} from "node:url";
import {chromium} from "playwright";

const [, , baselineArgument, currentArgument, outputArgument] = process.argv;
const baselineDirectory = resolve(baselineArgument || "deployment/main/screenshots");
const currentDirectory = resolve(currentArgument || "build/screenshots");
const outputDirectory = resolve(outputArgument || "build/visual-diffs");
const diffDirectory = resolve(outputDirectory, "images");

function escapeHtml(value) {
  return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

function urlSegment(value) {
  return encodeURIComponent(value);
}

async function screenshotNames(directory) {
  try {
    return (await readdir(directory, {withFileTypes: true}))
      .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".png"))
      .map((entry) => entry.name);
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

async function imageDimensions(filename) {
  const data = await readFile(filename);
  if (data.length < 24 || data.toString("ascii", 1, 4) !== "PNG") {
    throw new Error(`Not a PNG image: ${filename}`);
  }
  return {width: data.readUInt32BE(16), height: data.readUInt32BE(20)};
}

function imageMarkup({source, alt, dimensions}) {
  if (!source) {
    return '<div class="missing">Not present</div>';
  }
  return `<a href="${source}"><img src="${source}" alt="${escapeHtml(alt)}" width="${dimensions.width}" height="${dimensions.height}" loading="lazy"></a>`;
}

await rm(outputDirectory, {recursive: true, force: true});
await mkdir(diffDirectory, {recursive: true});

const baselineNames = await screenshotNames(baselineDirectory);
const currentNames = await screenshotNames(currentDirectory);
const baselineSet = new Set(baselineNames);
const currentSet = new Set(currentNames);
const names = [...new Set([...baselineNames, ...currentNames])]
  .sort((a, b) => a.localeCompare(b, undefined, {numeric: true}));

if (names.length === 0) {
  throw new Error("No baseline or current screenshots were found");
}

const browser = await chromium.launch({headless: true, args: ["--allow-file-access-from-files"]});
const page = await browser.newPage();
const currentIndex = resolve(currentDirectory, "index.html");
await page.goto(pathToFileURL(currentIndex).href, {waitUntil: "load"});

const comparisons = [];
try {
  for (const name of names) {
    const hasBaseline = baselineSet.has(name);
    const hasCurrent = currentSet.has(name);
    const baselinePath = hasBaseline ? resolve(baselineDirectory, name) : null;
    const currentPath = hasCurrent ? resolve(currentDirectory, name) : null;
    const baselineDimensions = baselinePath ? await imageDimensions(baselinePath) : null;
    const currentDimensions = currentPath ? await imageDimensions(currentPath) : null;
    const width = Math.max(baselineDimensions?.width || 0, currentDimensions?.width || 0);
    const height = Math.max(baselineDimensions?.height || 0, currentDimensions?.height || 0);

    const result = await page.evaluate(async ({baselineUrl, currentUrl, width, height}) => {
      async function loadImage(url) {
        if (!url) {
          return null;
        }
        const image = new Image();
        image.src = url;
        await image.decode();
        return image;
      }

      function pixels(image) {
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const context = canvas.getContext("2d", {willReadFrequently: true});
        context.fillStyle = "#fff";
        context.fillRect(0, 0, width, height);
        if (image) {
          context.drawImage(image, 0, 0);
        }
        return context.getImageData(0, 0, width, height);
      }

      const [baselineImage, currentImage] = await Promise.all([
        loadImage(baselineUrl),
        loadImage(currentUrl),
      ]);
      const baseline = pixels(baselineImage);
      const current = pixels(currentImage);
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const context = canvas.getContext("2d");
      const diff = context.createImageData(width, height);
      let changedPixels = 0;

      for (let offset = 0; offset < diff.data.length; offset += 4) {
        const redDelta = Math.abs(baseline.data[offset] - current.data[offset]);
        const greenDelta = Math.abs(baseline.data[offset + 1] - current.data[offset + 1]);
        const blueDelta = Math.abs(baseline.data[offset + 2] - current.data[offset + 2]);
        const alphaDelta = Math.abs(baseline.data[offset + 3] - current.data[offset + 3]);
        const changed = Math.max(redDelta, greenDelta, blueDelta, alphaDelta) > 16;

        if (changed) {
          changedPixels += 1;
          diff.data[offset] = 255;
          diff.data[offset + 1] = 0;
          diff.data[offset + 2] = 96;
        } else {
          const luminance = Math.round(
            current.data[offset] * 0.2126
            + current.data[offset + 1] * 0.7152
            + current.data[offset + 2] * 0.0722,
          );
          const faded = Math.round(225 + luminance * 0.118);
          diff.data[offset] = faded;
          diff.data[offset + 1] = faded;
          diff.data[offset + 2] = faded;
        }
        diff.data[offset + 3] = 255;
      }

      if (changedPixels === 0) {
        return {changedPixels, dataUrl: null};
      }
      context.putImageData(diff, 0, 0);
      return {changedPixels, dataUrl: canvas.toDataURL("image/png")};
    }, {
      baselineUrl: baselinePath ? pathToFileURL(baselinePath).href : null,
      currentUrl: currentPath ? pathToFileURL(currentPath).href : null,
      width,
      height,
    });

    const status = !hasBaseline ? "added" : !hasCurrent ? "removed" : result.changedPixels > 0 ? "changed" : "unchanged";
    if (result.dataUrl) {
      const encoded = result.dataUrl.slice(result.dataUrl.indexOf(",") + 1);
      await writeFile(resolve(diffDirectory, name), Buffer.from(encoded, "base64"));
    }
    comparisons.push({
      name,
      status,
      changedPixels: result.changedPixels,
      totalPixels: width * height,
      dimensions: {width, height},
      baselineDimensions,
      currentDimensions,
    });
  }
} finally {
  await browser.close();
}

const counts = Object.fromEntries(["added", "removed", "changed", "unchanged"]
  .map((status) => [status, comparisons.filter((comparison) => comparison.status === status).length]));
const differences = comparisons.filter((comparison) => comparison.status !== "unchanged");
const cards = differences.map((comparison) => {
  const label = escapeHtml(basename(comparison.name, ".png"));
  const filename = urlSegment(comparison.name);
  const percentage = comparison.totalPixels === 0
    ? "0.00"
    : (comparison.changedPixels / comparison.totalPixels * 100).toFixed(2);
  const baselineSource = comparison.baselineDimensions ? `../../main/screenshots/${filename}` : null;
  const currentSource = comparison.currentDimensions ? `../screenshots/${filename}` : null;
  const diffSource = comparison.changedPixels > 0 ? `images/${filename}` : null;

  return `      <article id="${label}" class="comparison comparison--${comparison.status}">
        <header><h2>${label}</h2><span class="status">${comparison.status}</span><span>${comparison.changedPixels} pixels (${percentage}%)</span></header>
        <div class="panels">
          <figure><figcaption>Main baseline</figcaption>${imageMarkup({source: baselineSource, alt: `${label} on main`, dimensions: comparison.baselineDimensions})}</figure>
          <figure><figcaption>Preview</figcaption>${imageMarkup({source: currentSource, alt: `${label} in preview`, dimensions: comparison.currentDimensions})}</figure>
          <figure><figcaption>Visual diff</figcaption>${imageMarkup({source: diffSource, alt: `${label} visual difference`, dimensions: comparison.dimensions})}</figure>
        </div>
      </article>`;
}).join("\n");

const html = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Screenshot visual diffs</title>
    <style>
      :root { color-scheme: light; font-family: system-ui, sans-serif; color: #172b3f; background: #eef3f8; }
      body { margin: 0; padding: 2rem; }
      h1 { margin: 0 0 .35rem; }
      .intro { margin: 0 0 1.5rem; color: #52677c; }
      .summary { display: flex; flex-wrap: wrap; gap: .65rem; margin-bottom: 1.5rem; }
      .summary span, .status { padding: .3rem .6rem; border-radius: 999px; background: #dce8f3; font-weight: 650; }
      .comparison { margin: 0 0 1.5rem; padding: 1rem; border: 1px solid #b8c9dc; border-radius: 6px; background: #fff; }
      .comparison > header { display: flex; align-items: center; flex-wrap: wrap; gap: .75rem; margin-bottom: .8rem; }
      .comparison h2 { margin: 0 auto 0 0; font: 700 1rem ui-monospace, monospace; }
      .comparison--added .status { background: #d8f0dc; color: #155c25; }
      .comparison--removed .status { background: #f5d9d9; color: #8b2020; }
      .comparison--changed .status { background: #ffe8b8; color: #704900; }
      .panels { display: grid; grid-template-columns: repeat(3, minmax(260px, 1fr)); gap: 1rem; align-items: start; }
      figure { min-width: 0; margin: 0; }
      figcaption { margin-bottom: .4rem; font-weight: 650; }
      a { display: block; }
      img { display: block; width: 100%; height: auto; border: 1px solid #aebfd2; background: #fff; }
      .missing { display: grid; min-height: 10rem; place-items: center; border: 1px dashed #aebfd2; color: #6d7f90; background: #f6f8fa; }
      .empty { padding: 2rem; border: 1px solid #b8c9dc; border-radius: 6px; background: #fff; }
      @media (max-width: 900px) { body { padding: 1rem; } .panels { grid-template-columns: 1fr; } }
    </style>
  </head>
  <body>
    <h1>Screenshot visual diffs</h1>
    <p class="intro">Preview screenshots compared pixel-by-pixel with the deployed <a href="../../main/screenshots/">main baseline</a>. Pink pixels differ.</p>
    <div class="summary">
      <span>${counts.changed} changed</span><span>${counts.added} added</span><span>${counts.removed} removed</span><span>${counts.unchanged} unchanged</span>
    </div>
    <main>
${cards || '      <p class="empty">No visual differences detected.</p>'}
    </main>
  </body>
</html>
`;

await writeFile(resolve(outputDirectory, "index.html"), html, "utf8");

// Keep this deterministic (no timestamps): the preview deployment only commits when
// the generated files actually change.
const summary = {compared: comparisons.length, differences: differences.length, ...counts};
await writeFile(resolve(outputDirectory, "summary.json"), `${JSON.stringify(summary, null, 2)}\n`, "utf8");

console.log(`Compared ${comparisons.length} screenshots: ${differences.length} visual differences`);
console.log(`Wrote ${resolve(outputDirectory, "index.html")}`);
