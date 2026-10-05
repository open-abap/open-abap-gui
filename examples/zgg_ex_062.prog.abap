REPORT zgg_ex_062.

* After Check the order gets another status: Check is gone, and Save is
* offered, in the application toolbar and on Ctrl+S.

START-OF-SELECTION.
  SET PF-STATUS 'EDIT'.
  WRITE / 'Order 4711, not checked'.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'CHECK'.
      SET PF-STATUS 'CHECKED'.
      WRITE / 'Order 4711, checked'.
    WHEN 'SAVE'.
      WRITE / 'Order 4711, saved'.
  ENDCASE.
