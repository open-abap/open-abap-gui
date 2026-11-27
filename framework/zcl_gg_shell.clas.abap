CLASS zcl_gg_shell DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The session shell, the page the address bar's / opens in every host: a rail
* of GUI sessions beside the session on screen, each session in an iframe of
* its own, so every page keeps its styles, element ids and scripts.
*
* The shell's script fetches the pages with fetch( ), naming its session in the
* x-gg-window header; its first request asks for a new one (see
* zcl_gg_host_windows), so the shells of several browser tabs never share a
* session, and the requests sent before the host named it wait for the name.
* When the page goes, by a reload or a closed tab, the host ends the shell's
* sessions. A session's frame carries the status of its last page in
* data-gg-status; the host's error pages show in the frame like any other. The host says when a session opens or ends with the x-gg-session
* response header, after /o, /i or System > Create Session and End Session.
* In the browser preview fetch( ) is the ABAP runtime in the tab (web/web.mjs),
* on the npm start server it is the network; the shell is the same in both.
* A route in the hash (/#/transaction?tcode=SE16) opens in the active session.
*
* The rail lists the sessions in the order they opened, with the transaction
* code and screen title of each, and ends one from its button; the last
* session stays open. It collapses to the start of each transaction code.
* The host names the transaction on screen in the x-gg-transaction response
* header, see zcl_gg_host_runtime=>transaction_of; the shell never guesses it
* from the URL, since a program ends or calls another without one.
* Its look is "Midnight Glass": a navy gradient, the active session a frosted
* pane with a gold marker.

  PUBLIC SECTION.
    CLASS-METHODS render
      RETURNING
        VALUE(rv_html) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS styles
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS markup
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS script
      RETURNING
        VALUE(rv_text) TYPE string.

ENDCLASS.

CLASS zcl_gg_shell IMPLEMENTATION.

  METHOD render.
    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8">' &&
      '<meta name="viewport" content="width=device-width, initial-scale=1">' &&
      '<title>open-abap-gui</title><style>' && styles( ) && '</style></head><body>' &&
      markup( ) && '<script>' && script( ) && '</script></body></html>'.
  ENDMETHOD.

  METHOD styles.
    rv_text = 'html, body { margin: 0; height: 100%; }' && ` ` &&
      'body { background: #fff; overflow: hidden; }' && ` ` &&
      '[hidden] { display: none !important; }' && ` ` &&
      '/* The rail of GUI sessions sits beside the session on screen. */' && ` ` &&
      '#gg-shell { display: grid; grid-template-columns: 196px minmax(0, 1fr); height: 100%; }' && ` ` &&
      '#gg-shell.gg-shell--collapsed { grid-template-columns: 50px minmax(0, 1fr); }' && ` ` &&
      '#gg-frames { position: relative; min-width: 0; min-height: 0; }' && ` ` &&
      '.gg-session-frame { display: block; width: 100%; height: 100%; border: 0; }' && ` ` &&
      '/* Midnight Glass: navy falling to near black with a cool glow at the top; the' && ` ` &&
      'active session is a frosted pane with a lit top edge and a gold marker. */' && ` ` &&
      '#gg-rail { position: relative; z-index: 1; display: flex; flex-direction: column; gap: 6px; min-width: 0; min-height: 0; padding: 8px;' && ` ` &&
      'box-sizing: border-box; color: #eef4fb; font: 13px/1.3 "Segoe UI", system-ui, sans-serif;' && ` ` &&
      'background: linear-gradient(180deg, #24406a 0%, #172c4a 48%, #0f1d33 100%);' && ` ` &&
      '/* The rail ends at its own edge; no shadow falls on the session beside it. */' && ` ` &&
      'box-shadow: inset -1px 0 0 rgba(255, 255, 255, .07); }' && ` ` &&
      '#gg-rail::before { content: ""; position: absolute; inset: 0 0 auto; height: 120px; pointer-events: none;' && ` ` &&
      'background: radial-gradient(120% 100% at 0% 0%, rgba(120, 170, 255, .22), transparent 70%); }' && ` ` &&
      '#gg-rail-list { position: relative; list-style: none; margin: 0; padding: 0 0 0 4px; display: flex; flex-direction: column; gap: 3px;' && ` ` &&
      'overflow-y: auto; min-height: 0; }' && ` ` &&
      '.gg-rail-item { position: relative; display: flex; align-items: center; border-radius: 9px; border: 1px solid transparent;' && ` ` &&
      'transition: background-color .15s, border-color .15s; }' && ` ` &&
      '.gg-rail-item:hover { background: rgba(255, 255, 255, .05); border-color: rgba(255, 255, 255, .06); }' && ` ` &&
      '.gg-rail-item--active { background: linear-gradient(180deg, rgba(255, 255, 255, .17), rgba(255, 255, 255, .06));' && ` ` &&
      'border-color: rgba(255, 255, 255, .16); box-shadow: inset 0 1px 0 rgba(255, 255, 255, .22), 0 6px 16px rgba(2, 8, 20, .35); }' && ` ` &&
      '.gg-rail-item--active::before { content: ""; position: absolute; left: -5px; top: 9px; bottom: 9px; width: 3px; border-radius: 3px;' && ` ` &&
      'background: linear-gradient(#ffd766, #f0a400); box-shadow: 0 0 8px rgba(255, 200, 60, .6); }' && ` ` &&
      '/* Every entry is as tall as one with a title line, the code centred in one without. */' && ` ` &&
      '.gg-rail-select { all: unset; box-sizing: border-box; cursor: pointer; flex: 1; min-width: 0; display: flex; flex-direction: column;' && ` ` &&
      'justify-content: center; min-height: calc(13px * 1.3 + 11px * 1.3 + 12px); padding: 6px 10px; border-radius: 9px; }' && ` ` &&
      '.gg-rail-code { font-weight: 600; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }' && ` ` &&
      '.gg-rail-title { font-size: 11px; color: #a3b9d3; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }' && ` ` &&
      '.gg-rail-title:empty { display: none; }' && ` ` &&
      '.gg-rail-end { all: unset; cursor: pointer; flex: none; width: 20px; height: 20px; margin-right: 6px; display: grid; place-items: center;' && ` ` &&
      'border-radius: 5px; font-size: 11px; color: #9db3cd; }' && ` ` &&
      '.gg-rail-end:hover, .gg-rail-end:focus-visible { background: rgba(255, 255, 255, .12); color: #fff; }' && ` ` &&
      '.gg-rail-foot { position: relative; margin-top: auto; display: flex; flex-direction: column; gap: 2px; padding-top: 6px;' && ` ` &&
      'border-top: 1px solid rgba(255, 255, 255, .08); }' && ` ` &&
      '.gg-rail-foot button { all: unset; box-sizing: border-box; cursor: pointer; display: flex; gap: 8px; align-items: center; padding: 6px 10px;' && ` ` &&
      'border-radius: 7px; white-space: nowrap; overflow: hidden; color: #b9cbe0; }' && ` ` &&
      '.gg-rail-foot button:hover, .gg-rail-foot button:focus-visible { background: rgba(255, 255, 255, .07); color: #fff; }' && ` ` &&
      '.gg-rail-select:focus-visible, .gg-rail-end:focus-visible, .gg-rail-foot button:focus-visible { outline: 2px solid #f0b400; outline-offset: -2px; }' && ` ` &&
      '/* The glyphs are SVG, centred by the grid: a text glyph sits on its font''s baseline, off the middle of a circle. */' && ` ` &&
      '.gg-rail-glyph { width: 20px; height: 20px; flex: none; display: grid; place-items: center; }' && ` ` &&
      '.gg-rail-glyph svg { width: 14px; height: 14px; fill: none; stroke: currentColor; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; }' && ` ` &&
      '#gg-rail-new .gg-rail-glyph { border-radius: 50%; color: #ffd766;' && ` ` &&
      'background: linear-gradient(180deg, rgba(255, 215, 102, .22), rgba(240, 164, 0, .1));' && ` ` &&
      'box-shadow: inset 0 0 0 1px rgba(255, 215, 102, .5), 0 0 10px rgba(255, 200, 60, .15);' && ` ` &&
      'transition: background .15s, color .15s, box-shadow .15s; }' && ` ` &&
      '#gg-rail-new .gg-rail-glyph svg { width: 12px; height: 12px; stroke-width: 2.4; }' && ` ` &&
      '#gg-rail-new:hover .gg-rail-glyph, #gg-rail-new:focus-visible .gg-rail-glyph { color: #172c4a;' && ` ` &&
      'background: linear-gradient(#ffd766, #f0a400); box-shadow: 0 0 12px rgba(255, 200, 60, .45); }' && ` ` &&
      '.gg-rail-collapse-glyph { transition: transform .2s; }' && ` ` &&
      '@media (prefers-reduced-motion: reduce) { .gg-rail-item, .gg-rail-glyph, .gg-rail-collapse-glyph { transition: none; } }' && ` ` &&
      '/* Collapsed, the rail shows the start of each transaction code. */' && ` ` &&
      '.gg-shell--collapsed #gg-rail { padding: 8px 4px; }' && ` ` &&
      '.gg-shell--collapsed .gg-rail-title, .gg-shell--collapsed .gg-rail-end, .gg-shell--collapsed .gg-rail-label { display: none; }' && ` ` &&
      '.gg-shell--collapsed .gg-rail-select { padding: 6px 2px; text-align: center; }' && ` ` &&
      '.gg-shell--collapsed .gg-rail-code { font-size: 10px; text-overflow: clip; }' && ` ` &&
      '.gg-shell--collapsed .gg-rail-foot button { justify-content: center; padding: 6px 0; }' && ` ` &&
      '.gg-shell--collapsed .gg-rail-collapse-glyph { transform: scaleX(-1); }'.
  ENDMETHOD.

  METHOD markup.
    rv_text = '<div id="gg-shell">' && ` ` &&
      '<nav id="gg-rail" aria-label="Sessions">' && ` ` &&
      '<ol id="gg-rail-list"></ol>' && ` ` &&
      '<div class="gg-rail-foot">' && ` ` &&
      '<button id="gg-rail-new" type="button" title="Create Session (/o)"><span class="gg-rail-glyph" aria-hidden="true">' &&
      '<svg viewBox="0 0 24 24"><path d="M12 5v14M5 12h14"/></svg></span><span class="gg-rail-label">New session</span></button>' && ` ` &&
      '<button id="gg-rail-collapse" type="button" title="Collapse the session list" aria-controls="gg-rail-list"><span class="gg-rail-glyph gg-rail-collapse-glyph" aria-hidden="true">' &&
      '<svg viewBox="0 0 24 24"><path d="M11 7l-5 5 5 5M18 7l-5 5 5 5"/></svg></span><span class="gg-rail-label">Collapse</span></button>' && ` ` &&
      '</div>' && ` ` &&
      '</nav>' && ` ` &&
      '<div id="gg-frames"></div>' && ` ` &&
      '</div>'.
  ENDMETHOD.

  METHOD script.
* The lines join with blanks, so every statement ends with a semicolon and
* comments are block comments.
    rv_text = '(function () {' && ` ` &&
      'var NEW_WINDOW = "new";' && ` ` &&
      'var COMMAND_FORM = "wb-command-transaction";' && ` ` &&
      'var COLLAPSED_KEY = "open-abap-gui.rail-collapsed";' && ` ` &&
      'var shell = document.getElementById("gg-shell");' && ` ` &&
      'var list = document.getElementById("gg-rail-list");' && ` ` &&
      'var frames = document.getElementById("gg-frames");' && ` ` &&
      'var sessions = [];' && ` ` &&
      'var active = null;' && ` ` &&
      'var lastKey = 0;' && ` ` &&
      'function isElement(value) {' && ` ` &&
      'return value !== null && typeof value === "object" && value.nodeType === 1;' && ` ` &&
      '}' && ` ` &&
      '/* A route of the host: the path without the drive letter Chromium keeps in' && ` ` &&
      'file URLs on Windows, and the query. */' && ` ` &&
      'function route(url) {' && ` ` &&
      'var path = url.pathname || "/";' && ` ` &&
      'if (url.protocol === "file:" && /^\/[A-Za-z]:(\/|$)/.test(path)) {' && ` ` &&
      'path = path.slice(3) || "/";' && ` ` &&
      '}' && ` ` &&
      '/* One leading slash: //other.example/ would be a URL of another host. */' && ` ` &&
      'return path.replace(/^\/+/, "/") + url.search;' && ` ` &&
      '}' && ` ` &&
      'function sameSite(url) {' && ` ` &&
      'return url.origin === location.origin || url.protocol === "file:";' && ` ` &&
      '}' && ` ` &&
      'function createSession(windowId) {' && ` ` &&
      'var frame = document.createElement("iframe");' && ` ` &&
      'frame.className = "gg-session-frame";' && ` ` &&
      'frame.title = "Session";' && ` ` &&
      'frame.hidden = true;' && ` ` &&
      'frames.appendChild(frame);' && ` ` &&
      'lastKey += 1;' && ` ` &&
      'var session = {window: windowId, key: String(lastKey), frame: frame, tcode: "", title: "", handlers: null, nativeSubmit: null, opening: null};' && ` ` &&
      'sessions.push(session);' && ` ` &&
      'return session;' && ` ` &&
      '}' && ` ` &&
      'function removeSession(session) {' && ` ` &&
      'var index = sessions.indexOf(session);' && ` ` &&
      'if (index < 0) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'sessions.splice(index, 1);' && ` ` &&
      'frames.removeChild(session.frame);' && ` ` &&
      'if (active !== session) {' && ` ` &&
      'renderRail();' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      '/* The one after the ended session takes its place, or else the one before. */' && ` ` &&
      'activate(sessions[index] || sessions[index - 1]);' && ` ` &&
      '}' && ` ` &&
      'function activate(session) {' && ` ` &&
      'if (!session) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'active = session;' && ` ` &&
      'sessions.forEach(function (other) {' && ` ` &&
      'other.frame.hidden = other !== session;' && ` ` &&
      '});' && ` ` &&
      'renderRail();' && ` ` &&
      'var win = session.frame.contentWindow;' && ` ` &&
      'var doc = session.frame.contentDocument;' && ` ` &&
      'if (win && doc) {' && ` ` &&
      'win.focus();' && ` ` &&
      'if (!doc.activeElement || doc.activeElement === doc.body) {' && ` ` &&
      'var field = doc.getElementById("ToolbarOkCode");' && ` ` &&
      'if (field) {' && ` ` &&
      'field.focus();' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      'function request(session, value, init) {' && ` ` &&
      '/* The first request of a session opens its window on the host; the ones sent' && ` ` &&
      'before the host named it wait, or each would open another. */' && ` ` &&
      'if (session.window === NEW_WINDOW && session.opening) {' && ` ` &&
      'return session.opening.then(function () {' && ` ` &&
      'return request(session, value, init);' && ` ` &&
      '});' && ` ` &&
      '}' && ` ` &&
      'init = init || {};' && ` ` &&
      'var method = String(init.method || "GET").toUpperCase();' && ` ` &&
      'var sent = fetch(value, {method: method, body: init.body, headers: {"x-gg-window": session.window}});' && ` ` &&
      'if (session.window === NEW_WINDOW) {' && ` ` &&
      'session.opening = sent.then(function (response) {' && ` ` &&
      'session.window = response.headers.get("x-gg-window") || NEW_WINDOW;' && ` ` &&
      '}, function () {' && ` ` &&
      'return undefined;' && ` ` &&
      '}).then(function () {' && ` ` &&
      'session.opening = null;' && ` ` &&
      '});' && ` ` &&
      '}' && ` ` &&
      'return sent.then(function (response) {' && ` ` &&
      'return handleResponse(session, response);' && ` ` &&
      '})' && ` ` &&
      '.catch(function (error) {' && ` ` &&
      'showError(session, error);' && ` ` &&
      '});' && ` ` &&
      '}' && ` ` &&
      'function handleResponse(session, response) {' && ` ` &&
      'var kind = response.headers.get("x-gg-session");' && ` ` &&
      'if (kind === "end") {' && ` ` &&
      'removeSession(session);' && ` ` &&
      'return undefined;' && ` ` &&
      '}' && ` ` &&
      'if (kind === "new") {' && ` ` &&
      'var created = createSession(response.headers.get("x-gg-window"));' && ` ` &&
      'return write(created, response).then(function () {' && ` ` &&
      '/* The command stays in the session it was typed in; clear it there. */' && ` ` &&
      'var form = session.frame.contentDocument && session.frame.contentDocument.getElementById(COMMAND_FORM);' && ` ` &&
      'if (form) {' && ` ` &&
      'form.reset();' && ` ` &&
      '}' && ` ` &&
      'activate(created);' && ` ` &&
      '}, function (error) {' && ` ` &&
      'removeSession(created);' && ` ` &&
      '/* The host opened the window already; end it there as well, or the host counts' && ` ` &&
      'a session the rail does not show, and lets the last one shown end. */' && ` ` &&
      'fetch("/transaction", {method: "POST", headers: {"x-gg-window": created.window},' && ` ` &&
      'body: new URLSearchParams({session: "end"})}).catch(function () {' && ` ` &&
      'return undefined;' && ` ` &&
      '});' && ` ` &&
      'throw error;' && ` ` &&
      '});' && ` ` &&
      '}' && ` ` &&
      'return write(session, response);' && ` ` &&
      '}' && ` ` &&
      'function write(session, response) {' && ` ` &&
      'return response.text().then(function (html) {' && ` ` &&
      '/* An error page of the host is a page of the session as well; anything else is no page. */' && ` ` &&
      'if (!response.ok && !/^text\/html/i.test(response.headers.get("content-type") || "")) {' && ` ` &&
      'throw new Error("The host answered " + response.status + ": " + html);' && ` ` &&
      '}' && ` ` &&
      'session.frame.setAttribute("data-gg-status", String(response.status));' && ` ` &&
      'var doc = session.frame.contentDocument;' && ` ` &&
      'doc.open();' && ` ` &&
      'doc.write(html);' && ` ` &&
      'doc.close();' && ` ` &&
      'install(session);' && ` ` &&
      'var title = doc.getElementById("wb-page-title");' && ` ` &&
      'session.title = (title && title.textContent.trim()) || doc.title || "";' && ` ` &&
      '/* The host names the program on screen, which CALL TRANSACTION and SUBMIT change;' && ` ` &&
      'the workbench with no program running has none. Any other page, such as an' && ` ` &&
      'error while a program runs, keeps the one before. */' && ` ` &&
      'var tcode = response.headers.get("x-gg-transaction");' && ` ` &&
      'if (tcode !== null) {' && ` ` &&
      'session.tcode = tcode;' && ` ` &&
      '} else if (doc.querySelector("[data-gg-menu]")) {' && ` ` &&
      'session.tcode = "";' && ` ` &&
      '}' && ` ` &&
      'session.frame.title = session.title || "Session";' && ` ` &&
      'renderRail();' && ` ` &&
      '});' && ` ` &&
      '}' && ` ` &&
      'function install(session) {' && ` ` &&
      'var win = session.frame.contentWindow;' && ` ` &&
      'if (!session.handlers) {' && ` ` &&
      'session.handlers = {' && ` ` &&
      'click: function (event) { handleClick(session, event); },' && ` ` &&
      'submit: function (event) { handleSubmit(session, event); },' && ` ` &&
      'load: function (event) { relay(session, event.target); }' && ` ` &&
      '};' && ` ` &&
      '}' && ` ` &&
      'var handlers = session.handlers;' && ` ` &&
      'win.removeEventListener("click", handlers.click, true);' && ` ` &&
      'win.removeEventListener("submit", handlers.submit, true);' && ` ` &&
      'win.addEventListener("click", handlers.click, true);' && ` ` &&
      'win.addEventListener("submit", handlers.submit, true);' && ` ` &&
      '/* The load event of an element stops at its document, so the frames of the' && ` ` &&
      'page are watched there, the ones loaded already included. */' && ` ` &&
      'win.document.removeEventListener("load", handlers.load, true);' && ` ` &&
      'win.document.addEventListener("load", handlers.load, true);' && ` ` &&
      'Array.prototype.forEach.call(win.document.querySelectorAll("iframe"), function (nested) {' && ` ` &&
      'relay(session, nested);' && ` ` &&
      '});' && ` ` &&
      '/* form.submit() skips the submit event, as in the F-key script; route it' && ` ` &&
      'through the shell as well, or it would navigate the frame away. */' && ` ` &&
      'var proto = win.HTMLFormElement.prototype;' && ` ` &&
      'if (!session.nativeSubmit) {' && ` ` &&
      'session.nativeSubmit = proto.submit;' && ` ` &&
      'proto.submit = function () {' && ` ` &&
      'if (!submitForm(session, this, null)) {' && ` ` &&
      'session.nativeSubmit.call(this);' && ` ` &&
      '}' && ` ` &&
      '};' && ` ` &&
      '/* The next page in the frame keeps this wrapper; the mark keeps its script from' && ` ` &&
      'wrapping it again, see zcl_gg_host_windows=>script. */' && ` ` &&
      'proto.submit.ggWindow = true;' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      '/* An HTML viewer shows its document in an iframe of the page, sandboxed without' && ` ` &&
      'scripts, whose sapevent forms post to the top window: the shell, which they' && ` ` &&
      'would replace, ending every session. Its submits go through the session like' && ` ` &&
      'those of the page; a frame of another site is left alone. */' && ` ` &&
      'function relay(session, nested) {' && ` ` &&
      'if (!isElement(nested) || nested.tagName !== "IFRAME") {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'try {' && ` ` &&
      'var nestedWin = nested.contentWindow;' && ` ` &&
      'if (!nestedWin || !nestedWin.document) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'nestedWin.removeEventListener("submit", session.handlers.submit, true);' && ` ` &&
      'nestedWin.addEventListener("submit", session.handlers.submit, true);' && ` ` &&
      '} catch (error) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      'function formBody(form, submitter) {' && ` ` &&
      'var values = new FormData(form);' && ` ` &&
      'if (submitter && submitter.name) {' && ` ` &&
      'values.set(submitter.name, submitter.value);' && ` ` &&
      '}' && ` ` &&
      'var encoded = new URLSearchParams();' && ` ` &&
      'values.forEach(function (value, name) {' && ` ` &&
      'encoded.append(name, typeof value === "string" ? value : value.name);' && ` ` &&
      '});' && ` ` &&
      'return encoded;' && ` ` &&
      '}' && ` ` &&
      'function handleClick(session, event) {' && ` ` &&
      'if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'var link = isElement(event.target) ? event.target.closest("a[href]") : null;' && ` ` &&
      'if (!link) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'var href = link.getAttribute("href");' && ` ` &&
      'if (!href || href.charAt(0) === "#" || /^(mailto|javascript):/i.test(href)) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'var url = new URL(href, location.href);' && ` ` &&
      '/* A download link, such as the blob: URL of GUI_DOWNLOAD, which shares the' && ` ` &&
      'page''s origin, is the browser''s to follow. */' && ` ` &&
      'if (link.hasAttribute("download") || !/^(https?|file):$/.test(url.protocol) || !sameSite(url)) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'event.preventDefault();' && ` ` &&
      'request(session, route(url));' && ` ` &&
      '}' && ` ` &&
      'function handleSubmit(session, event) {' && ` ` &&
      'var form = event.target;' && ` ` &&
      'if (!isElement(form) || form.tagName !== "FORM") {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'if (submitForm(session, form, event.submitter)) {' && ` ` &&
      'event.preventDefault();' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      '/* Sends a form of the session''s page to the host. False for a form that' && ` ` &&
      'posts to another site, which the browser then handles. */' && ` ` &&
      'function submitForm(session, form, submitter) {' && ` ` &&
      'var url = new URL(form.getAttribute("action") || "/", location.href);' && ` ` &&
      'if (!sameSite(url)) {' && ` ` &&
      'return false;' && ` ` &&
      '}' && ` ` &&
      'var method = String(form.getAttribute("method") || "GET").toUpperCase();' && ` ` &&
      'var body = formBody(form, submitter);' && ` ` &&
      'var target = route(url);' && ` ` &&
      'if (method === "GET") {' && ` ` &&
      'var query = body.toString();' && ` ` &&
      'request(session, target + (query ? (url.search ? "&" : "?") + query : ""));' && ` ` &&
      '} else {' && ` ` &&
      'request(session, target, {method: method, body: body});' && ` ` &&
      '}' && ` ` &&
      'return true;' && ` ` &&
      '}' && ` ` &&
      'function renderRail() {' && ` ` &&
      'var several = sessions.length > 1;' && ` ` &&
      'while (list.firstChild) {' && ` ` &&
      'list.removeChild(list.firstChild);' && ` ` &&
      '}' && ` ` &&
      '/* New sessions are appended, so the rail keeps the order they opened in. */' && ` ` &&
      'sessions.forEach(function (session) {' && ` ` &&
      'var label = session.tcode || session.title || "Session";' && ` ` &&
      'var item = document.createElement("li");' && ` ` &&
      'item.className = "gg-rail-item" + (session === active ? " gg-rail-item--active" : "");' && ` ` &&
      'var select = document.createElement("button");' && ` ` &&
      'select.type = "button";' && ` ` &&
      'select.className = "gg-rail-select";' && ` ` &&
      'select.setAttribute("data-session", session.key);' && ` ` &&
      'select.title = session.title || label;' && ` ` &&
      'if (session === active) {' && ` ` &&
      'select.setAttribute("aria-current", "true");' && ` ` &&
      '}' && ` ` &&
      'var code = document.createElement("span");' && ` ` &&
      'code.className = "gg-rail-code";' && ` ` &&
      'code.textContent = label;' && ` ` &&
      'var title = document.createElement("span");' && ` ` &&
      'title.className = "gg-rail-title";' && ` ` &&
      'title.textContent = session.tcode ? session.title : "";' && ` ` &&
      'select.appendChild(code);' && ` ` &&
      'select.appendChild(title);' && ` ` &&
      'item.appendChild(select);' && ` ` &&
      '/* The last session stays open, so it has no end button. */' && ` ` &&
      'if (several) {' && ` ` &&
      'var end = document.createElement("button");' && ` ` &&
      'end.type = "button";' && ` ` &&
      'end.className = "gg-rail-end";' && ` ` &&
      'end.setAttribute("data-end-session", session.key);' && ` ` &&
      'end.setAttribute("aria-label", "End session " + label);' && ` ` &&
      'end.title = "End session";' && ` ` &&
      'end.textContent = "\u2715";' && ` ` &&
      'item.appendChild(end);' && ` ` &&
      '}' && ` ` &&
      'list.appendChild(item);' && ` ` &&
      '});' && ` ` &&
      '}' && ` ` &&
      'function byKey(key) {' && ` ` &&
      'for (var i = 0; i < sessions.length; i += 1) {' && ` ` &&
      'if (sessions[i].key === key) {' && ` ` &&
      'return sessions[i];' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      'return null;' && ` ` &&
      '}' && ` ` &&
      'function collapsed() {' && ` ` &&
      'try {' && ` ` &&
      'return window.localStorage.getItem(COLLAPSED_KEY) === "1";' && ` ` &&
      '} catch (error) {' && ` ` &&
      'return false;' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      'function setCollapsed(value) {' && ` ` &&
      'shell.classList.toggle("gg-shell--collapsed", value);' && ` ` &&
      'document.getElementById("gg-rail-collapse").setAttribute("aria-expanded", String(!value));' && ` ` &&
      'try {' && ` ` &&
      'window.localStorage.setItem(COLLAPSED_KEY, value ? "1" : "0");' && ` ` &&
      '} catch (error) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      'function showError(session, error) {' && ` ` &&
      'var doc = session && session.frame.contentDocument;' && ` ` &&
      'if (!doc) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'doc.open();' && ` ` &&
      'doc.write("<!doctype html><main style=\"font:16px system-ui;padding:2rem\"><h1>Preview failed</h1><pre style=\"white-space:pre-wrap\"></pre></main>");' && ` ` &&
      'doc.close();' && ` ` &&
      'doc.querySelector("main pre").textContent = String(error && error.message || error);' && ` ` &&
      'session.frame.removeAttribute("data-gg-status");' && ` ` &&
      '}' && ` ` &&
      'document.getElementById("gg-rail").addEventListener("click", function (event) {' && ` ` &&
      'if (!isElement(event.target)) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'var end = event.target.closest("[data-end-session]");' && ` ` &&
      'if (end) {' && ` ` &&
      'var ending = byKey(end.getAttribute("data-end-session"));' && ` ` &&
      'if (ending) {' && ` ` &&
      'request(ending, "/transaction", {method: "POST", body: new URLSearchParams({session: "end"})});' && ` ` &&
      '}' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'var select = event.target.closest("[data-session]");' && ` ` &&
      'if (select) {' && ` ` &&
      'activate(byKey(select.getAttribute("data-session")));' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'if (event.target.closest("#gg-rail-new")) {' && ` ` &&
      'request(active, "/transaction", {method: "POST", body: new URLSearchParams({session: "open"})});' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'if (event.target.closest("#gg-rail-collapse")) {' && ` ` &&
      'setCollapsed(!shell.classList.contains("gg-shell--collapsed"));' && ` ` &&
      '}' && ` ` &&
      '});' && ` ` &&
      'setCollapsed(collapsed());' && ` ` &&
      '/* A route in the address bar''s hash, as #/transaction?tcode=SE16, opens in the' && ` ` &&
      'active session, at the start and whenever the hash changes; without one the' && ` ` &&
      'session shows the workbench. Only a path of this host is taken: a URL reads a' && ` ` &&
      'backslash as /, so /\other.example/ names another host. */' && ` ` &&
      'function hashRoute() {' && ` ` &&
      'var value = location.hash.slice(1);' && ` ` &&
      'if (value.charAt(0) !== "/") {' && ` ` &&
      'return "/";' && ` ` &&
      '}' && ` ` &&
      'try {' && ` ` &&
      'var url = new URL(value, location.href);' && ` ` &&
      'return sameSite(url) && url.host === location.host ? route(url) : "/";' && ` ` &&
      '} catch (error) {' && ` ` &&
      'return "/";' && ` ` &&
      '}' && ` ` &&
      '}' && ` ` &&
      'window.addEventListener("hashchange", function () {' && ` ` &&
      'request(active, hashRoute());' && ` ` &&
      '});' && ` ` &&
      '/* A reload or a closed tab ends the sessions of the page on the host; a page' && ` ` &&
      'the browser kept and shows again has none any more, so it starts afresh. */' && ` ` &&
      'window.addEventListener("pagehide", function () {' && ` ` &&
      'var named = sessions.filter(function (session) {' && ` ` &&
      'return session.window !== NEW_WINDOW;' && ` ` &&
      '})[0];' && ` ` &&
      'if (!named) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      'try {' && ` ` &&
      'fetch("/transaction", {method: "POST", keepalive: true, headers: {"x-gg-window": named.window},' && ` ` &&
      'body: new URLSearchParams({session: "close"})}).catch(function () {' && ` ` &&
      'return undefined;' && ` ` &&
      '});' && ` ` &&
      '} catch (error) {' && ` ` &&
      'return;' && ` ` &&
      '}' && ` ` &&
      '});' && ` ` &&
      'window.addEventListener("pageshow", function (event) {' && ` ` &&
      'if (event.persisted) {' && ` ` &&
      'location.reload();' && ` ` &&
      '}' && ` ` &&
      '});' && ` ` &&
      'var first = createSession(NEW_WINDOW);' && ` ` &&
      'activate(first);' && ` ` &&
      'request(first, hashRoute());' && ` ` &&
      '}());'.
  ENDMETHOD.

ENDCLASS.
