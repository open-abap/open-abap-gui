REPORT zexample_main.

INCLUDE zexample_main_top.
INCLUDE zexample_main_f01.

START-OF-SELECTION.
  PERFORM build_message.
  WRITE: / gv_message.
