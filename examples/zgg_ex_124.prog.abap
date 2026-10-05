REPORT zgg_ex_124.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_picture TYPE REF TO cl_gui_picture.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_url TYPE c LENGTH 255 VALUE '/assets/icons/refresh.svg'.
DATA gv_result TYPE i.
DATA gv_state TYPE c LENGTH 60.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_picture
      EXPORTING
        parent = go_container.
    go_picture->set_alt_text( 'Refresh icon' ).
    PERFORM load_picture.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'FIT'.
      go_picture->set_display_mode( cl_gui_picture=>display_mode_fit_center ).
      gv_state = 'Fit and centered'.
    WHEN 'NORMAL'.
      go_picture->set_display_mode( cl_gui_picture=>display_mode_normal ).
      gv_state = 'Normal size'.
    WHEN 'CLEAR'.
      go_picture->clear_picture( ).
      gv_state = 'Picture cleared'.
    WHEN 'LOAD'.
      PERFORM load_picture.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.

FORM load_picture.
  go_picture->load_picture_from_url( EXPORTING url    = gv_url
                                     IMPORTING result = gv_result ).
  gv_state = COND #( WHEN gv_result = 1 THEN 'Picture loaded' ELSE 'Picture could not be loaded' ).
ENDFORM.
