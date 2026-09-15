import {test, expect, openExample} from "../fixtures.mjs";

async function pressToolbar(page, label) {
  await page.locator(".wb-toolbar").getByRole("button", {name: label}).click();
  await page.waitForLoadState("load");
}

test("ZCL_GG_EX_124 - picture exposes safe loaded state", async ({page, host}) => {
  await openExample(page, host, 124);
  const picture = page.locator('[data-control-kind="PICTURE"]');
  await expect(picture).toHaveAttribute("data-picture-state", "loaded");
  await expect(picture).toHaveAttribute("data-display-mode", "0");
  await expect(picture.locator("img")).toHaveAttribute("src", "/assets/icons/refresh.svg");
});

test("ZCL_GG_EX_152 - timer lifecycle is deterministic", async ({page, host}) => {
  await openExample(page, host, 152);
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER STOPPED");
  await expect(page.locator(".gg-structured-table")).toContainText("deterministic clock");
  await pressToolbar(page, "Start timer");
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER RUNNING");
  await pressToolbar(page, "Tick once");
  await expect(page.locator(".gg-structured-table")).toContainText("Completed ticks");
  await pressToolbar(page, "Stop timer");
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER STOPPED");
});

test("ZCL_GG_EX_152 - timer state is isolated between browser sessions", async ({page, host}) => {
  const secondPage = await page.context().newPage();
  try {
    await openExample(page, host, 152);
    await openExample(secondPage, host, 152);
    await pressToolbar(page, "Start timer");
    await pressToolbar(page, "Tick once");
    await expect(page.locator(".gg-structured-table")).toContainText("Completed ticks");
    await expect(secondPage.locator(".gg-structured-table tbody tr").nth(2).locator("td").nth(1)).toHaveText("0");
    await expect(secondPage.locator(".gg-list-status")).toHaveText("TIMER STOPPED");
  } finally {
    await secondPage.close();
  }
});

test("ZCL_GG_EX_153 - tree and grid expose typed drop actions", async ({page, host}) => {
  await openExample(page, host, 153);
  await expect(page.getByRole("tree", {name: "Drag source tree"})).toBeVisible();
  await expect(page.locator("[data-node-key=NODE-100]")).toHaveAttribute("aria-selected", "true");
  await pressToolbar(page, "Reject next drop");
  await pressToolbar(page, "Move node");
  await expect(page.locator(".gg-structured-table")).toContainText("Source row 1");
  await expect(page.getByText("Drop rejected by server validation; no row changed")).toBeVisible();
  await pressToolbar(page, "Move node");
  await expect(page.locator(".gg-structured-table")).toContainText("Grid row 2");
  await pressToolbar(page, "Inspect payload");
  await expect(page.getByText("Payload NODE-100; flavor=application/x-gg-row; effect validated server-side")).toBeVisible();
  await pressToolbar(page, "Copy node");
  await expect(page.locator(".gg-structured-table")).toContainText("Grid row 2 (copy)");
  await pressToolbar(page, "Undo drop");
  await expect(page.locator(".gg-structured-table")).toContainText("Source row 1");
});

test("ZCL_GG_EX_154 - frontend services report capability boundaries", async ({page, host}) => {
  await openExample(page, host, 154);
  await expect(page.locator('input[type="file"]')).toHaveCount(1);
  await expect(page.getByRole("link", {name: "Download browser fixture"})).toHaveAttribute("download", "");
  await pressToolbar(page, "Directory capability");
  await expect(page.locator(".gg-structured-table")).toContainText("desktop API unavailable");
  await expect(page.getByText("Directory access refused: browser has no desktop directory capability")).toBeVisible();
});

test("ZCL_GG_EX_155 - modeless dialog keeps the parent available", async ({page, host}) => {
  await openExample(page, host, 155);
  const dialog = page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]');
  await expect(dialog).toHaveCount(1);
  await expect(dialog).toHaveAttribute("data-modeless", "true");
  await expect(dialog).toHaveAttribute("aria-modal", "false");
  await pressToolbar(page, "Move dialog");
  await expect(page.locator(".gg-structured-table")).toContainText("100, 50");
  await pressToolbar(page, "Resize dialog");
  await expect(page.locator(".gg-structured-table")).toContainText("380 x 190");
  await pressToolbar(page, "Focus dialog");
  await expect(page.locator(".gg-structured-table")).toContainText("FOCUSED");
  await pressToolbar(page, "Use parent");
  await expect(page.getByText("Parent action remained available while dialog was modeless")).toBeVisible();
  await pressToolbar(page, "Close dialog");
  await expect(page.locator('[data-control-kind="DIALOGBOX_CONTAINER"]')).toHaveCount(0);
  await expect(page.locator(".gg-list-status")).toHaveText("DIALOG CLOSED");
});

