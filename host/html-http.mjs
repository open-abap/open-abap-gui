import {createServer} from "node:http";

const MAX_BODY_BYTES = 1024 * 1024;

function requestFromPayload(payload) {
  const actionValue = String(payload.gg_action ?? payload.action ?? "");
  let action = String(payload.action ?? "");
  let row = Number(payload.row ?? 0);
  let target = String(payload.target ?? "");

  if (actionValue.startsWith("LINE:")) {
    action = "LINE";
    const lineValue = actionValue.slice(5).split("|", 2);
    row = Number(lineValue[0]);
    target = lineValue[1] ?? target;
  } else if (actionValue.startsWith("VALUE_HELP:")) {
    action = "VALUE_HELP";
    target = actionValue.slice(11);
  } else if (actionValue.startsWith("HELP:")) {
    action = "HELP";
    target = actionValue.slice(5);
  } else if (actionValue.startsWith("TAB:")) {
    action = "TAB";
    const tabValue = actionValue.slice(4).split("|", 2);
    target = tabValue[0];
    if (tabValue[1] !== undefined) payload.gg_ucomm ??= tabValue[1];
  } else if (actionValue.startsWith("SCREEN:")) {
    action = "SCREEN";
    const screenValue = actionValue.slice(7).split("|", 2);
    target = screenValue[0];
    if (screenValue[1] !== undefined) payload.gg_ucomm ??= screenValue[1];
  } else if (actionValue.startsWith("COMMAND:")) {
    action = "COMMAND";
    payload.gg_ucomm ??= actionValue.slice(8);
  } else if (actionValue && !action) {
    action = actionValue;
  }

  const parsedValues = Array.isArray(payload.values)
    ? {
      selection: payload.values,
      dynpro: Array.isArray(payload.dynpro_values)
        ? toDynproValues(payload.dynpro_values)
        : toDynproValues(payload.values),
    }
    : formValueSets(payload);
  return {
    session_id: String(payload.session_id ?? ""),
    page_id: String(payload.page_id ?? ""),
    action,
    ucomm: String(payload.gg_ucomm ?? payload.ucomm ?? ""),
    target,
    value: String(payload.value ?? ""),
    row,
    pf_key: Number(payload.pf_key ?? 0),
    token: String(payload.gg_token ?? payload.token ?? (action === "LINE" ? target : "")),
    cursor_field: String(payload.cursor_field ?? ""),
    cursor_value: String(payload.cursor_value ?? ""),
    values: parsedValues.selection,
    dynpro_values: parsedValues.dynpro,
  };
}

function toDynproValues(values) {
  return values.map((value) => ({
    container: String(value.container ?? ""),
    name: String(value.name ?? ""),
    row: Number(value.row ?? 0),
    value: String(value.value ?? ""),
  }));
}

function formValueSets(payload) {
  const reserved = new Set([
    "session_id", "page_id", "action", "gg_action", "ucomm", "gg_ucomm",
    "target", "value", "row", "pf_key", "token", "gg_token", "cursor_field", "cursor_value",
  ]);
  const byName = new Map();
  const byDynproKey = new Map();
  for (const [key, raw] of Object.entries(payload)) {
    if (reserved.has(key) || key.startsWith("gg_")) continue;
    if (key.startsWith("gg-radio-")) {
      const selected = String(raw ?? "");
      if (selected) {
        byName.set(selected, {name: selected, value: "X", ranges: []});
        byDynproKey.set(`\u0000${selected}\u00000`, {container: "", name: selected, row: 0, value: "X"});
      }
      continue;
    }
    const cellMatch = key.match(/^gg-cell-(.*)-(\d+)$/);
    if (cellMatch) {
      const row = Number(cellMatch[2]);
      const separator = cellMatch[1].lastIndexOf("-");
      const container = separator < 0 ? "" : cellMatch[1].slice(0, separator);
      const name = separator < 0 ? cellMatch[1] : cellMatch[1].slice(separator + 1);
      const recordKey = `${container}\u0000${name}\u0000${row}`;
      byDynproKey.set(recordKey, {container, name, row, value: String(raw ?? "")});
      continue;
    }
    const value = String(raw ?? "");
    const rangeMatch = key.match(/^(.+)-(LOW|HIGH|SIGN|OPTION)$/);
    const name = rangeMatch ? rangeMatch[1] : key;
    const record = byName.get(name) ?? {name, value: "", ranges: []};
    if (!rangeMatch) {
      record.value = value;
    } else {
      record.ranges[0] ??= {sign: "I", option: "EQ", low: "", high: ""};
      record.ranges[0][rangeMatch[2].toLowerCase()] = value;
    }
    byName.set(name, record);
    byDynproKey.set(`\u0000${name}\u00000`, {container: "", name, row: 0, value});
  }
  return {selection: [...byName.values()], dynpro: [...byDynproKey.values()]};
}

async function readBody(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      throw new Error("Request body too large");
    }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf8");
}

async function parseRequest(request) {
  const raw = await readBody(request);
  if (!raw) return {};
  const contentType = String(request.headers["content-type"] ?? "");
  if (contentType.includes("application/json")) {
    return JSON.parse(raw);
  }
  return Object.fromEntries(new URLSearchParams(raw));
}

function sendJson(response, status, body) {
  const payload = JSON.stringify(body);
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "content-length": Buffer.byteLength(payload),
  });
  response.end(payload);
}

function sendHtml(response, status, body) {
  response.writeHead(status, {
    "content-type": "text/html; charset=utf-8",
    "cache-control": "no-store",
    "content-length": Buffer.byteLength(body),
  });
  response.end(body);
}

function responseStatus(result) {
  if (result?.valid !== false) return 200;
  return String(result?.error ?? "").includes("Stale") ? 409 : 400;
}

export function createHtmlHostServer({start, dispatch, close = () => {}}) {
  if (typeof start !== "function" || typeof dispatch !== "function") {
    throw new TypeError("start and dispatch callbacks are required");
  }

  return createServer(async (request, response) => {
    try {
      if (request.method === "OPTIONS") {
        response.writeHead(204, {
          allow: "GET, POST, DELETE, OPTIONS",
          "cache-control": "no-store",
        });
        response.end();
        return;
      }

      const url = new URL(request.url ?? "/", "http://localhost");
      if (request.method === "GET" && url.pathname === "/") {
        const result = await start({url});
        sendHtml(response, responseStatus(result), result?.html ?? "");
        return;
      }

      if (request.method === "POST" && url.pathname === "/dispatch") {
        const payload = await parseRequest(request);
        const result = await dispatch(requestFromPayload(payload));
        if (result?.valid === false) {
          sendJson(response, responseStatus(result), result);
        } else {
          sendHtml(response, 200, result?.html ?? "");
        }
        return;
      }

      const match = url.pathname.match(/^\/session\/([^/]+)$/);
      if (request.method === "DELETE" && match) {
        await close(decodeURIComponent(match[1]));
        response.writeHead(204, {"cache-control": "no-store"});
        response.end();
        return;
      }

      response.setHeader("allow", "GET, POST, DELETE, OPTIONS");
      sendJson(response, 405, {valid: false, error: "Method not allowed"});
    } catch (error) {
      sendJson(response, 400, {valid: false, error: error.message});
    }
  });
}

export {requestFromPayload};
