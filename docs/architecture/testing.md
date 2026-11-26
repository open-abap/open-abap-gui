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
