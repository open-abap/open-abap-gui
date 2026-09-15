import {test, expect, openExample} from "../fixtures.mjs";

const representativeExamples = [124, 132, 143, 147, 148, 159];

async function visibleUnnamedControls(page) {
  return page.locator("button, input, select, textarea, img, a[href], [role='treeitem']").evaluateAll((elements) => {
    const visible = (element) => {
      const style = getComputedStyle(element);
      return !element.hidden
        && style.display !== "none"
        && style.visibility !== "hidden"
        && element.getClientRects().length > 0;
    };
    const nameOf = (element) => {
      const labelledBy = element.getAttribute("aria-labelledby");
      if (labelledBy) {
        const text = labelledBy.split(/\s+/)
          .map((id) => document.getElementById(id)?.textContent ?? "")
          .join(" ")
          .trim();
        if (text) return text;
      }
      if (element.getAttribute("aria-label")?.trim()) return element.getAttribute("aria-label").trim();
      if (element.labels?.length) {
        const text = [...element.labels].map((label) => label.textContent ?? "").join(" ").trim();
        if (text) return text;
      }
      if (element.getAttribute("title")?.trim()) return element.getAttribute("title").trim();
      if (element.tagName === "IMG") return element.getAttribute("alt")?.trim() ?? "";
      return element.textContent?.replace(/\s+/g, " ").trim() ?? "";
    };
    return elements
      .filter((element) => visible(element) && !(element.tagName === "INPUT" && element.type === "hidden"))
      .map((element) => ({tag: element.tagName, name: nameOf(element)}))
      .filter(({name}) => !name);
  });
}

test("PLAN10 - representative renderers remain usable at narrow and reference widths", async ({page, host}) => {
  for (const number of representativeExamples) {
    await page.setViewportSize({width: 1299, height: 1009});
    await openExample(page, host, number);
    await expect(page.locator("[data-page-kind]")).toBeVisible();
    await expect(await visibleUnnamedControls(page), `Example ${number} has an unnamed control at reference width`).toEqual([]);

    await page.setViewportSize({width: 420, height: 760});
    await expect(page.locator("[data-page-kind]")).toBeVisible();
    const layout = await page.evaluate(() => ({
      clientWidth: document.documentElement.clientWidth,
      scrollWidth: document.documentElement.scrollWidth,
      visibleContent: [...document.querySelectorAll("[data-page-kind], .wb-statusbar")]
        .every((element) => element.getClientRects().length > 0),
    }));
    expect(layout.scrollWidth, `Example ${number} overflows horizontally at narrow width`).toBeLessThanOrEqual(layout.clientWidth);
    expect(layout.visibleContent, `Example ${number} loses visible content at narrow width`).toBe(true);
    await expect(await visibleUnnamedControls(page), `Example ${number} has an unnamed control at narrow width`).toEqual([]);
  }
});

test("PLAN10 - high zoom, forced colors, and reduced motion preserve names and keyboard input", async ({page, host}) => {
  await page.setViewportSize({width: 1299, height: 1009});
  await page.emulateMedia({forcedColors: "active", reducedMotion: "reduce"});
  await openExample(page, host, 152);
  await page.evaluate(() => { document.documentElement.style.zoom = "2"; });

  const start = page.getByRole("button", {name: "Start timer"});
  await expect(start).toBeVisible();
  await start.focus();
  await page.keyboard.press("Enter");
  await page.waitForLoadState("load");
  await expect(page.locator(".gg-list-status")).toHaveText("TIMER RUNNING");
  await expect(await visibleUnnamedControls(page), "Zoomed forced-colors page has an unnamed control").toEqual([]);
  await expect(page.locator("[data-page-kind]")).toHaveAttribute("data-page-kind", "LIST");
});
