import {test, expect, openExample, submit} from "../fixtures.mjs";

const state = (page) => page.locator("#gg-dynpro-control-n-GV_STATE");
const documentField = (page) => page.locator('[name="GV_DOCUMENT"]');
const DOCUMENT = "https://example.com/docs/guide.html?lang=en#intro";

// The tab gets a page of its own without reaching the network.
async function serveDocuments(page) {
  await page.context().route("https://example.com/**", (route) => route.fulfill({
    contentType: "text/html",
    body: "<!doctype html><title>Guide</title><p>Guide</p>",
  }));
}

// Each press is a new page; waiting for it keeps a check off the old one.
async function openDocument(page, document) {
  await documentField(page).fill(document);
  await Promise.all([
    page.waitForEvent("load"),
    page.getByRole("button", {name: "Open document"}).click(),
  ]);
}

test("ZCL_GG_EX_154 — execute opens an HTTPS document in a new tab", async ({page, host}) => {
  await serveDocuments(page);
  await openExample(page, host, 154);
  const popup = page.waitForEvent("popup");
  await openDocument(page, DOCUMENT);
  const tab = await popup;
  await tab.waitForURL(DOCUMENT);
  // The document cannot reach back into the GUI that opened it.
  expect(await tab.evaluate(() => window.opener)).toBeNull();
  await expect(state(page)).toHaveText("Document handed to the browser");
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await tab.close();
});

test("ZCL_GG_EX_154 — a blocked tab leaves the document as a link to follow", async ({page, host}) => {
  await serveDocuments(page);
  // A popup blocker answers window.open, which runs without a click here, with null.
  await page.addInitScript(() => {
    window.open = () => null;
  });
  await openExample(page, host, 154);
  await openDocument(page, DOCUMENT);
  await expect(state(page)).toHaveText("Document handed to the browser");
  const dialog = page.getByRole("dialog", {name: "Open document"});
  await expect(dialog).toBeVisible();
  const link = dialog.getByRole("link", {name: DOCUMENT});
  await expect(link).toBeFocused();
  await expect(link).toHaveAttribute("href", DOCUMENT);
  await expect(link).toHaveAttribute("target", "_blank");
  await expect(link).toHaveAttribute("rel", "noopener noreferrer");

  // The user's click is one the browser lets open a tab.
  const popup = page.waitForEvent("popup");
  await link.click();
  const tab = await popup;
  await tab.waitForURL(DOCUMENT);
  await expect(dialog).toBeHidden();
  await tab.close();
});

test("ZCL_GG_EX_154 — execute refuses what a browser tab cannot open", async ({page, host}) => {
  let tabs = 0;
  page.on("popup", () => tabs++);
  await openExample(page, host, 154);
  for (const [document, expected] of [
    ["C:\\temp\\report.txt", "Open failed: not supported by the GUI"],
    ["file:///tmp/report.txt", "Open failed: not supported by the GUI"],
    ["javascript:alert(1)", "Open failed: not supported by the GUI"],
    ["https://user:secret@example.com/", "Open failed: bad parameter"],
    ["https:///no-host", "Open failed: bad parameter"],
    ["https://example.com/a b", "Open failed: bad parameter"],
    ["", "Open failed: bad parameter"],
  ]) {
    await openDocument(page, document);
    await expect(state(page), document).toHaveText(expected);
    await expect(page.locator("[data-gg-execute]"), document).toHaveCount(0);
  }
  expect(tabs).toBe(0);
});

test("ZCL_GG_EX_154 — file_save_dialog and gui_download save the flights as a file", async ({page, host}) => {
  await openExample(page, host, 154);
  await submit(page, "Download flights");
  const dialog = page.getByRole("dialog", {name: "Download flights"});
  await expect(dialog.getByLabel("File name")).toHaveValue("flights.txt");
  await dialog.getByLabel("File name").fill("connections");

  const download = page.waitForEvent("download");
  await dialog.getByRole("button", {name: "Save"}).click();
  const file = await download;
  expect(file.suggestedFilename()).toBe("connections.txt");
  const stream = await file.createReadStream();
  let text = "";
  for await (const chunk of stream) text += chunk;
  expect(text).toBe("LH\t0400\tFrankfurt\tNew York\r\nUA\t0941\tFrankfurt\tSan Francisco\r\nAF\t0010\tParis\tNew York\r\n");
  await expect(state(page)).toHaveText(`connections.txt: ${Buffer.byteLength(text)} bytes downloaded`);
});

test("ZCL_GG_EX_154 — cancelling the save dialog downloads nothing", async ({page, host}) => {
  await openExample(page, host, 154);
  await submit(page, "Download flights");
  await page.getByRole("dialog", {name: "Download flights"}).getByRole("button", {name: "Cancel"}).click();
  await page.waitForLoadState("load");
  await expect(state(page)).toHaveText("Download cancelled");
  await expect(page.locator("a.gg-download")).toHaveCount(0);
});

test("ZCL_GG_EX_154 — file_open_dialog and gui_upload read the chosen file", async ({page, host}) => {
  await openExample(page, host, 154);
  await submit(page, "Upload file");
  const dialog = page.getByRole("dialog", {name: "Upload text file"});
  await dialog.getByLabel("File").setInputFiles({
    name: "notes.txt",
    mimeType: "text/plain",
    buffer: Buffer.from("First line\r\nSecond line\r\n"),
  });
  await expect(dialog.locator('[name="gg-popup-FILENAME"]')).toHaveValue("notes.txt");
  await dialog.getByRole("button", {name: "Open"}).click();
  await page.waitForLoadState("load");
  await expect(state(page)).toHaveText("notes.txt: 2 lines, 25 bytes");
  await expect(page.locator("#gg-dynpro-control-n-GV_FIRST_LINE")).toHaveText("First line");
});
