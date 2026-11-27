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
| `cl_gui_alv_grid`, `cx_salv_not_found`, `if_salv_c_bool_sap` | `zc_gui_alv_grid`, `zx_salv_not_found`, `zi_salv_c_bool_sap` |
| DDIC such as `lvc_s_fcat` | `zlvc_s_fcat` |

The type pools and the function group are left out; the copy uses SAP's own.
The build fails if the renamed copy does not compile, if a reference still
names an old object, or if a name is longer than 30 characters.

`sap-build/` is an abapGit repository with `PREFIX` folder logic: push it to a
branch, pull it into a local package such as `$GG_TEST`, and run ABAP Unit on
the package.

Code: [test/build-sap.mjs](../../test/build-sap.mjs)
