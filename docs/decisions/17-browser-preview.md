# Browser preview runs ABAP in the tab

The preview deployment is one self-contained HTML file. Webpack bundles the
transpiled ABAP, the runtime and an in-memory SQLite database (`sql-asm.js`, so
no `.wasm` is fetched). The shell's `fetch( )` goes to the ABAP runtime in the
tab instead of the network; the pages are the same as on the express server.

`web.mjs` is a transport only, like express for the server: it answers
`fetch( )` with the HTTP handler and writes the shell into the page. Navigation,
the rail, value help and every other page behaviour live in the ABAP host, so
the two hosts cannot drift apart.

Each converted screen gets a screenshot of its session frame, opened through
the shell with a hash route, and pull requests show visual diffs against
`main`.

Code: [web/web.mjs](../../web/web.mjs),
[webpack.config.cjs](../../webpack.config.cjs),
[test/capture-web-screenshots.mjs](../../test/capture-web-screenshots.mjs)
