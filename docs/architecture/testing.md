# Testing

`npm test` runs every layer:

| layer | command | checks |
| --- | --- | --- |
| lint | `npm run lint`, `npm run lint:framework` | abaplint; the framework without the examples |
| ABAP Unit | `npm run unit` | transpiled `*.testclasses.abap` |
| browser | `npm run test:html-browser` | Playwright specs in `test/specs/` against the express server |
| examples | `npm run test:examples` | committed example classes equal the converter's output |
| converter | `npm run test:converter` | the converter's own suites, see [converter/README.md](../../converter/README.md) |

The preview build (`npm run web:build`) also takes a screenshot of every screen
and diffs it against `main`.

## On a real SAP system

`npm run build:sap` writes `sap-build/`, a copy of `src/` and `framework/` that
installs next to SAP's own controls. The `rename` patterns in `abaplint.jsonc`
give the SAP-named objects customer names, together with every reference:

| in the repository | in the copy |
| --- | --- |
| `cl_gui_alv_grid`, `cx_salv_not_found`, `if_salv_c_bool_sap` | `zcl_gg_gui_alv_grid`, `zcx_gg_salv_not_found`, `zif_gg_salv_c_bool_sap` |
| DDIC such as `lvc_s_fcat` | `zgg_lvc_s_fcat` |

DDIC gets `zgg_` rather than `z_gg_`: SAP allows no underscore in the second or
third character of a table or structure name. Nine class and interface names
would pass SAP's 30 characters with the `_gg_` prefix; the patterns give them
shortened names of their own, such as `zcl_gg_gui_easy_splitter_cont`.
The type pools and the function group are left out; the copy uses SAP's own.
The build fails if the renamed copy does not compile, if a reference still
names an old object, or if a name is longer than 30 characters.

`sap-build/` is an abapGit repository with everything under `src/`: `framework/`
becomes `src/framework/`, and every folder has a `package.devc.xml`. Folder
logic is `PREFIX`, so the subpackages are named after the root package and
never collide with SAP's own. Push it to a branch, pull it into a local package
such as `$GG_TEST`, and run ABAP Unit on the package. The icon notices sit in
`assets/`, outside abapGit's starting folder.

`sap-build/abaplint.jsonc` holds the syntax checks from abaplint's on-premise
getting started configuration, against open-abap-core and with only the
customer namespace as errors: run `npx abaplint` in `sap-build/` to check the
copy before installing it. open-abap-core has no `CNTB` or `CNCA` type pool,
which the copy takes from SAP, so expect four `check_syntax` findings for
their constants.

Code: [test/build-sap.mjs](../../test/build-sap.mjs)
