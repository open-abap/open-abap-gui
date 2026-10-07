import {test, expect, openExample} from "../fixtures.mjs";

async function rejectedDispatch(page, request) {
  const sessionId = await page.locator("[data-page-kind]").getAttribute("data-session-id");
  const pageId = await page.locator("[data-page-kind]").getAttribute("data-page-id");
  const response = await page.context().request.post(
    new URL("/dispatch", page.url()).href,
    {
      headers: {"content-type": "application/json"},
      data: {session_id: sessionId, page_id: pageId, ...request},
    },
  );
  return {status: response.status(), body: await response.json()};
}

test("PLAN10 - rejects forged commands, rows, paths, and node-like identifiers", async ({page, host}) => {
  await openExample(page, host, 61);
  const command = await rejectedDispatch(page, {action: "COMMAND", ucomm: "EXCLUDED"});
  expect(command.status).toBe(400);
  expect(command.body.error).toMatch(/not active/);

  await openExample(page, host, 43);
  const line = await rejectedDispatch(page, {
    action: "LINE",
    row: 999,
    token: "NODE-FORGED",
  });
  expect(line.status).toBe(400);
  expect(line.body.error).toMatch(/Invalid list row|Invalid list action token/);

  // A control event names a submit element of the page; a forged node key
  // is no event the ALV tree offered.
  await openExample(page, host, 143);
  const node = await rejectedDispatch(page, {gg_ctl_event: "GUI-2|TOGGLE|ALV-TREE-NODE-FORGED"});
  expect(node.status).toBe(400);
  expect(node.body.error).toMatch(/Control event is not offered/);

  await page.goto(`${host.baseUrl}/`);
  const unsafePath = page.getByRole("textbox", {name: "Command"});
  await unsafePath.fill("/n../../etc");
  await unsafePath.press("Enter");
  await expect(page.locator(".wb-status-error[role=alert]")).toContainText(/Unknown transaction code|Unsupported command/);
  await expect(page.locator("[data-page-kind]")).toHaveCount(0);
});

test("PLAN10 - keeps URL and upload metadata browser-owned", async ({page, host}) => {
  // An upload hands the program the bytes the user picked; no path of the
  // file name reaches anything on the server.
  await openExample(page, host, 154);
  await page.getByRole("button", {name: "Upload file"}).click();
  await page.waitForLoadState("load");
  await page.getByRole("dialog", {name: "Upload text file"}).getByLabel("File").setInputFiles({
    name: "../../outside.txt",
    mimeType: "text/plain",
    buffer: Buffer.from("browser-owned fixture"),
  });
  await page.getByRole("button", {name: "Open"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator("#gg-dynpro-control-n-GV_FIRST_LINE")).toHaveText("browser-owned fixture");

  // The shell's own Help link is the one absolute URL the page may carry.
  const unsafeLinks = await page.locator("a[href], iframe[src]").evaluateAll((elements) => elements
    .filter((element) => !element.closest(".wb-menubar"))
    .map((element) => element.getAttribute("href") || element.getAttribute("src") || "")
    .filter((url) => /^(?:javascript:|data:|file:|https?:\/\/)/i.test(url)));
  expect(unsafeLinks).toEqual([]);

  await openExample(page, host, 151);
  const frameLinks = await page.frameLocator('[title="HTML viewer"]').locator("a[href]").evaluateAll((elements) => elements
    .map((element) => element.getAttribute("href") || "")
    .filter((url) => /^(?:javascript:|data:|file:|https?:\/\/)/i.test(url)));
  expect(frameLinks).toEqual([]);
});
