REPORT zexample_unresolved.

DATA go_any TYPE REF TO object.
DATA go_missing TYPE REF TO zcl_not_in_input.
DATA gv_method TYPE string VALUE 'RUN'.

START-OF-SELECTION.
  go_missing->run( ).
  zcl_not_in_input=>run( ).
  CALL METHOD go_any->(gv_method).
  CALL METHOD zcl_not_in_input=>(gv_method).
  SET HANDLER go_missing->on_event FOR go_any.
  WRITE: / 'done'.
