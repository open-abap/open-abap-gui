import {test, expect, openExample, submit} from "../fixtures.mjs";

// The layouts live in the host for its lifetime, so the tests of this file run in order: the second one saves the
// default layout.
const grid = (page) => page.locator(".gg-alv");
const headings = (page) => grid(page).locator("thead th.gg-grid-column");

async function hideColumns(page, ...names) {
  await submit(page, "Change layout");
  const dialog = page.getByRole("dialog", {name: "Change Layout"});
  for (const name of names) {
    await dialog.getByLabel(name, {exact: true}).uncheck();
  }
  await submit(page, "Apply");
}

test("ZCL_GG_EX_157 — Change layout hides columns of the grid", async ({page, host}) => {
  await openExample(page, host, 157);
  await expect(headings(page)).toHaveText(["Airline", "Flight", "From", "To", "Capacity", "Occupied"]);
  await expect(grid(page).getByRole("button", {name: "Choose layout"})).toBeVisible();
  await expect(grid(page).getByRole("button", {name: "Save layout"})).toBeVisible();

  await hideColumns(page, "From", "Capacity");
  await expect(headings(page)).toHaveText(["Airline", "Flight", "To", "Occupied"]);
  await expect(page.getByRole("dialog", {name: "Change Layout"})).toHaveCount(0);
});

test("ZCL_GG_EX_157 — a saved default layout is chosen again and starts the next run", async ({page, host}) => {
  await openExample(page, host, 157);
  await hideColumns(page, "From", "Capacity");

  await submit(page, "Save layout");
  const save = page.getByRole("dialog", {name: "Save Layout"});
  await save.getByLabel("Layout").fill("compact");
  await save.getByLabel("Description").fill("Without cities");
  await save.getByLabel("Default setting").check();
  await save.getByRole("button", {name: "Save", exact: true}).click();
  await page.waitForLoadState("load");

  await submit(page, "Current layout");
  await expect(page.locator("#gg-dynpro-control-n-GV_LAYOUT")).toHaveText("COMPACT");
  await expect(page.locator("#gg-dynpro-control-n-GV_LAYOUT_TEXT")).toHaveText("Without cities");

  await submit(page, "Choose layout");
  const choose = page.getByRole("dialog", {name: "Choose Layout"});
  await expect(choose.locator("tbody tr")).toHaveCount(1);
  await expect(choose.locator("tbody tr")).toContainText("Without cities");
  await choose.getByRole("button", {name: "COMPACT"}).click();
  await page.waitForLoadState("load");
  await expect(headings(page)).toHaveText(["Airline", "Flight", "To", "Occupied"]);

  // A new run of the transaction starts with the default layout.
  await openExample(page, host, 157);
  await expect(headings(page)).toHaveText(["Airline", "Flight", "To", "Occupied"]);
  await submit(page, "Current layout");
  await expect(page.locator("#gg-dynpro-control-n-GV_LAYOUT")).toHaveText("COMPACT");
});
