import {access, readFile} from "node:fs/promises";
import {resolve} from "node:path";
import {pathToFileURL} from "node:url";
import {test, expect} from "playwright/test";
import {clickHelp, startHost, statusMessage, stopHost} from "../fixtures.mjs";

// The session shell (zcl_gg_shell), the same in both hosts: the rail lists the
// GUI sessions and each session is an iframe. The address bar's / opens it, in
// the browser preview (npm run web:build), which runs the ABAP runtime in the
// tab, and on the npm start server.
const htmlFile = resolve(process.cwd(), "build", "index.html");
const built = await access(htmlFile).then(() => true, () => false);

const hosts = [
  {name: "browser preview", start: async () => ({base: pathToFileURL(htmlFile).href}), missing: !built},
  {name: "npm start", start: async () => {
    const {child, baseUrl} = await startHost();
    return {base: `${baseUrl}/`, child};
  }, missing: false},
];

function onScreen(page) {
  return page.frameLocator("#gg-frames iframe:not([hidden])");
}

function railEntries(page) {
  return page.locator("#gg-rail .gg-rail-item");
}

async function command(page, value) {
  const field = onScreen(page).getByRole("textbox", {name: "Command"});
  await field.fill(value);
  await field.press("Enter");
}

for (const host of hosts) {
  test.describe(host.name, () => {
    test.skip(host.missing, "build/index.html is missing; run npm run web:build first");

    let running;
    test.beforeAll(async () => {
      running = await host.start();
    });
    test.afterAll(async () => {
      if (running?.child) await stopHost(running.child);
    });

    // Opens the shell, and the transaction in its first session.
    async function open(page, tcode) {
      await page.goto(running.base, {waitUntil: "load"});
      await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible({timeout: 30000});
      if (tcode) {
        await command(page, `/n${tcode}`);
        await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText(tcode);
      }
    }

    test("the rail shows the one session, which cannot be ended from it", async ({page}) => {
      await open(page);
      await expect(page.locator("#gg-rail")).toBeVisible();
      await expect(railEntries(page)).toHaveCount(1);
      await expect(railEntries(page).first()).toHaveClass(/gg-rail-item--active/);
      await expect(page.locator("#gg-rail .gg-rail-end")).toHaveCount(0);
      // The rail casts no shadow onto the session beside it.
      const shadows = await page.locator("#gg-rail").evaluate((rail) =>
        getComputedStyle(rail).boxShadow.split(/,(?![^(]*\))/));
      expect(shadows.filter((shadow) => shadow !== "none" && !shadow.includes("inset"))).toEqual([]);
    });

    test("/o opens a second session and the first keeps its program", async ({page}) => {
      await open(page, "SE16");
      await onScreen(page).getByRole("button", {name: "Table Contents", exact: true}).click();
      await expect(onScreen(page).locator('[data-screen="0150"]')).toHaveCount(1);
      await onScreen(page).locator('input[name="P_T1_MAX"]').fill("2");

      await command(page, "/ose11");
      await expect(railEntries(page)).toHaveCount(2);
      await expect(onScreen(page).locator("#wb-page-title")).toContainText("Dictionary");
      await expect(railEntries(page).nth(1)).toHaveClass(/gg-rail-item--active/);
      await expect(railEntries(page).nth(1).locator(".gg-rail-code")).toHaveText("SE11");

      // Leaving to the workbench in session 2 ends only session 2's program.
      await command(page, "/n");
      await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible();

      await railEntries(page).nth(0).locator(".gg-rail-select").click();
      await expect(onScreen(page).locator('[data-screen="0150"]')).toHaveCount(1);
      await expect(onScreen(page).locator('input[name="P_T1_MAX"]')).toHaveValue("2");
      await onScreen(page).getByRole("button", {name: "Execute", exact: true}).click();
      await expect(onScreen(page).locator('[data-screen="0200"]')).toHaveCount(1);
      await expect(onScreen(page).getByText("2 of 5 rows returned; hard maximum reached.", {exact: true})).toBeVisible();
    });

    test("new sessions go last in the rail", async ({page}) => {
      await open(page, "SE16");
      await command(page, "/ose38");
      await expect(railEntries(page)).toHaveCount(2);
      await railEntries(page).nth(0).locator(".gg-rail-select").click();
      await expect(railEntries(page).nth(0)).toHaveClass(/gg-rail-item--active/);
      await command(page, "/ose11");
      await expect(page.locator("#gg-rail .gg-rail-code")).toHaveText(["SE16", "SE38", "SE11"]);
      await expect(railEntries(page).nth(2)).toHaveClass(/gg-rail-item--active/);

      // Ending the middle one puts the next one on screen.
      await railEntries(page).nth(1).locator(".gg-rail-select").click();
      await expect(onScreen(page).locator("#wb-page-title")).toContainText("ABAP Editor");
      await command(page, "/i");
      await expect(page.locator("#gg-rail .gg-rail-code")).toHaveText(["SE16", "SE11"]);
      await expect(railEntries(page).nth(1)).toHaveClass(/gg-rail-item--active/);
    });

    test("/i ends the session", async ({page}) => {
      await open(page);
      await command(page, "/ose38");
      await expect(railEntries(page)).toHaveCount(2);

      await command(page, "/i");
      await expect(railEntries(page)).toHaveCount(1);
      await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible();
    });

    test("System > Create Session opens one and the rail ends it", async ({page}) => {
      await open(page);
      const frame = onScreen(page);
      await frame.getByRole("menuitem", {name: "System"}).click();
      await expect(frame.getByRole("menuitem", {name: "End Session"})).toBeDisabled();
      await frame.getByRole("menuitem", {name: "Create Session"}).click();
      await expect(railEntries(page)).toHaveCount(2);

      await onScreen(page).getByRole("menuitem", {name: "System"}).click();
      await expect(onScreen(page).getByRole("menuitem", {name: "End Session"})).toBeEnabled();

      await railEntries(page).nth(1).getByRole("button", {name: /^End session/}).click();
      await expect(railEntries(page)).toHaveCount(1);
      await expect(page.locator("#gg-frames iframe")).toHaveCount(1);
    });

    test("the last session cannot be ended", async ({page}) => {
      await open(page);
      await command(page, "/i");
      await expect(statusMessage(onScreen(page))).toContainText("The last session cannot be ended.");
      await expect(page.locator("#gg-frames iframe")).toHaveCount(1);
    });

    test("back to the workbench, the rail shows no transaction", async ({page}) => {
      await open(page, "ZGG_EX_003");
      await onScreen(page).getByRole("button", {name: "Back"}).click();
      await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible();
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("Workbench");
      await expect(railEntries(page).first().locator(".gg-rail-title")).toHaveText("");
    });

    test("a command error keeps the running transaction in the rail", async ({page}) => {
      await open(page, "ZGG_EX_003");
      await command(page, "/xyz");
      await expect(statusMessage(onScreen(page))).not.toHaveText("");
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("ZGG_EX_003");
    });

    test("SUBMIT lists the submitted program in the rail", async ({page}) => {
      await open(page);
      await command(page, "/nZGG_EX_053");
      await expect(onScreen(page).locator(".gg-list")).toContainText("hello world");
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("ZGG_EX_001");
    });

    // The return to the caller is in zcl_gg_host_runtime's unit tests: SE38's
    // status has no Back of its own, so its button leaves for the workbench.
    test("CALL TRANSACTION lists the called transaction in the rail", async ({page}) => {
      await open(page);
      await command(page, "/nZGG_EX_056");
      await expect(onScreen(page).locator('[name="P_PROGRAM"]')).toBeVisible();
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("SE38");
    });

    test("a route in the hash opens in the session, and a new hash replaces it", async ({page}) => {
      await page.goto(`${running.base}#/transaction?tcode=SE16`, {waitUntil: "load"});
      await expect(railEntries(page)).toHaveCount(1);
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("SE16");
      await expect(onScreen(page).getByRole("button", {name: "Table Contents", exact: true})).toBeVisible();

      await page.evaluate(() => { window.location.hash = "/transaction?tcode=SE11"; });
      await expect(railEntries(page)).toHaveCount(1);
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("SE11");
      await expect(onScreen(page).locator("#wb-page-title")).toContainText("Dictionary");
    });

    test("a hash that is not a path of the host opens the workbench", async ({page}) => {
      await page.goto(`${running.base}#//example.com/transaction?tcode=SE16`, {waitUntil: "load"});
      await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible({timeout: 30000});
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("Workbench");
    });

    // A URL reads a backslash as a slash, so /\example.com/ names another host.
    test("a hash that names another host through a backslash opens the workbench", async ({page}) => {
      const requests = [];
      page.on("request", (request) => requests.push(request.url()));
      await page.goto(`${running.base}#/\\example.com/transaction?tcode=SE16`, {waitUntil: "load"});
      await expect(onScreen(page).locator("#wb-app-panel")).toBeVisible({timeout: 30000});
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("Workbench");
      expect(requests.filter((url) => url.includes("example.com"))).toEqual([]);
    });

    test("an unknown transaction in the hash keeps the running one in the rail", async ({page}) => {
      await open(page, "SE16");
      await page.evaluate(() => { window.location.hash = "/transaction?tcode=NOPE"; });
      await expect(statusMessage(onScreen(page))).toContainText("Unknown transaction code: NOPE");
      await expect(railEntries(page).first().locator(".gg-rail-code")).toHaveText("SE16");
    });

    test("value help works in a second session", async ({page}) => {
      await open(page);
      await command(page, "/ose16");
      await expect(railEntries(page)).toHaveCount(2);
      const frame = onScreen(page);
      await frame.getByRole("button", {name: "Table Contents", exact: true}).click();
      await clickHelp(frame, "P_T1_LOW1", "Value help for P_T1_LOW1");
      const help = frame.getByRole("region", {name: "Value help"});
      await expect(help.locator("li")).toHaveText(["AA", "LH", "SQ"]);
      await help.locator("li", {hasText: "LH"}).dblclick();
      await expect(frame.locator('input[name="P_T1_LOW1"]')).toHaveValue("LH");
    });

    // The viewer's sapevent forms post to the top window, the shell; they go
    // through the session instead, so the shell and its sessions stay.
    test("a SAPEVENT link in an HTML viewer stays in its session", async ({page}) => {
      await page.goto(`${running.base}#/ZCL_GG_EX_151`, {waitUntil: "load"});
      const viewer = onScreen(page).frameLocator('iframe[title="HTML viewer"]');
      await expect(viewer.locator("h1")).toHaveText("Flights", {timeout: 30000});
      await command(page, "/ose16");
      await expect(railEntries(page)).toHaveCount(2);
      await railEntries(page).nth(0).locator(".gg-rail-select").click();

      await viewer.getByRole("button", {name: "UA 0941"}).click();
      await expect(viewer.locator("h1")).toHaveText("Flight UA 0941");
      await expect(page.locator("#gg-rail")).toBeVisible();
      await expect(railEntries(page)).toHaveCount(2);

      await viewer.getByLabel("Seats").fill("5");
      await viewer.getByRole("button", {name: "Book"}).click();
      await expect(viewer.locator("p").first()).toHaveText("Frankfurt to San Francisco, 215 seats occupied.");
      await viewer.getByRole("button", {name: "Back to the flights"}).click();
      await expect(viewer.locator("h1")).toHaveText("Flights");

      // The other session is still open on the host.
      await railEntries(page).nth(1).locator(".gg-rail-select").click();
      await onScreen(page).getByRole("button", {name: "Table Contents", exact: true}).click();
      await expect(onScreen(page).locator('[data-screen="0150"]')).toHaveCount(1);
    });

    // The file is a blob: URL of the session's page, which the page's and the
    // shell's link handlers must leave to the browser.
    test("a list saved to a local file downloads from a session", async ({page}) => {
      await page.goto(`${running.base}#/ZCL_GG_EX_095`, {waitUntil: "load"});
      const frame = onScreen(page);
      await expect(frame.locator("[data-page-kind]")).toHaveCount(1, {timeout: 30000});
      await frame.getByRole("menuitem", {name: "List"}).click();
      await frame.getByRole("button", {name: "Save to local file"}).click();
      const dialog = frame.getByRole("dialog", {name: "Save list in file"});
      await dialog.getByRole("radio", {name: "Spreadsheet"}).check();
      await dialog.getByRole("textbox", {name: "File name"}).fill("carriers.xls");
      const downloaded = page.waitForEvent("download");
      await dialog.getByRole("button", {name: "Save"}).click();
      const download = await downloaded;
      expect(download.suggestedFilename()).toBe("carriers.xls");
      expect(await readFile(await download.path(), "utf8")).toContain("LH	Lufthansa	EUR");
    });
  });
}
