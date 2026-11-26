# Folders

| folder | contents |
| --- | --- |
| [src/](../../src/) | SAP-named GUI classes: `cl_gui_*` controls, ALV, SALV, trees, `cl_ctmenu`, type pools, a function group |
| [framework/](../../framework/) | the host: interfaces, runtime, renderer, workbench, shell, registries |
| [framework/host/](../../framework/host/) | the processors: report run, session, selection screen, list, dynpro |
| [framework/http/](../../framework/http/) | the HTTP handler, the only HTTP-aware part |
| [converter/](../../converter/) | TypeScript PROG-to-CLAS converter, published as its own npm package |
| [examples/](../../examples/) | example programs and the classes generated from them, plus integration classes and DDIC objects |
| [test/](../../test/) | test scripts and Playwright specs |
| [web/](../../web/) | the page the browser preview bundle is built into |

Consumers take `src/` and `framework/` as an abap_transpile lib; see the
[README](../../README.md).
