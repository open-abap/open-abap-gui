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

  await openExample(page, host, 143);
  const node = await rejectedDispatch(page, {
    action: "LINE",
    row: 999,
    token: "ALV-TREE-NODE-FORGED",
  });
  expect(node.status).toBe(400);
  expect(node.body.error).toMatch(/Invalid list row|Invalid list action token/);

  await page.goto(`${host.baseUrl}/`);
  const unsafePath = page.getByRole("textbox", {name: "Command"});
  await unsafePath.fill("/n../../etc");
  await unsafePath.press("Enter");
  await expect(page.locator(".wb-status-error[role=alert]")).toContainText(/Unknown transaction code|Unsupported command/);
  await expect(page.locator("[data-page-kind]")).toHaveCount(0);
});

test("PLAN10 - keeps URL and upload metadata browser-owned", async ({page, host}) => {
  await openExample(page, host, 154);
  await page.locator('[name="UPLOAD_FILE"]').setInputFiles({
    name: "../../outside.txt",
    mimeType: "text/plain",
    buffer: Buffer.from("browser-owned fixture"),
  });
  await page.getByRole("button", {name: "Inspect upload"}).click();
  await page.waitForLoadState("load");
  await expect(page.locator("body")).toContainText("Upload metadata inspected");
  await expect(page.locator("body")).not.toContainText("uploaded to server");

  const unsafeLinks = await page.locator("a[href], iframe[src]").evaluateAll((elements) => elements
    .map((element) => element.getAttribute("href") || element.getAttribute("src") || "")
    .filter((url) => /^(?:javascript:|data:|file:|https?:\/\/)/i.test(url)));
  expect(unsafeLinks).toEqual([]);

  await openExample(page, host, 151);
  const frameLinks = await page.frameLocator('[title="HTML viewer"]').locator("a[href]").evaluateAll((elements) => elements
    .map((element) => element.getAttribute("href") || "")
    .filter((url) => /^(?:javascript:|data:|file:|https?:\/\/)/i.test(url)));
  expect(frameLinks).toEqual([]);
});
