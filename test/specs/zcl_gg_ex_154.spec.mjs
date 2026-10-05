import {test, expect, openExample, submit} from "../fixtures.mjs";

const state = (page) => page.locator("#gg-dynpro-control-n-GV_STATE");

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
