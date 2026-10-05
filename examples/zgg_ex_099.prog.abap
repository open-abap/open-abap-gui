REPORT zgg_ex_099.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_input TYPE c LENGTH 30 VALUE 'input'.
DATA gv_output TYPE c LENGTH 40 VALUE 'output'.
DATA gv_check TYPE c LENGTH 1 VALUE 'X'.
DATA gv_alpha TYPE c LENGTH 1 VALUE 'X'.
DATA gv_beta TYPE c LENGTH 1.
DATA gv_list TYPE c LENGTH 10 VALUE 'A'.
DATA gt_values TYPE vrm_values.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  gt_values = VALUE #( ( key = 'A' text = 'Alpha' ) ( key = 'B' text = 'Beta' ) ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GV_LIST'
      values = gt_values.
ENDMODULE.

MODULE exit_0100 INPUT.
  CLEAR gv_ok_code.
  LEAVE TO SCREEN 0.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'APPLY'.
    gv_output = |{ gv_input }, { COND string( WHEN gv_check = 'X' THEN 'checked' ELSE 'unchecked' ) }, | &&
                |{ COND string( WHEN gv_alpha = 'X' THEN 'Alpha' ELSE 'Beta' ) }, { gv_list }|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
