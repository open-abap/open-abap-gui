INTERFACE zif_gg_program_v1 PUBLIC.

* Public metadata for an executable report that no transaction starts. The
* program is the classic program name the class implements, so the workbench
* can list the report and SUBMIT of that program finds the class. description
* is user-facing text. Implementations must return metadata without requiring
* a host session or changing application state.

  TYPES: BEGIN OF ty_program,
           program     TYPE zif_gg_session_types_v1=>ty_program,
           description TYPE string,
         END OF ty_program.

  METHODS get_program
    RETURNING
      VALUE(rs_program) TYPE ty_program.

ENDINTERFACE.
