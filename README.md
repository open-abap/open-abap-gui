# open-abap-gui

GUI Dynpro controls and classic report/dynpro processing for [open-abap](https://github.com/open-abap), rendered as HTML in the browser.

Work in progress.

Preview of `main`: https://open-abap.github.io/open-abap-gui-preview-deployments/main/

## Usage

Classic reports (`*.prog.abap`) are converted to classes, transpiled, and served in the browser through [express-icf-shim](https://github.com/open-abap/express-icf-shim).

```sh
npm install --save-dev @abaplint/open-abap-gui-converter @abaplint/transpiler-cli @abaplint/runtime @abaplint/database-sqlite express@4
```

`abap_transpile.json`, with the reports in `reports/`:

```json
{
  "input_folder": ["src", "generated"],
  "output_folder": "output",
  "converter": {
    "input_folder": ["reports"],
    "output_folder": "generated"
  },
  "libs": [
    { "url": "https://github.com/open-abap/open-abap-core" },
    { "url": "https://github.com/open-abap/express-icf-shim" },
    { "url": "https://github.com/open-abap/open-abap-gui", "files": ["/src/**", "/framework/**"] }
  ],
  "options": {
    "addCommonJS": true,
    "setup": { "filename": "../setup.mjs", "preFunction": "setupDatabase" }
  }
}
```

The converter writes one class per report to `generated/`; see [converter/README.md](converter/README.md). `framework/` holds the host and workbench the generated classes run in.

`setup.mjs`, a database for the transpiled code:

```js
import {SQLiteDatabaseClient} from "@abaplint/database-sqlite";

export async function setupDatabase(abap, schemas, insert) {
  const database = new SQLiteDatabaseClient();
  abap.context.databaseConnections.DEFAULT = database;
  await database.connect();
  await database.execute(schemas.sqlite);
  await database.execute(insert);
}
```

`package.json`:

```json
"scripts": {
  "convert": "open-abap-gui-convert",
  "build": "npm run convert && abap_transpile abap_transpile.json",
  "express": "npm run build && node express.mjs"
}
```

`express.mjs`:

```js
import express from "express";
import {initializeABAP} from "./output/init.mjs";
import {cl_express_icf_shim} from "./output/express-icf-shim/cl_express_icf_shim.clas.mjs";
await initializeABAP();

const app = express();
app.use(express.raw({type: "*/*"}));
app.all("*", async function (req, res) {
  await cl_express_icf_shim.run({req, res, class: "ZCL_GG_HTTP_HANDLER"});
});
app.listen(3000);
```

Then `npm run express` and open http://localhost:3000 for the workbench.

## abaplint.app

Looking for a hosted setup? [abaplint.app](https://abaplint.app) runs abaplint automatically on your GitHub pull requests: no system installation, custom configurations supported, and findings reported right where you review code.