REPORT zgg_ex_185.

* A function module call whose period stands on a line of its own, after
* commented-out parameters.

DATA: gs_variant TYPE disvariant,
      gv_exit(1) TYPE c.

START-OF-SELECTION.
  gs_variant-report = sy-repid.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant = gs_variant
      i_save     = 'A'
    IMPORTING
      e_exit     = gv_exit
      es_variant = gs_variant  " the chosen variant
*    EXCEPTIONS
*     NOT_FOUND = 1
    .
  WRITE: / gs_variant-variant, gv_exit.
