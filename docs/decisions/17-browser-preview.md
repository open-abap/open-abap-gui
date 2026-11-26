# Browser preview runs ABAP in the tab

The preview deployment is one self-contained HTML file. Webpack bundles the
transpiled ABAP, the runtime and an in-memory SQLite database (`sql-asm.js`, so
no `.wasm` is fetched). The shell's `fetch( )` goes to the ABAP runtime in the
tab instead of the network; the pages are the same as on the express server.

Each converted screen gets a screenshot, and pull requests show visual diffs
against `main`.

Code: [webpack.config.cjs](../../webpack.config.cjs),
[test/capture-web-screenshots.mjs](../../test/capture-web-screenshots.mjs)
