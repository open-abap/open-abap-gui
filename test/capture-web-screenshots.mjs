import {access, mkdir, readdir, readFile, rm, writeFile} from "node:fs/promises";
import {resolve} from "node:path";
import {pathToFileURL} from "node:url";
import {chromium} from "playwright";

const buildDirectory = resolve(process.cwd(), "build");
const htmlFile = resolve(buildDirectory, "index.html");
const screenshotsDirectory = resolve(buildDirectory, "screenshots");
const previewUrl = pathToFileURL(htmlFile).href;
const viewport = {width: 1440, height: 900};

function escapeHtml(value) {
  return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

// The reports the converter examples define, see test/web-converter-examples.mjs.
// Only these reports are captured: other reports may stop the server on
// purpose, like ZGG_INT_CAST_FAILURE.
async function converterExamplePrograms() {
  const examplesDirectory = resolve(process.cwd(), "converter", "test", "examples");
  const programs = new Set();
  for (const example of await readdir(examplesDirectory, {withFileTypes: true})) {
    if (!example.isDirectory()) continue;
    const outputDirectory = resolve(examplesDirectory, example.name, "output");
    for (const filename of await readdir(outputDirectory)) {
      const source = await readFile(resolve(outputDirectory, filename), "utf8");
      const program = /METHOD zif_gg_program_v1~get_program\.\s*rs_program = VALUE #\( program = '([^']+)'/i.exec(source)?.[1];
      if (program) programs.add(program.toUpperCase());
    }
  }
  return programs;
}

async function writeScreenshotIndex(transactions) {
  const descriptions = new Map(transactions.map(({tcode, description}) => [tcode.toLowerCase(), description]));
  const screenshots = (await readdir(screenshotsDirectory, {withFileTypes: true}))
    .filter((entry) => entry.isFile() && /\.(?:png|jpe?g|webp|gif)$/i.test(entry.name))
    .map((entry) => entry.name)
    .sort((a, b) => a.localeCompare(b, undefined, {numeric: true}));

  const cards = screenshots
    .map((filename) => {
      const label = escapeHtml(filename.replace(/\.[^.]+$/, ""));
      const source = escapeHtml(filename);
      const tcode = filename.replace(/\.[^.]+$/, "");
      const description = escapeHtml(descriptions.get(tcode) || "No description available");
      return `        <figure><a href="${source}"><img src="${source}" alt="${label}" width="${viewport.width}" height="${viewport.height}" loading="lazy"></a><figcaption><strong>${label}</strong><span class="description">${description}</span></figcaption></figure>`;
    })
    .join("\n");

  const html = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Web screenshots</title>
    <style>
      body { margin: 2rem; font: 16px system-ui, sans-serif; color: #222; }
      h1 { margin-bottom: .25rem; }
      p { color: #666; }
      main { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem; }
      figure { margin: 0; }
      a { display: block; }
      img { display: block; width: 100%; height: auto; border: 1px solid #ccc; }
      figcaption { display: flex; flex-direction: column; gap: .2rem; padding-top: .4rem; }
      figcaption strong { font-family: ui-monospace, monospace; }
      figcaption .description { color: #666; }
    </style>
  </head>
  <body>
    <h1>Web screenshots</h1>
    <p>${screenshots.length} screenshot${screenshots.length === 1 ? "" : "s"}</p>
    <main>
${cards}
    </main>
  </body>
</html>
`;

  await writeFile(resolve(screenshotsDirectory, "index.html"), html, "utf8");
  return screenshots.length;
}

await access(htmlFile);
await rm(screenshotsDirectory, {recursive: true, force: true});
await mkdir(screenshotsDirectory, {recursive: true});

const browser = await chromium.launch({headless: true});
// Screenshots are compared pixel by pixel against the main branch, so they
// must not catch a popup or a status bar message halfway through its entry
// animation. The pages drop their animations when the reader asks for reduced
// motion; disabling animations on capture covers any that do not.
const page = await browser.newPage({viewport, reducedMotion: "reduce"});
const browserErrors = [];

// The HTML viewer shows program HTML in a frame sandboxed without scripts, so a
// script in that HTML is blocked by design (zgg_ex_128 has one); the browser
// reports it as a console error.
const sandboxedScript = /^Blocked script execution in 'about:srcdoc' because the document's frame is sandboxed and the 'allow-scripts' permission is not set\.$/;

page.on("console", (message) => {
  if (message.type() === "error" && !sandboxedScript.test(message.text())) {
    browserErrors.push(`console: ${message.text()}`);
  }
});
page.on("pageerror", (error) => browserErrors.push(`page: ${error}`));
page.on("requestfailed", (request) => {
  browserErrors.push(`request: ${request.url()} :: ${request.failure()?.errorText || "failed"}`);
});

async function waitForPreview() {
  await page.locator(".wb-appbar").waitFor({state: "visible", timeout: 30000});
  await page.waitForFunction(() => !document.body.innerText.includes("Preview failed"));
}

try {
  await page.goto(previewUrl, {waitUntil: "load"});
  await waitForPreview();

  const transactions = await page.locator('a[href^="/transaction?tcode="]').evaluateAll((links) => {
    const entries = links.map((link) => {
      const href = link.getAttribute("href") || "";
      const tcode = new URL(href, "https://open-abap-gui.invalid").searchParams.get("tcode");
      const description = link.querySelector(".wb-app-description")?.textContent?.trim() || "";
      return {tcode, description};
    });
    return [...new Map(entries
      .filter(({tcode}) => tcode && /^[A-Za-z0-9_]+$/.test(tcode))
      .map((entry) => [entry.tcode, entry])).values()]
      .sort((a, b) => a.tcode.localeCompare(b.tcode, undefined, {numeric: true}));
  });

  if (transactions.length === 0) {
    throw new Error("No transaction links found in the rendered workbench");
  }

  const examplePrograms = await converterExamplePrograms();
  const programs = (await page.locator('a[href^="/program?name="]').evaluateAll((links) => links.map((link) => {
    const href = link.getAttribute("href") || "";
    const program = new URL(href, "https://open-abap-gui.invalid").searchParams.get("name");
    const description = link.querySelector(".wb-app-description")?.textContent?.trim() || "";
    return {program, description};
  })))
    .filter(({program}) => program && examplePrograms.has(program.toUpperCase()))
    .sort((a, b) => a.program.localeCompare(b.program, undefined, {numeric: true}));

  for (const {tcode} of transactions) {
    await page.goto(`${previewUrl}#/transaction?tcode=${encodeURIComponent(tcode)}`, {waitUntil: "load"});
    await waitForPreview();
    await page.screenshot({
      path: resolve(screenshotsDirectory, `${tcode.toLowerCase()}.png`),
      fullPage: false,
      animations: "disabled",
    });
  }

  for (const {program} of programs) {
    await page.goto(`${previewUrl}#/program?name=${encodeURIComponent(program)}`, {waitUntil: "load"});
    await waitForPreview();
    await page.screenshot({
      path: resolve(screenshotsDirectory, `${program.toLowerCase()}.png`),
      fullPage: false,
      animations: "disabled",
    });
  }

  if (browserErrors.length > 0) {
    throw new Error(browserErrors.join("\n"));
  }

  const screenshotCount = await writeScreenshotIndex([
    ...transactions,
    ...programs.map(({program, description}) => ({tcode: program, description})),
  ]);
  console.log(`Captured ${screenshotCount} screenshots (${transactions.length} transactions, ${programs.length} converter example reports) and wrote ${resolve(screenshotsDirectory, "index.html")}`);
} catch (error) {
  if (browserErrors.length > 0) {
    throw new Error(`${error.message}\nBrowser errors:\n${browserErrors.join("\n")}`, {cause: error});
  }
  throw error;
} finally {
  await browser.close();
}