test("ZCL_GG_EX_156 - popup actions return typed state", async ({page, host}) => {
  await openExample(page, host, 156);
  await pressToolbar(page, "Input popup");
  await expect(page.getByRole("dialog", {name: "INPUT popup"})).toBeVisible();
  await page.getByRole("dialog", {name: "INPUT popup"}).getByRole("button", {name: "OK"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("article", {name: "Popup compatibility gallery"})).toContainText("INPUT returned typed OK");
  await expect(page.locator(".gg-structured-table")).toContainText("INPUT -> OK");
});

test("ZCL_GG_EX_156 - table popup exposes accessible rows", async ({page, host}) => {
  await openExample(page, host, 156);
  await pressToolbar(page, "Table popup");
  const popup = page.getByRole("dialog", {name: "TABLE popup"});
  await expect(popup.locator(".gg-popup-table tbody tr")).toHaveCount(3);
  await popup.getByRole("button", {name: "Select row 2"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByRole("article", {name: "Popup compatibility gallery"})).toContainText("TABLE returned typed row 2");
  await expect(page.locator(".gg-structured-table")).toContainText("TABLE -> row 2");
});

test("ZCL_GG_EX_157 - variant lifecycle stays report-local", async ({page, host}) => {
  await openExample(page, host, 157);
  const table = page.locator('[aria-label="ALV variant lifecycle"]');
  await table.locator('[name="ALV_VARIANT"]').fill("COMPACT");
  await table.getByRole("button", {name: "Save", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-status")).toHaveText("CONFIRM VARIANT");
  await expect(table).toContainText("Confirm save");
  await expect(table.getByRole("button", {name: "Confirm save"})).toBeEnabled();
  await pressToolbar(page, "Confirm save");
  await expect(page.locator(".gg-list-status")).toContainText("SAVED");
  await expect(table).toContainText("saved");
  await pressToolbar(page, "Switch layout");
  await expect(table).toContainText("variant DEFAULT");
  await pressToolbar(page, "Apply layout");
  await expect(table).toContainText("applied through handle ALV-VAR-157");
  await table.locator('[name="ALV_VARIANT"]').fill("BAD/NAME");
  await table.getByRole("button", {name: "Save", exact: true}).click();
  await page.waitForLoadState("load");
  await expect(table).toContainText("Variant rejected");
  await pressToolbar(page, "Delete layout");
  await expect(table).toContainText("deleted from report-local memory");
  await pressToolbar(page, "Cleanup layouts");
  await expect(page.locator(".gg-list-status")).toHaveText("ALV LAYOUT READY");
});

test("ZCL_GG_EX_158 - SALV fallback preserves header item structure", async ({page, host}) => {
  await openExample(page, host, 158);
  const table = page.locator(".gg-salv-hierseq");
  await expect(table).toContainText("Order 100");
  await expect(table.locator('[data-level="1"][data-group-key="100"]')).toHaveCount(1);
  await expect(table.locator('[data-level="2"][data-parent-key="100"]')).toHaveCount(2);
  await expect(table.locator(".gg-salv-hierseq-level").nth(0)).toContainText("Header level");
  await expect(table.locator(".gg-salv-hierseq-level").nth(1)).toContainText("LH400");
  await expect(table.locator("tfoot")).toContainText("410");
  await pressToolbar(page, "Sort hierarchy");
  await expect(page.locator(".gg-salv-hierseq")).toContainText("Item records grouped by binding");
  await pressToolbar(page, "Show totals");
  await expect(page.locator(".gg-salv-hierseq-total")).toContainText("410");
  await pressToolbar(page, "Select item");
  await expect(page.getByText("Selected item LH400 under header Order 100")).toBeVisible();
});

test("ZCL_GG_EX_159 - calendar renders nine stable months", async ({page, host}) => {
  await openExample(page, host, 159);
  const table = page.locator(".gg-structured-table");
  await expect(table.locator("tbody tr")).toHaveCount(9);
  await expect(table).toContainText("ISO weeks");
  await expect(table).toContainText("selection=2026-08-30");
  await expect(table).toContainText("bounds=2026-08-01..2027-12-31");
  await expect(table.locator('[name="CALENDAR_DATE"]')).toHaveValue("2026-08-30");
  await table.locator('[name="CALENDAR_DATE"]').fill("2026-09-05");
  await table.getByRole("button", {name: "Set date"}).click();
  await page.waitForLoadState("load");
  await expect(table).toContainText("selection=2026-09-05");
  await expect(page.getByText("Selected 2026-09-05 within 2026-08-01..2027-12-31")).toBeVisible();
  await table.getByRole("button", {name: "Toggle range"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-status")).toHaveText("CALENDAR RANGE 2026-09-05");
  await expect(table).toContainText("mode=range");
  await table.getByRole("button", {name: "Read selection"}).click();
  await page.waitForLoadState("load");
  await expect(page.getByText("Calendar selection read: 2026-09-05 (range)")).toBeVisible();
  await table.getByRole("button", {name: "Clear marks"}).click();
  await page.waitForLoadState("load");
  await expect(table).toContainText("Last event: MARKS_CLEARED");
  await table.getByRole("button", {name: "Recreate"}).click();
  await page.waitForLoadState("load");
  await expect(table).toContainText("generation=2");
  await expect(page.locator(".gg-list-status")).toHaveText("CALENDAR SINGLE 2026-08-30");
  await pressToolbar(page, "Next months");
  await expect(table.locator("tbody")).toContainText("2026-11");
  await expect(table.locator("tbody")).not.toContainText("2026-08");
  await pressToolbar(page, "Previous months");
  await expect(table.locator("tbody")).toContainText("2026-08");
});
