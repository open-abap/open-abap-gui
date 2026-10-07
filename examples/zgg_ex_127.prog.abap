REPORT zgg_ex_127.

* The selector is the dropdown listbox of a dynpro field with values from
* VRM_SET_VALUES; there is no stand-alone selector control.

DATA gv_carrier TYPE c LENGTH 2.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.
DATA gt_values TYPE vrm_values.

START-OF-SELECTION.
  gv_carrier = 'LH'.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  gt_values = VALUE #( ( key = 'AA' text = 'Alpha Airlines' )
                       ( key = 'LH' text = 'Lufthansa' )
                       ( key = 'UA' text = 'United' ) ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GV_CARRIER'
      values = gt_values.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'CARRIER'.
    gv_state = |Selected carrier { gv_carrier }|.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.
