# No invented controls

Every field, button and screen element on a program's page comes from data the
program or a control declared, or from a standard SAP status (such as the list
functions for paging and Find). Dynpro screens, flow logic, GUI statuses and titlebars are
read from the abapGit metadata (`.prog.xml`, `.prog.screen_NNNN.abap`). Source
code is never used to guess at controls, and the renderer adds no buttons of
its own.

Why: the browser should show what SAP would show, and a gap in the metadata
should be visible, not papered over.

Code: [converter/src/dynpro-metadata.ts](../../converter/src/dynpro-metadata.ts)
