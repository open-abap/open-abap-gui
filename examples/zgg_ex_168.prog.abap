REPORT zgg_ex_168.

SELECT-OPTIONS s_data FOR sy-datum DEFAULT sy-datum.

START-OF-SELECTION.
  LOOP AT s_data INTO DATA(ls_data).
    WRITE: / ls_data-sign, ls_data-option, ls_data-low, ls_data-high.
  ENDLOOP.
