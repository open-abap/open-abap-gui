import {access, mkdir, rm} from "node:fs/promises";
import {resolve} from "node:path";
import {pathToFileURL} from "node:url";
import {chromium} from "playwright";

const buildDirectory = resolve(process.cwd(), "build");
const htmlFile = resolve(buildDirectory, "index.html");
const screenshotsDirectory = resolve(buildDirectory, "screenshots");
const previewUrl = pathToFileURL(htmlFile).href;
const viewport = {width: 1440, height: 900};

await access(htmlFile);
await rm(screenshotsDirectory, {recursive: true, force: true});
await mkdir(screenshotsDirectory, {recursive: true});

const browser = await chromium.launch({headless: true});
const page = await browser.newPage({viewport});
const browserErrors = [];

page.on("console", (message) => {
  if (message.type() === "error") {
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
    const codes = links.map((link) => {
      const href = link.getAttribute("href") || "";
      return new URL(href, "https://open-abap-gui.invalid").searchParams.get("tcode");
    });
    return [...new Set(codes.filter((code) => code && /^[A-Za-z0-9_]+$/.test(code)))].sort((a, b) =>
      a.localeCompare(b, undefined, {numeric: true}),
    );
  });

  if (transactions.length === 0) {
    throw new Error("No transaction links found in the rendered workbench");
  }

  for (const tcode of transactions) {
    await page.goto(`${previewUrl}#/transaction?tcode=${encodeURIComponent(tcode)}`, {waitUntil: "load"});
    await waitForPreview();
    await page.screenshot({
      path: resolve(screenshotsDirectory, `${tcode.toLowerCase()}.png`),
      fullPage: false,
    });
  }

  if (browserErrors.length > 0) {
    throw new Error(browserErrors.join("\n"));
  }

  console.log(`Captured ${transactions.length} transaction screenshots in ${screenshotsDirectory}`);
} finally {
  await browser.close();
}
