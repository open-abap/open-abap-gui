import {Buffer} from "buffer";
import {cl_express_icf_shim} from "../output/cl_express_icf_shim.clas.mjs";
import "../output/init.mjs";

const ROUTE_ORIGIN = "https://open-abap-gui.invalid";
const originalFetch = globalThis.fetch;
const embeddedAssets = new Map([
  [
    "/assets/icons/refresh.svg",
    `data:image/svg+xml;charset=utf-8,${encodeURIComponent(
      `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 11a8.1 8.1 0 0 0-15.5-2m-.5-4v4h4"/><path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4"/></svg>`,
    )}`,
  ],
]);
const browserConsole = {
  value: "",
  empty: true,
  clear() {
    this.value = "";
    this.empty = true;
  },
  add(data) {
    this.value += String(data);
    this.empty = false;
  },
  get() {
    return this.value;
  },
  isEmpty() {
    return this.empty;
  },
  getTrimmed() {
    return this.value.trim();
  },
};

function normalizeRoutePath(pathname) {
  const value = pathname || "/";
  // Chromium on Windows keeps the drive letter in file URL pathnames, e.g.
  // `/C:/transaction`. The ABAP handler expects application routes without
  // the local drive prefix.
  return /^\/[A-Za-z]:(?:\/|$)/.test(value) ? value.slice(3) || "/" : value;
}

function pathnameForUrl(url) {
  return url.protocol === "file:"
    ? normalizeRoutePath(url.pathname)
    : url.pathname || "/";
}

// The generated runtime defaults to a Node stdout console. Replace it before
// the first browser request so WRITE output remains in the ABAP context.
globalThis.abap.console = browserConsole;
globalThis.abap.context.console = browserConsole;

function routeUrl(value) {
  const raw = typeof value === "string" ? value : value?.url;
  return new URL(raw || "/", ROUTE_ORIGIN);
}

function requestBody(value) {
  if (value === undefined || value === null) {
    return Buffer.alloc(0);
  }
  if (value instanceof URLSearchParams) {
    return Buffer.from(value.toString());
  }
  if (typeof value === "string") {
    return Buffer.from(value);
  }
  if (value instanceof ArrayBuffer || ArrayBuffer.isView(value)) {
    return Buffer.from(value);
  }
  return Buffer.from(String(value));
}

function requestHeaders(input, init) {
  const headers = new Headers(init?.headers || input?.headers || {});
  if (init?.body instanceof URLSearchParams && !headers.has("content-type")) {
    headers.set("content-type", "application/x-www-form-urlencoded");
  }
  return Object.fromEntries(headers.entries());
}

function responseBody(value) {
  if (value instanceof Uint8Array) {
    return value;
  }
  if (value instanceof ArrayBuffer) {
    return new Uint8Array(value);
  }
  return new TextEncoder().encode(String(value ?? ""));
}

async function browserFetch(input, init = {}) {
  const url = routeUrl(input);
  const pathname = pathnameForUrl(url);
  const method = String(init.method || (typeof input === "object" ? input.method : "GET") || "GET").toUpperCase();
  const body = init.body === undefined && typeof input === "object" ? input.body : init.body;
  const responseHeaders = new Headers();
  let responseStatus = 200;
  let responseData = new Uint8Array(0);
  const response = {
    append(name, value) {
      responseHeaders.append(name, value);
    },
    status(code) {
      responseStatus = Number(code);
      return response;
    },
    send(data) {
      responseData = responseBody(data);
    },
  };

  await cl_express_icf_shim.run({
    req: {
      body: requestBody(body),
      headers: requestHeaders(input, init),
      method,
      path: pathname,
      url: `${pathname}${url.search}`,
    },
    res: response,
    class: "ZCL_GG_HTTP_HANDLER",
  });

  return new Response(responseData, {
    headers: responseHeaders,
    status: responseStatus,
  });
}

globalThis.Buffer = Buffer;
globalThis.fetch = browserFetch;

function routeFromHash() {
  const route = window.location.hash.slice(1);
  return normalizeRoutePath(route);
}

function routeKey(value) {
  const url = new URL(value, ROUTE_ORIGIN);
  return `${normalizeRoutePath(url.pathname)}${url.search}`;
}

function setRoute(value) {
  const next = routeKey(value);
  if (routeFromHash() !== next) {
    window.location.hash = next;
  }
}

async function writeResponse(result) {
  const html = await result.text();
  if (!result.ok) {
    throw new Error(`ABAP host returned HTTP ${result.status}: ${html}`);
  }
  document.open();
  document.write(html);
  document.close();
  inlineEmbeddedAssets();
  // document.open() may clear listeners associated with the replaced
  // document. Reinstall the delegated handlers for the newly rendered page.
  installValueHelpHandlers();
  installNavigationHandlers();
}

function inlineEmbeddedAssets() {
  for (const [path, dataUrl] of embeddedAssets) {
    for (const element of document.querySelectorAll(`[src="${path}"], [href="${path}"]`)) {
      if (element.hasAttribute("src")) {
        element.setAttribute("src", dataUrl);
      } else {
        element.setAttribute("href", dataUrl);
      }
    }
  }
}

function valueHelpField(name) {
  if (!name) {
    return undefined;
  }
  const fields = document.querySelectorAll("[data-abap-name], [name]");
  for (const field of fields) {
    if (field.getAttribute("data-abap-name") === name || field.getAttribute("name") === name) {
      return field;
    }
  }
  if (!name.endsWith("-LOW")) {
    return valueHelpField(name + "-LOW");
  }
  return undefined;
}

