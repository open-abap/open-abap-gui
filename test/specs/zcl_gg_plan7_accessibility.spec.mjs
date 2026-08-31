import {test, expect, openExample} from "../fixtures.mjs";

const plan7Examples = Array.from({length: 92}, (_, index) => index + 59);

test("PLAN7 — every rendered control has a name and keyboard-visible focus", async ({page, host}) => {
  for (const number of plan7Examples) {
    await openExample(page, host, number);

    const unnamed = await page.locator("button, input, select, textarea, iframe, img, a[href], [role='treeitem']")
      .evaluateAll((elements) => {
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
          const ariaLabel = element.getAttribute("aria-label")?.trim();
          if (ariaLabel) return ariaLabel;
          if (element.labels?.length) {
            const text = [...element.labels].map((label) => label.textContent ?? "").join(" ").trim();
            if (text) return text;
          }
          const title = element.getAttribute("title")?.trim();
          if (title) return title;
          if (element.tagName === "IMG") return element.getAttribute("alt")?.trim() ?? "";
          return element.textContent?.replace(/\s+/g, " ").trim() ?? "";
        };
        return elements
          .filter((element) => visible(element) && !(element.tagName === "INPUT" && element.type === "hidden"))
          .map((element) => ({tag: element.tagName, name: nameOf(element)}))
          .filter(({name}) => !name);
      });
    expect(unnamed, `Example ${number} contains an unnamed control`).toEqual([]);

    const focusables = page.locator("button:not([disabled]), input:not([type='hidden']):not([disabled]), select:not([disabled]), textarea:not([disabled]), a[href], [role='treeitem'][tabindex='0']");
    const focusableIndexes = await focusables.evaluateAll((elements) => {
      const visible = (element) => {
        const style = getComputedStyle(element);
        return !element.hidden
          && style.display !== "none"
          && style.visibility !== "hidden"
          && element.getClientRects().length > 0;
      };
      return elements
        .map((element, index) => ({element, index}))
        .filter(({element}) => visible(element))
        .map(({index}) => index);
    });
    expect(focusableIndexes.length, `Example ${number} has no keyboard focus target`).toBeGreaterThan(0);

    for (const index of focusableIndexes) {
      const target = focusables.nth(index);
      await target.focus();
      const focusState = await target.evaluate((element) => {
        const style = getComputedStyle(element);
        const hasOutline = style.outlineStyle !== "none" && style.outlineWidth !== "0px";
        const hasShadow = style.boxShadow !== "none";
        const hasBorder = style.borderStyle !== "none" && style.borderWidth !== "0px";
        return {
          active: document.activeElement === element,
          keyboardReachable: element.tabIndex >= 0,
          visibleIndicator: hasOutline || hasShadow || hasBorder || element.matches(":focus-visible"),
        };
      });
      expect(focusState.active, `Example ${number} lost focus`).toBe(true);
      expect(focusState.keyboardReachable, `Example ${number} has a non-keyboard target`).toBe(true);
      expect(focusState.visibleIndicator, `Example ${number} has no visible focus indicator`).toBe(true);
    }
  }
});
