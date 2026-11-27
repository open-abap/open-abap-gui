// The browser preview: the transpiled ABAP runs in the tab, and fetch( ) is
// answered by ZCL_GG_HTTP_HANDLER here instead of over the network. This is the
// preview's transport, as express is the npm start server's; everything the
// user sees, the session shell included, is served by the ABAP host.
import {Buffer} from "buffer";
import "../output/init.mjs";
import {formatError, isDevelopment} from "./format-error.mjs";

const cl_express_icf_shim = globalThis.abap.Classes.CL_EXPRESS_ICF_SHIM;

const ROUTE_ORIGIN = "https://open-abap-gui.invalid";

// Statuses whose response has no body; Response throws when given one, as the
// host's 204 for End Session would be.
const NULL_BODY_STATUSES = new Set([101, 103, 204, 205, 304]);

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

// The generated runtime defaults to a Node stdout console. Replace it before
// the first browser request so WRITE output remains in the ABAP context.
globalThis.abap.console = browserConsole;
globalThis.abap.context.console = browserConsole;

// Chromium on Windows keeps the drive letter in file URL pathnames, e.g.
// `/C:/transaction`. The ABAP handler expects application routes without the
// local drive prefix.
function pathnameForUrl(url) {
  const value = url.pathname || "/";
  return url.protocol === "file:" && /^\/[A-Za-z]:(?:\/|$)/.test(value) ? value.slice(3) || "/" : value;
}

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

// The GUI sessions share the host's static GUI state, which each request puts
// in place for its own session (zcl_gg_host_windows), and the transpiled ABAP
// yields at every await; so the requests run one after the other.
let pending = Promise.resolve();

function browserFetch(input, init = {}) {
  const run = pending.then(() => handleFetch(input, init));
  pending = run.catch(() => undefined);
  return run;
}

async function handleFetch(input, init) {
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

  return new Response(NULL_BODY_STATUSES.has(responseStatus) ? null : responseData, {
    headers: responseHeaders,
    status: responseStatus,
  });
}

globalThis.Buffer = Buffer;
globalThis.fetch = browserFetch;

function showError(error) {
  console.error(error);
  document.body.innerHTML = `<main style="font:16px system-ui;padding:2rem"><h1>Preview failed</h1><pre style="white-space:pre-wrap"></pre></main>`;
  document.querySelector("main pre").textContent = formatError(error, {stack: isDevelopment()});
}

// The address bar's / is the session shell (zcl_gg_shell), which then asks for
// every page itself, a route in the hash included.
async function renderShell() {
  const result = await browserFetch("/");
  const html = await result.text();
  if (!result.ok) {
    throw new Error(`ABAP host returned HTTP ${result.status}: ${html}`);
  }
  document.open();
  document.write(html);
  document.close();
}

renderShell().catch(showError);
