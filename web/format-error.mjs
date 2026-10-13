// The explanation of a request that failed in JavaScript. ZCL_GG_HTTP_HANDLER
// answers every ABAP exception itself, with ZCL_GG_EXCEPTION_TEXT; what is
// left here are JavaScript errors, such as a failure of the runtime or of
// Express, and the explanation is never "" or "[object Object]".
// The module has no Node dependencies: the browser preview uses it as well.

const FALLBACK = "Unknown error (no message available)";
// The cause chain is followed this far, and a cycle ends it.
const MAX_CHAIN = 10;

export function isDevelopment() {
  return typeof process === "undefined" || process.env.NODE_ENV !== "production";
}

// Returns the explanation; with stack, the outermost JavaScript stack follows.
export function formatError(error, {stack = false} = {}) {
  const lines = [];
  const seen = new Set();
  let current = error;
  while (current !== undefined && current !== null && lines.length < MAX_CHAIN && !seen.has(current)) {
    if (typeof current === "object") seen.add(current);
    lines.push(describe(current));
    current = current?.cause;
  }
  let text = lines.filter((line) => line !== "").join("\nCaused by: ") || FALLBACK;
  if (stack && typeof error?.stack === "string" && error.stack !== "") {
    text += `\n\n${error.stack}`;
  }
  return text;
}

// The JSON body a server answers a failed request with.
export function errorResponse(error, options) {
  return {valid: false, error: formatError(error, options)};
}

function describe(error) {
  if (error instanceof Error) {
    // A transpiled ABAP exception that escaped the handler has an empty
    // message; its class name is still known.
    const name = error.constructor?.INTERNAL_NAME || error.name || "Error";
    const message = typeof error.message === "string" ? error.message.trim() : "";
    return message === "" ? name : `${name}: ${message}`;
  }
  if (typeof error === "string") return error.trim();
  if (typeof error === "object") return describeObject(error);
  return String(error);
}

function describeObject(value) {
  if (typeof value.message === "string" && value.message.trim() !== "") return value.message.trim();
  try {
    const json = JSON.stringify(value);
    return json === undefined || json === "{}" ? "" : json;
  } catch {
    return "";
  }
}
