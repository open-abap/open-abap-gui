# open-abap-gui

wip

`npm test` transpiles without source maps. Use `npm run transpile` to generate
source maps for debugging, then `node --enable-source-maps output/index.mjs`
to run the ABAP unit tests with mapped stacks. `npm run test:html-e2e` also uses
the faster test transpilation configuration.
