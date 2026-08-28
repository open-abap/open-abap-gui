import {pathToFileURL} from "node:url";
import {createHtmlHostServer} from "./html-http.mjs";
import {createAbapHtmlRuntime} from "./abap-html-runtime.mjs";

const integrationEntries = [
  {className: "ZCL_GG_DB_HELPER", path: "/ZCL_GG_DB_HELPER"},
  {
    className: "ZCL_GG_INTEGRATION_DYNPRO",
    path: "/ZCL_GG_INTEGRATION_DYNPRO",
    entryPoint: "ZCL_GG_INTEGRATION_DYNPRO",
  },
  {
    className: "ZCL_GG_INTEGRATION_FAILURE",
    path: "/ZCL_GG_INTEGRATION_FAILURE",
    entryPoint: "ZCL_GG_INTEGRATION_FAILURE",
  },
  {
    className: "ZCL_GG_INTEGRATION_FLIGHTS",
    path: "/ZCL_GG_INTEGRATION_FLIGHTS",
    entryPoint: "ZCL_GG_INTEGRATION_FLIGHTS",
  },
  {
    className: "ZCL_GG_INTEGRATION_HTML_REPORT",
    path: "/ZCL_GG_INTEGRATION_HTML_REPORT",
    entryPoint: "ZCL_GG_INTEGRATION_HTML_REPORT",
  },
  {
    className: "ZCL_GG_INTEGRATION_INTERACTIVE",
    path: "/ZCL_GG_INTEGRATION_INTERACTIVE",
    entryPoint: "ZCL_GG_INTEGRATION_INTERACTIVE",
  },
  {
    className: "ZCL_GG_INTEGRATION_NAVIGATION",
    path: "/ZCL_GG_INTEGRATION_NAVIGATION",
    entryPoint: "ZCL_GG_INTEGRATION_NAVIGATION",
  },
  {
    className: "ZCL_GG_INTEGRATION_SELECTION",
    path: "/ZCL_GG_INTEGRATION_SELECTION",
    entryPoint: "ZCL_GG_INTEGRATION_SELECTION",
  },
  {
    className: "ZCL_GG_INTEGRATION_VARIANTS",
    path: "/ZCL_GG_INTEGRATION_VARIANTS",
    entryPoint: "ZCL_GG_INTEGRATION_VARIANTS",
  },
];
const integrationRuntimes = new Map(
  integrationEntries
    .filter(({entryPoint}) => entryPoint)
    .map(({path, entryPoint}) => [path, createAbapHtmlRuntime({entryPoint})]),
);
const integrationReportRuntime = integrationRuntimes.get("/ZCL_GG_INTEGRATION_HTML_REPORT");
const exampleNames = Array.from({length: 58}, (_, index) =>
  `zgg_ex_${String(index + 1).padStart(2, "0")}`);
const exampleEntries = exampleNames.map((name) => ({
  className: `ZCL_GG_EX_${name.slice(-2)}`,
  path: `/ZCL_GG_EX_${name.slice(-2)}`,
}));
const exampleRuntimes = new Map(
  exampleEntries.map(({className, path}) =>
    [path, createAbapHtmlRuntime({entryPoint: `zgg_ex_${className.slice(-2)}`})]),
);
const startRuntimes = new Map([
  ...integrationRuntimes,
  ...exampleRuntimes,
]);
const utilityPages = new Map([
  ["/ZCL_GG_DB_HELPER", `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ZCL_GG_DB_HELPER</title>
  </head>
  <body>
    <main>
      <h1>ZCL_GG_DB_HELPER</h1>
      <p>This is the database fixture support class used by the integration examples.</p>
      <p>It is not an executable report or dynpro program.</p>
    </main>
  </body>
</html>`],
]);

function runtimeFor(url) {
  const runtime = startRuntimes.get(url.pathname);
  if (!runtime) throw new RangeError(`Unknown ABAP HTML route: ${url.pathname}`);
  return runtime;
}

function linksFor(entries) {
  return entries
    .map(({className, path}) => `      <li><a href="${path}">${className}</a></li>`)
    .join("\n");
}

function exampleIndex() {
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ABAP examples and integration classes</title>
  </head>
  <body>
    <main>
      <h1>ABAP examples</h1>
      <ul>
${linksFor(exampleEntries)}
      </ul>
      <h2>Integration classes</h2>
      <ul>
${linksFor(integrationEntries)}
      </ul>
    </main>
  </body>
</html>`;
}

export function createAbapHtmlHostServer() {
  const server = createHtmlHostServer({
    start: ({url}) => {
      if (url.pathname === "/") return {valid: true, html: exampleIndex()};
      if (utilityPages.has(url.pathname)) return {valid: true, html: utilityPages.get(url.pathname)};
      return runtimeFor(url).start({url});
    },
    dispatch: (request) => integrationReportRuntime.dispatch(request),
    close: (sessionId) => integrationReportRuntime.close(sessionId),
    startPaths: ["/", ...utilityPages.keys(), ...startRuntimes.keys()],
  });
  server.shutdown = async () => integrationReportRuntime.destroy();
  return server;
}

export function launchAbapHtmlHost({host = "127.0.0.1", port = 8080} = {}) {
  const server = createAbapHtmlHostServer();
  server.listen(port, host, () => {
    const address = server.address();
    const actualPort = typeof address === "object" && address !== null ? address.port : port;
    const base = `http://${host}:${actualPort}`;
    console.log(`ABAP HTML server started at ${base}`);
    console.log(`  Index: ${base}/`);
    for (const {className, path} of integrationEntries) {
      console.log(`  ${className}: ${base}${path}`);
    }
    console.log(`  Examples: ${base}/ZCL_GG_EX_01 through ${base}/ZCL_GG_EX_58`);
  });
  return server;
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  launchAbapHtmlHost();
}
