REPORT zgg_ex_178.

* The components of a header-line table are not screen fields of their own.

DATA: BEGIN OF gt_list OCCURS 0,
        matnr     TYPE matnr,
        text(100) TYPE c,
      END OF gt_list.
DATA ok_code LIKE sy-ucomm.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  gt_list-matnr = 'M-01'.
  gt_list-text = 'Material'.
  APPEND gt_list.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF ok_code = 'BACK'.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDMODULE.