function closeValueHelp(modal, field) {
  modal.hidden = true;
  modal.setAttribute("aria-hidden", "true");
  (field || valueHelpField(modal.getAttribute("data-help-field")))?.focus();
}

function handleValueHelpClick(event) {
  if (!(event.target instanceof Element)) {
    return;
  }
  const modal = event.target.closest(".gg-value-help-modal");
  if (!modal || modal.hidden) {
    return;
  }
  const close = event.target.closest("[data-value-help-close]");
  if (close) {
    event.preventDefault();
    closeValueHelp(modal);
    return;
  }
  if (event.target === modal) {
    closeValueHelp(modal);
  }
}

function handleValueHelpDoubleClick(event) {
  if (!(event.target instanceof Element)) {
    return;
  }
  const row = event.target.closest(".gg-value-help li");
  const modal = row?.closest(".gg-value-help-modal");
  if (!row || !modal || modal.hidden) {
    return;
  }
  const field = valueHelpField(row.getAttribute("data-name") || modal.getAttribute("data-help-field"));
  if (!field) {
    return;
  }
  field.value = row.getAttribute("data-value") ?? row.textContent.trim();
  field.dispatchEvent(new Event("input", {bubbles: true}));
  field.dispatchEvent(new Event("change", {bubbles: true}));
  closeValueHelp(modal, field);
}

function handleValueHelpKeydown(event) {
  if (event.key !== "Escape") {
    return;
  }
  const modal = document.querySelector(".gg-value-help-modal:not([hidden])");
  if (!modal) {
    return;
  }
  event.preventDefault();
  closeValueHelp(modal);
}

function installValueHelpHandlers() {
  document.removeEventListener("click", handleValueHelpClick, true);
  document.removeEventListener("dblclick", handleValueHelpDoubleClick);
  document.removeEventListener("keydown", handleValueHelpKeydown);
  if (!document.querySelector(".gg-value-help-modal")) {
    return;
  }
  document.addEventListener("click", handleValueHelpClick, true);
  document.addEventListener("dblclick", handleValueHelpDoubleClick);
  document.addEventListener("keydown", handleValueHelpKeydown);
  document.querySelector("[data-value-help-close]")?.focus();
}

async function renderRequest(value, init, updateRoute) {
  if (updateRoute) {
    setRoute(value);
  }
  await writeResponse(await browserFetch(value, init));
}

function formBody(form, submitter) {
  const values = new FormData(form);
  if (submitter?.name) {
    values.set(submitter.name, submitter.value);
  }
  const encoded = new URLSearchParams();
  for (const [name, value] of values.entries()) {
    encoded.append(name, typeof value === "string" ? value : value.name);
  }
  return encoded;
}

function handleClick(event) {
  if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
    return;
  }
  const link = event.target instanceof Element ? event.target.closest("a[href]") : undefined;
  if (!link) {
    return;
  }
  const href = link.getAttribute("href");
  if (!href || href.startsWith("#") || href.startsWith("mailto:") || href.startsWith("javascript:")) {
    return;
  }
  const url = new URL(href, window.location.href);
  if (url.origin !== window.location.origin && url.protocol !== "file:") {
    return;
  }
  event.preventDefault();
  const target = `${pathnameForUrl(url)}${url.search}`;
  if (routeFromHash() === routeKey(target)) {
    renderRequest(target, undefined, false).catch(showError);
  } else {
    setRoute(target);
  }
}

function handleSubmit(event) {
  if (!(event.target instanceof HTMLFormElement)) {
    return;
  }
  const form = event.target;
  const url = new URL(form.getAttribute("action") || "/", window.location.href);
  if (url.origin !== window.location.origin && url.protocol !== "file:") {
    return;
  }
  event.preventDefault();
  const method = String(form.getAttribute("method") || "GET").toUpperCase();
  const body = method === "GET" ? undefined : formBody(form, event.submitter);
  const target = method === "GET"
    ? `${pathnameForUrl(url)}${url.search}${body ? (url.search ? "&" : "?") + body : ""}`
    : `${pathnameForUrl(url)}${url.search}`;
  if (method === "GET" && routeFromHash() !== routeKey(target)) {
    setRoute(target);
  } else {
    renderRequest(target, {method, body}, false).catch(showError);
  }
}

function handleHashchange() {
  renderRequest(routeFromHash(), undefined, false).catch(showError);
}

function installNavigationHandlers() {
  window.removeEventListener("click", handleClick, true);
  window.removeEventListener("submit", handleSubmit, true);
  window.removeEventListener("hashchange", handleHashchange);
  window.addEventListener("click", handleClick, true);
  window.addEventListener("submit", handleSubmit, true);
  window.addEventListener("hashchange", handleHashchange);
}

function showError(error) {
  console.error(error);
  document.body.innerHTML = `<main style="font:16px system-ui;padding:2rem"><h1>Preview failed</h1><pre style="white-space:pre-wrap">${String(error.message || error)}</pre></main>`;
}

if (originalFetch !== undefined) {
  // Keep a reference for debugging and make the intentional replacement clear
  // to browser tooling; application requests use browserFetch above.
  globalThis.__openAbapGuiNetworkFetch = originalFetch;
}

installNavigationHandlers();
renderRequest(routeFromHash(), undefined, false).catch(showError);
