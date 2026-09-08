import {test, expect, openExample, expectPageKind} from "../fixtures.mjs";

test("ZCL_GG_EX_151 — carries the whole UI in one full-screen HTML viewer", async ({page, host}) => {
  await openExample(page, host, 151);
  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-line")).toHaveCount(0);

  const viewer = page.getByTitle("HTML viewer");
  // Enough to submit a form and, on a real click, replace the top page. Nothing else.
  await expect(viewer).toHaveAttribute(
    "sandbox",
    "allow-forms allow-top-navigation-by-user-activation",
  );
  await expect(viewer).toHaveAttribute("srcdoc", /\$ZDEMO_ALPHA/);
  const size = await viewer.evaluate((element) => ({
    width: element.clientWidth,
    height: element.clientHeight,
  }));
  expect(size).toEqual({width: 960, height: 540});

  // The docking container is the surface, so it holds the viewer and nothing else.
  const shell = page.locator('[data-control-kind="DOCKING_CONTAINER"]');
  await expect(shell).toHaveCount(1);
  await expect(shell).toBeEmpty();
});

test("ZCL_GG_EX_151 — renders the page document inside the sandbox", async ({page, host}) => {
  await openExample(page, host, 151);
  const document = page.frameLocator('[title="HTML viewer"]');
  await expect(document.locator("header")).toHaveText("Repositories");
  await expect(document.locator("tbody tr")).toHaveCount(3);
  await expect(document.locator("tbody tr").nth(1)).toContainText("release");
});

test("ZCL_GG_EX_151 — a sapevent anchor inside the control reaches the server", async ({page, host}) => {
  await openExample(page, host, 151);
  const document = page.frameLocator('[title="HTML viewer"]');

  // The anchor the program wrote arrives as a submit button of a form posting
  // to /dispatch, and scripts stay blocked inside the same document.
  const open = document.getByRole("button", {name: "$ZDEMO_BETA"});
  await expect(open).toBeVisible();
  await open.click();
  await page.waitForLoadState("load");

  await expectPageKind(page, "LIST");
  await expect(page.locator(".gg-list-status")).toHaveText("REPOSITORY");
  await expect(document.locator("header")).toHaveText("$ZDEMO_BETA");

  // Staging from inside the document too, then back out of the page stack.
  await document.getByRole("button", {name: "Stage changes"}).click();
  await page.waitForLoadState("load");
  await expect(document.locator("dd").nth(2)).toHaveText("staged");

  await document.getByRole("button", {name: "Back to repositories"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-status")).toHaveText("OVERVIEW");
});

test("ZCL_GG_EX_151 — the host rejects a sapevent action the page never declared", async ({page, host}) => {
  await openExample(page, host, 151);
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");

  // Same transport the rewritten anchor uses, with an action the overview
  // status does not carry.
  const response = await page.evaluate(async ({sessionId, pageId}) => {
    const body = new URLSearchParams({
      session_id: sessionId,
      page_id: pageId,
      action: "COMMAND",
      ucomm: "STAGE",
    });
    const result = await fetch("/dispatch", {
      method: "POST",
      headers: {"content-type": "application/x-www-form-urlencoded"},
      body: body.toString(),
    });
    return {status: result.status, text: await result.text()};
  }, {sessionId, pageId});

  expect(response.status).toBe(400);
  expect(response.text).toMatch(/not active/);
});

test("ZCL_GG_EX_151 — opens a repository page from the declared icon bar", async ({page, host}) => {
  await openExample(page, host, 151);
  const toolbar = page.locator(".wb-toolbar");
  await expect(toolbar.getByRole("button", {name: "Open $ZDEMO_BETA"})).toBeEnabled();
  await toolbar.getByRole("button", {name: "Open $ZDEMO_BETA"}).click();
  await page.waitForLoadState("load");

  await expect(page.locator(".gg-list-status")).toHaveText("REPOSITORY");

  const document = page.frameLocator('[title="HTML viewer"]');
  await expect(document.locator("header")).toHaveText("$ZDEMO_BETA");
  await expect(document.locator("dd").nth(2)).toHaveText("not staged");

  // The overview actions are no longer declared, so they are gone from the bar.
  await expect(toolbar.getByRole("button", {name: "Open $ZDEMO_BETA"})).toHaveCount(0);
  await expect(toolbar.getByRole("button", {name: "Stage changes"})).toBeEnabled();
});

test("ZCL_GG_EX_151 — stages, re-renders, and steps back to the overview", async ({page, host}) => {
  await openExample(page, host, 151);
  const toolbar = page.locator(".wb-toolbar");
  await toolbar.getByRole("button", {name: "Open $ZDEMO_BETA"}).click();
  await page.waitForLoadState("load");
  await toolbar.getByRole("button", {name: "Stage changes"}).click();
  await page.waitForLoadState("load");

  const document = page.frameLocator('[title="HTML viewer"]');
  await expect(document.locator("dd").nth(2)).toHaveText("staged");

  await toolbar.getByRole("button", {name: "Back to repositories"}).click();
  await page.waitForLoadState("load");

  await expect(page.locator(".gg-list-status")).toHaveText("OVERVIEW");
  await expect(document.locator("header")).toHaveText("Repositories");
});
